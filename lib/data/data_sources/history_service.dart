import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/scan_history.dart';

class HistoryService {
  final CollectionReference _historyCollection = 
      FirebaseFirestore.instance.collection('historial');

  // Guardar un escaneo
  Future<void> saveScan(ScanHistory scan) async {
    try {
      await _historyCollection.add(scan.toMap());
         } catch (e) {
      
    }
  }

  // Obtener todo el historial (Stream en tiempo real)
  Stream<List<ScanHistory>> getHistoryStream() {
    return _historyCollection
        .orderBy('timestamp', descending: true) // Más reciente primero
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ScanHistory.fromFirestore(doc))
          .toList();
    });
  }

  // Eliminar un escaneo específico
  Future<void> deleteScan(String id) async {
    await _historyCollection.doc(id).delete();
  }

  // Eliminar todo el historial
  Future<void> clearAllHistory() async {
    final snapshot = await _historyCollection.get();
    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  // Contar cuántas veces se ha escaneado una raza
Future<int> getScanCountForBreed(String breed) async {
  final snapshot = await _historyCollection.where('breed', isEqualTo: breed).get();
  return snapshot.docs.length;
}
}