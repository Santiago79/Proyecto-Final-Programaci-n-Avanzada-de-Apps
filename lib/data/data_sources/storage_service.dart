import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String?> uploadScanImage(String imagePath, String breed) async {
    try {
      var file = File(imagePath);
      
      // Verificar que el archivo existe
      if (!await file.exists()) {
        print('Error: El archivo no existe en la ruta: $imagePath');
        return null;
      }
      
      // Si la imagen está en el directorio temporal, la copiamos a un directorio permanente
      if (imagePath.contains('/data/user/') || imagePath.contains('/cache/') || imagePath.contains('/tmp/')) {
        final appDir = await getApplicationDocumentsDirectory();
        final permanentDir = Directory('${appDir.path}/scans');
        if (!await permanentDir.exists()) {
          await permanentDir.create(recursive: true);
        }
        
        final newPath = '${permanentDir.path}/${DateTime.now().millisecondsSinceEpoch}_${breed.replaceAll(' ', '_')}.jpg';
        file = await file.copy(newPath);
        print('Imagen copiada a: ${file.path}');
      }
      
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${breed.replaceAll(' ', '_')}.jpg';
      final ref = _storage.ref().child('scans/$fileName');
      
      await ref.putFile(file);
      return await ref.getDownloadURL();
    } catch (e) {
      print('Error al subir imagen: $e');
      return null;
    }
  }
}