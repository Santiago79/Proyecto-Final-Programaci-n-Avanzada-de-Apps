import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/camera_provider.dart';
import '../providers/tflite_provider.dart';

class ScannerScreen extends ConsumerWidget {
  const ScannerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Escuchamos la cámara y arrancamos la IA en el fondo
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
              SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: CameraPreview(controller),
              ),
              
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 50.0),
                  child: FloatingActionButton.large(
                    backgroundColor: Colors.white,
                    child: const Icon(Icons.camera_alt, color: Colors.black, size: 40),
                    onPressed: () async {
                      if (tfliteAsync.isLoading || tfliteAsync.hasError) return;

                      final cameraSource = ref.read(cameraDataSourceProvider);
                      final imagePath = await cameraSource.takePicture();
                      
                      if (imagePath != null && context.mounted) {
                        try {
                          final tfliteSource = ref.read(tfliteDataSourceProvider);
                          final result = await tfliteSource.analyzeDogImage(imagePath);

                          if (context.mounted && result != null) {
                            final breed = result['breed'];
                            final confidence = result['confidence'] as double;
                            
                            // Navegamos directo sin mostrar mensajitos abajo
                            context.push('/results', extra: {
                              'breed': breed,
                              'confidence': confidence,
                              'imagePath': imagePath,
                            }); 
                          }
                        } catch (e) {
                          print("Error: $e");
                        }
                      }
                    },
                  ),
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