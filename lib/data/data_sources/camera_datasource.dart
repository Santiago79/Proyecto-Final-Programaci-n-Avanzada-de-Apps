import 'package:camera/camera.dart';

class CameraDataSource {
  CameraController? _controller;

  // Ahora recibe la cámara exacta que queremos inicializar
  Future<CameraController> initializeCamera(CameraDescription camera) async {
    _controller?.dispose(); // Limpiamos la anterior si existía
    
    _controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false, 
    );

    await _controller!.initialize();
    return _controller!;
  }

  Future<String?> takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) return null;
    final file = await _controller!.takePicture();
    return file.path;
  }

  void dispose() {
    _controller?.dispose();
  }
}