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
      // 1. Cargamos el modelo .tflite
      _interpreter = await Interpreter.fromAsset('assets/models/model.tflite');
      
      // 2. Cargamos el archivo labels.txt usando rootBundle
      final labelsData = await rootBundle.loadString('assets/models/labels.txt');
      
      // Limpiamos las líneas vacías para evitar errores de índice
      _labels = labelsData.split('\n').where((line) => line.isNotEmpty).toList();
      
      print('✅ IA: Modelo y etiquetas cargados con éxito');
    } catch (e) {
      print('❌ IA Error: No se pudo inicializar el modelo: $e');
      rethrow;
    }
  }

  /// Procesa la imagen y devuelve la raza con el nivel de confianza.
  Future<Map<String, dynamic>?> analyzeDogImage(String imagePath) async {
    // Verificación de seguridad
    if (_interpreter == null || _labels == null) {
      throw Exception('El modelo no ha sido inicializado.');
    }

    // 1. Decodificar la imagen desde el archivo
    final imageData = File(imagePath).readAsBytesSync();
    img.Image? image = img.decodeImage(imageData);
    if (image == null) return null;

    // 2. Redimensionar al tamaño que espera el modelo (224x224)
    img.Image resizedImage = img.copyResize(image, width: 224, height: 224);

    // 3. Normalización y conversión a Float32
    // Formato: [1, 224, 224, 3] (Batch, Height, Width, Channels)
    var input = List.generate(1, (index) => 
      List.generate(224, (y) => 
        List.generate(224, (x) => 
          List.generate(3, (c) {
            final pixel = resizedImage.getPixel(x, y);
            
            // Normalizamos de 0-255 a un rango de -1 a 1 (estándar de Teachable Machine)
            if (c == 0) return (pixel.r - 127.5) / 127.5;
            if (c == 1) return (pixel.g - 127.5) / 127.5;
            return (pixel.b - 127.5) / 127.5;
          })
        )
      )
    );

    // 4. Preparar el contenedor para la salida (Output)
    // Debe tener el tamaño exacto de tu lista de etiquetas
    final numLabels = _labels!.length;
    var output = List.filled(1 * numLabels, 0.0).reshape([1, numLabels]);

    // 5. Ejecutar la inferencia
    _interpreter!.run(input, output);

    // 6. Lógica para encontrar el resultado con mayor confianza
    double maxScore = -1.0;
    int maxIndex = 0;
    List<double> results = List<double>.from(output[0]);

    for (int i = 0; i < results.length; i++) {
      if (results[i] > maxScore) {
        maxScore = results[i];
        maxIndex = i;
      }
    }

    // 7. Limpieza de la etiqueta para la API
    // rawLabel puede ser "0 Boston_bull" o "2 Bloodhound"
    String rawLabel = _labels![maxIndex];

    // Removemos números, guiones bajos y espacios innecesarios
    String cleanBreed = rawLabel
        .replaceAll(RegExp(r'[0-9]'), '') // Quita números
        .replaceAll('_', ' ')             // Cambia guiones por espacios
        .trim();                          // Limpia extremos

    return {
      'breed': cleanBreed,
      'confidence': maxScore, // Valor entre 0.0 y 1.0
    };
  }

  /// Libera los recursos del modelo cuando ya no se necesitan.
  void dispose() {
    _interpreter?.close();
  }
}