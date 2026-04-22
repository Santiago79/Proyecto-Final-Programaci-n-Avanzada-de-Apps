import 'package:dio/dio.dart';

class DogApiDataSource {
  final _dio = Dio(BaseOptions(
    baseUrl: 'https://api.thedogapi.com/v1',
    headers: {'x-api-key': 'live_EMGnky8xzXbddf2dLmESfltHwKhIOadIZtSIdUQChdyOdz8RXx9gqLviHYZ8ITdN'},
  ));

  Future<Map<String, dynamic>?> getBreedInfo(String breedName) async {
    try {
      // 1. Buscamos la raza por nombre
      final response = await _dio.get('/breeds/search', queryParameters: {'q': breedName});
      
      if (response.data is List && (response.data as List).isNotEmpty) {
        final breedData = response.data[0];
        
        // 2. Obtenemos una imagen oficial de esa raza
        final imageId = breedData['reference_image_id'];
        String? imageUrl;
        if (imageId != null) {
          final imgRes = await _dio.get('/images/$imageId');
          imageUrl = imgRes.data['url'];
        }

        return {
          'name': breedData['name'],
          'origin': breedData['origin'] ?? 'Desconocido',
          'temperament': breedData['temperament'],
          'life_span': breedData['life_span'],
          'image_url': imageUrl,
        };
      }
      return null;
    } catch (e) {
      print('Error en DogAPI: $e');
      return null;
    }
  }
}