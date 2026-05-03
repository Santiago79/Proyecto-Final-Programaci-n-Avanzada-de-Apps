class ScanHistory {
  final String? id;
  final String breed;
  final double confidence;
  final String imagePath;
  final DateTime timestamp;
  final Map<String, dynamic>? breedInfo;
  final String? imageUrl;

  ScanHistory({
    this.id,
    required this.breed,
    required this.confidence,
    required this.imagePath,
    required this.timestamp,
    this.breedInfo,
    this.imageUrl,
  });
}