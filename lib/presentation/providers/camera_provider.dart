import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/data_sources/camera_datasource.dart';

final cameraDataSourceProvider = Provider((ref) => CameraDataSource());

final cameraControllerProvider = FutureProvider.autoDispose<CameraController>((ref) async {
  final dataSource = ref.watch(cameraDataSourceProvider);
  
  ref.onDispose(() {
    dataSource.dispose();
  });

  return await dataSource.initializeCamera();
});