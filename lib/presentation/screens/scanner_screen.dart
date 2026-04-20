import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/camera_provider.dart';

class ScannerScreen extends ConsumerWidget {
  const ScannerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Escuchamos el estado de inicialización de la cámara
    final cameraAsync = ref.watch(cameraControllerProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Dog Scanner'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
      ),
      extendBodyBehindAppBar: true, // Para que la cámara ocupe toda la pantalla
      body: cameraAsync.when(
        data: (controller) {
          return Stack(
            children: [
              // Vista previa de la cámara a pantalla completa
              SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: CameraPreview(controller),
              ),
              
              // Botón para tomar la foto
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 40.0),
                  child: FloatingActionButton.large(
                    backgroundColor: Colors.white,
                    child: const Icon(Icons.camera_alt, color: Colors.black, size: 40),
                    onPressed: () async {
                      // 1. Tomamos la foto
                      final dataSource = ref.read(cameraDataSourceProvider);
                      final imagePath = await dataSource.takePicture();
                      
                      if (imagePath != null && context.mounted) {
                        // Aquí, temporalmente mostraremos un mensaje. 
                        // En el siguiente issue, pasaremos esta foto al modelo de IA.
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Foto tomada con éxito 📸')),
                        );
                        
                        // Para cuando el modelo de IA esté listo, navegaremos así:
                        // context.push('/results', extra: imagePath);
                      }
                    },
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 20),
              Text('Iniciando cámara...', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
        error: (error, stack) => Center(
          child: Text(
            'Error al abrir la cámara:\n$error',
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}