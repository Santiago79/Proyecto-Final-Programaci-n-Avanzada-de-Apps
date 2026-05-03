import '../entities/scan_result.dart';
import '../repositories/tflite_repository.dart';

class AnalyzeDogImageUseCase {
  final TFLiteRepository repository;

  AnalyzeDogImageUseCase(this.repository);

  Future<ScanResult?> call(String imagePath) {
    return repository.analyzeDogImage(imagePath);
  }
}