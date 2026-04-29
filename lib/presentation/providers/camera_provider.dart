import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../data/data_sources/camera_datasource.dart';

final cameraDataSourceProvider = Provider((ref) => CameraDataSource());

// 🆕 ESTADO: ¿El usuario quiere el lente 0.5x? (true/false)
final useUltraWideProvider = StateProvider<bool>((ref) => false);

final cameraControllerProvider = FutureProvider.autoDispose<CameraController>((ref) async {
  final dataSource = ref.watch(cameraDataSourceProvider);
  
  // Riverpod reiniciará la cámara automáticamente si este valor cambia
  final wantsUltraWide = ref.watch(useUltraWideProvider); 

  final cameras = await availableCameras();
  final backCameras = cameras.where((c) => c.lensDirection == CameraLensDirection.back).toList();

  CameraDescription cameraToUse = backCameras.first; // Por defecto, el 1x normal

  if (wantsUltraWide && backCameras.length > 1) {
    // Truco iOS: El último lente de la lista suele ser el Ultra Gran Angular físico
    cameraToUse = backCameras.last; 
  }

  ref.onDispose(() {
    dataSource.dispose();
  });

  return await dataSource.initializeCamera(cameraToUse);
});