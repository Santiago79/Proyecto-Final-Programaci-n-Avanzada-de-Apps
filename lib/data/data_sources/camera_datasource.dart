import 'package:camera/camera.dart';

class CameraDataSource {
  CameraController? _controller;

  Future<CameraController> initializeCamera() async {
    final cameras = await availableCameras();
    // Forzamos el uso de la cámara trasera
    final backCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    _controller = CameraController(
      backCamera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    await _controller!.initialize();
    return _controller!;
  }

  Future<String?> takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) return null;
    if (_controller!.value.isTakingPicture) return null;

    try {
      final XFile picture = await _controller!.takePicture();
      return picture.path; // Retorna la ruta de la foto temporal
    } catch (e) {
      return null;
    }
  }

  void dispose() {
    _controller?.dispose();
  }
}