import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/data_sources/tflite_datasource.dart';

// Instancia global de tu DataSource
final tfliteDataSourceProvider = Provider((ref) => TFLiteDataSource());

// Provider que inicializa la IA y la limpia cuando se cierra la app
final tfliteInitProvider = FutureProvider.autoDispose<void>((ref) async {
  final dataSource = ref.watch(tfliteDataSourceProvider);
  
  ref.onDispose(() {
    dataSource.dispose();
  });

  await dataSource.initializeModel();
});