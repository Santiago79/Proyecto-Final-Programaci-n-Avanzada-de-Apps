import 'dart:io';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class TFLiteDataSource {
  Interpreter? _interpreter;
  List<String>? _labels;

  /// Inicializa el modelo y las etiquetas desde la carpeta de assets.
  Future<void> initializeModel() async {
    try {
      // Asegúrate de que el nombre aquí coincida con el archivo que bajaste
      _interpreter = await Interpreter.fromAsset('assets/models/model.tflite');
      
      final labelsData = await rootBundle.loadString('assets/models/labels.txt');
      
      // Limpiamos las líneas vacías
      _labels = labelsData.split('\n').where((line) => line.isNotEmpty).toList();
      
      print('✅ IA: Modelo y ${_labels!.length} etiquetas cargados con éxito');
    } catch (e) {
      print('❌ IA Error: No se pudo inicializar el modelo: $e');
      rethrow;
    }
  }

  /// Procesa la imagen y devuelve la raza con el nivel de confianza.
  Future<Map<String, dynamic>?> analyzeDogImage(String imagePath) async {
    if (_interpreter == null || _labels == null) {
      throw Exception('El modelo no ha sido inicializado.');
    }

    // 1. Decodificar la imagen desde el archivo
    final imageData = File(imagePath).readAsBytesSync();
    img.Image? originalImage = img.decodeImage(imageData);
    if (originalImage == null) return null;

    // 2. Forzar la rotación correcta leyendo los metadatos EXIF
    // Esto evita que la cámara pase la foto "acostada" al modelo
    img.Image rotatedImage = img.bakeOrientation(originalImage);

    // 3. Recorte Cuadrado (Center Crop)
    // Esto evita que la imagen se "aplaste" o deforme al cambiar de tamaño
    int size = rotatedImage.width < rotatedImage.height 
        ? rotatedImage.width 
        : rotatedImage.height;
        
    int x = (rotatedImage.width - size) ~/ 2;
    int y = (rotatedImage.height - size) ~/ 2;
    
    img.Image squareImage = img.copyCrop(
      rotatedImage, 
      x: x, 
      y: y, 
      width: size, 
      height: size
    );

    // 4. Redimensionar al tamaño que espera EfficientNetB0 (224x224)
    img.Image resizedImage = img.copyResize(squareImage, width: 224, height: 224);

    // 5. Normalización para EfficientNet (Formato Float32, Rango 0-255)
    var input = List.generate(1, (index) => 
      List.generate(224, (y) => 
        List.generate(224, (x) => 
          List.generate(3, (c) {
            final pixel = resizedImage.getPixel(x, y);
            
            // EfficientNet usa los valores RGB puros (0 a 255) como decimales
            if (c == 0) return pixel.r.toDouble();
            if (c == 1) return pixel.g.toDouble();
            return pixel.b.toDouble();
          })
        )
      )
    );

    // 6. Preparar el contenedor para la salida (Output)
    final numLabels = _labels!.length;
    var output = List.filled(1 * numLabels, 0.0).reshape([1, numLabels]);

    // 7. Ejecutar la inferencia
    _interpreter!.run(input, output);

    // 8. Lógica para encontrar el resultado con mayor confianza
    double maxScore = -1.0;
    int maxIndex = 0;
    List<double> results = List<double>.from(output[0]);

    for (int i = 0; i < results.length; i++) {
      if (results[i] > maxScore) {
        maxScore = results[i];
        maxIndex = i;
      }
    }

    // 9. Limpieza de la etiqueta para la API
    String rawLabel = _labels![maxIndex];
    String cleanBreed = rawLabel
        .replaceAll(RegExp(r'[0-9]'), '') // Quita números si los hay
        .replaceAll('_', ' ')             // Cambia guiones por espacios
        .trim();

    return {
      'breed': cleanBreed,
      'confidence': maxScore, 
    };
  }

  /// Libera los recursos del modelo.
  void dispose() {
    _interpreter?.close();
  }
}