import '../entities/scan_result.dart';

abstract class TFLiteRepository {
  Future<void> initializeModel();
  Future<ScanResult?> analyzeDogImage(String imagePath);
  void dispose();
}