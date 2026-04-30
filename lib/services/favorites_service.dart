import 'package:cloud_firestore/cloud_firestore.dart';

class FavoritesService {
  final CollectionReference _favoritesCollection = 
      FirebaseFirestore.instance.collection('favoritos');

  /// Agregar una raza a favoritos
  Future<void> addFavorite({
    required String breed,
    required String imageUrl,
    required Map<String, dynamic> breedInfo,
  }) async {
    try {
      // Verificar si ya existe
      final existing = await _favoritesCollection
          .where('breed', isEqualTo: breed)
          .get();
      
      if (existing.docs.isEmpty) {
        await _favoritesCollection.add({
          'breed': breed,
          'imageUrl': imageUrl,
          'breedInfo': breedInfo,
          'fechaAgregado': FieldValue.serverTimestamp(),
        });
        print('✅ Favorito agregado: $breed');
      }
    } catch (e) {
      print('❌ Error al agregar favorito: $e');
    }
  }

  /// Eliminar una raza de favoritos
  Future<void> removeFavorite(String breed) async {
    try {
      final snapshot = await _favoritesCollection
          .where('breed', isEqualTo: breed)
          .get();
      
      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }
      print('✅ Favorito eliminado: $breed');
    } catch (e) {
      print('❌ Error al eliminar favorito: $e');
    }
  }

  /// Verificar si una raza está en favoritos
  Future<bool> isFavorite(String breed) async {
    try {
      final snapshot = await _favoritesCollection
          .where('breed', isEqualTo: breed)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('❌ Error al verificar favorito: $e');
      return false;
    }
  }

  /// Stream de favoritos (para la pantalla)
  Stream<List<Map<String, dynamic>>> getFavoritesStream() {
    return _favoritesCollection
        .orderBy('fechaAgregado', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        };
      }).toList();
    });
  }
}