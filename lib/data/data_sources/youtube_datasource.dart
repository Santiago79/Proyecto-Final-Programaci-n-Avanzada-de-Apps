import 'dart:convert';
import 'package:http/http.dart' as http;

class YouTubeDataSource {
  // ⚠️ OJO: Para tu defensa pon la llave aquí, pero en el mundo real 
  // esto va en un archivo .env para no subirlo a GitHub.
  static const String _apiKey = 'AIzaSyCy2qca91_5BMDZDpQJ_EtFMQ_00RK_I-s'; 
  static const String _baseUrl = 'https://www.googleapis.com/youtube/v3';

  Future<Map<String, String>?> getCareVideoForBreed(String breedName) async {
    try {
      // 1. Armamos la búsqueda inteligente
      final query = Uri.encodeComponent('cuidados del perro raza $breedName');
      
      // 2. Pedimos a YouTube: "Dame el primer video relevante (maxResults=1)"
      final url = Uri.parse(
          '$_baseUrl/search?part=snippet&q=$query&type=video&maxResults=1&key=$_apiKey');

      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // 3. Verificamos que YouTube haya encontrado algo
        if (data['items'] != null && (data['items'] as List).isNotEmpty) {
          final item = data['items'][0];
          
          return {
            'videoId': item['id']['videoId'],
            'title': item['snippet']['title'], // Título del video
            'thumbnail': item['snippet']['thumbnails']['high']['url'], // Foto de portada
          };
        }
      }
      return null;
    } catch (e) {
      print('❌ Error en YouTube API: $e');
      return null;
    }
  }
}