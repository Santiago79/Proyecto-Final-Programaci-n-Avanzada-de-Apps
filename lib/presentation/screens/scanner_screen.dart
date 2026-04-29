import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:proyecto_final/presentation/providers/camera_provider.dart';
import '../providers/camera_provider.dart';
import '../providers/tflite_provider.dart';


// CAMBIO 1: Cambiamos a ConsumerStatefulWidget para manejar el estado visual del Zoom
class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  // Guardamos el zoom actual para la UI (Empezamos en 1x)
  double _currentZoom = 1.0;

  // Lógica de seguridad para el zoom
  Future<void> _setZoom(CameraController controller, double targetZoom) async {
    try {
      // Leemos los límites del hardware de tu iPhone
      final minZoom = await controller.getMinZoomLevel();
      final maxZoom = await controller.getMaxZoomLevel();
      
      // Nos aseguramos de no pedir un zoom que rompa la cámara
      final safeZoom = targetZoom.clamp(minZoom, maxZoom);
      
      await controller.setZoomLevel(safeZoom);
      
      setState(() {
        _currentZoom = safeZoom;
      });

      // Si pediste 0.5x pero el teléfono solo baja a 1.0x, avisamos
      if (safeZoom != targetZoom && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lente de ${targetZoom}x no disponible en este dispositivo.'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print("Error ajustando zoom: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final cameraAsync = ref.watch(cameraControllerProvider);
    final tfliteAsync = ref.watch(tfliteInitProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Dog Scanner', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true, 
      body: cameraAsync.when(
        data: (controller) {
          return Stack(
            children: [
              // 1. La cámara de fondo
              SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: CameraPreview(controller),
              ),
              
              // 2. La máscara de recorte (Viewport)
              Positioned.fill(
                child: CustomPaint(
                  painter: ScannerOverlayPainter(),
                ),
              ),

              // 3. NUEVO: Controles de Zoom estilo iOS
              // ... (código anterior) ...
              Positioned(
                bottom: 130, 
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ZoomButton(
                      label: '0.5x',
                      // Está activo si el provider dice que estamos usando UltraWide
                      isActive: ref.watch(useUltraWideProvider), 
                      onTap: () {
                        // 1. Apagamos el zoom digital
                        setState(() => _currentZoom = 1.0);
                        // 2. Le decimos a Riverpod que cambie físicamente de lente
                        ref.read(useUltraWideProvider.notifier).state = true;
                      },
                    ),
                    const SizedBox(width: 15),
                    _ZoomButton(
                      label: '1x',
                      isActive: !ref.watch(useUltraWideProvider) && _currentZoom == 1.0,
                      onTap: () async {
                        // 1. Volvemos al lente físico principal
                        ref.read(useUltraWideProvider.notifier).state = false;
                        // 2. Quitamos el zoom digital
                        await controller.setZoomLevel(1.0);
                        setState(() => _currentZoom = 1.0);
                      },
                    ),
                    const SizedBox(width: 15),
                    _ZoomButton(
                      label: '2x',
                      isActive: !ref.watch(useUltraWideProvider) && _currentZoom == 2.0,
                      onTap: () async {
                        // 1. Aseguramos estar en el lente principal
                        ref.read(useUltraWideProvider.notifier).state = false;
                        // 2. Aplicamos zoom digital de 2.0x
                        await controller.setZoomLevel(2.0);
                        setState(() => _currentZoom = 2.0);
                      },
                    ),
                  ],
                ),
              ),
              // ... (botón de captura) ...
              
              // 4. Botón de captura
              // 4. Controles de captura y galería
              Positioned(
                bottom: 30,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // --- BOTÓN DE GALERÍA ---
                    FloatingActionButton(
                      heroTag: 'gallery_btn', // ⚠️ Obligatorio si usas más de un FAB
                      backgroundColor: Colors.white24, // Semi-transparente
                      elevation: 0,
                      onPressed: () async {
                        if (tfliteAsync.isLoading || tfliteAsync.hasError) return;

                        try {
                          final picker = ImagePicker();
                          // Abrimos la galería de iOS/Android
                          final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                          
                          if (image != null && context.mounted) {
                            final tfliteSource = ref.read(tfliteDataSourceProvider);
                            final result = await tfliteSource.analyzeDogImage(image.path);

                            if (context.mounted && result != null) {
                              context.push('/results', extra: {
                                'breed': result['breed'],
                                'confidence': result['confidence'] as double,
                                'imagePath': image.path,
                              }); 
                            }
                          }
                        } catch (e) {
                          print("Error seleccionando de galería: $e");
                        }
                      },
                      child: const Icon(Icons.photo_library, color: Colors.white, size: 28),
                    ),

                    // --- BOTÓN DE CÁMARA PRINCIPAL ---
                    FloatingActionButton.large(
                      heroTag: 'camera_btn',
                      backgroundColor: Colors.white,
                      onPressed: () async {
                        if (tfliteAsync.isLoading || tfliteAsync.hasError) return;

                        final cameraSource = ref.read(cameraDataSourceProvider);
                        final imagePath = await cameraSource.takePicture();
                        
                        if (imagePath != null && context.mounted) {
                          try {
                            final tfliteSource = ref.read(tfliteDataSourceProvider);
                            final result = await tfliteSource.analyzeDogImage(imagePath);

                            if (context.mounted && result != null) {
                              context.push('/results', extra: {
                                'breed': result['breed'],
                                'confidence': result['confidence'] as double,
                                'imagePath': imagePath,
                              }); 
                            }
                          } catch (e) {
                            print("Error: $e");
                          }
                        }
                      },
                      child: const Icon(Icons.camera_alt, color: Colors.black, size: 40),
                    ),

                    // --- ESPACIO INVISIBLE ---
                    // Sirve para balancear la fila y que el botón de cámara quede perfectamente en el centro
                    const SizedBox(width: 56), 
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
        error: (error, stack) => Center(
          child: Text('Error en la cámara: $error', style: const TextStyle(color: Colors.red)),
        ),
      ),
    );
  }
}

// --- WIDGET PARA EL BOTÓN DE ZOOM ---
class _ZoomButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _ZoomButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 45,
        height: 45,
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFE85D04) : Colors.black.withOpacity(0.5),
          shape: BoxShape.circle,
          border: Border.all(
            color: isActive ? const Color(0xFFE85D04) : Colors.white,
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

// --- PINTOR DE LA MÁSCARA (El mismo de antes) ---
class ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = Colors.black.withOpacity(0.6);
    final shortestSide = size.width < size.height ? size.width : size.height;
    
    final cropRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: shortestSide,
      height: shortestSide,
    );

    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        Path()..addRect(cropRect),
      ),
      bgPaint,
    );
    
    final borderPaint = Paint()
      ..color = const Color(0xFFE85D04) 
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawRect(cropRect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}