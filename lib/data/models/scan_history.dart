import 'package:cloud_firestore/cloud_firestore.dart';

class ScanHistory {
  final String? id;  // Opcional, Firestore lo asigna
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

  // Convertir a Map para guardar en Firestore
  Map<String, dynamic> toMap() {
    return {
      'breed': breed,
      'confidence': confidence,
      'imagePath': imagePath,
      'timestamp': Timestamp.fromDate(timestamp),
      'breedInfo': breedInfo ?? {},
      'imageUrl': imageUrl ?? '',
    };
  }

  // Crear desde Firestore
  factory ScanHistory.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ScanHistory(
      id: doc.id,
      breed: data['breed']?.toString() ?? 'Desconocido',
      confidence: (data['confidence'] as num?)?.toDouble() ?? 0.0,
      imagePath: data['imagePath']?.toString() ?? '',
      timestamp: data['timestamp'] != null 
          ? (data['timestamp'] as Timestamp).toDate() 
          : DateTime.now(),
      breedInfo: data['breedInfo'] is Map 
          ? Map<String, dynamic>.from(data['breedInfo']) 
          : null,
      imageUrl: data['imageUrl']?.toString(),
    );
  }
}