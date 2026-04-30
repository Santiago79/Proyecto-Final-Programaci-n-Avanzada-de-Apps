import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/data_sources/dog_api_datasouce.dart';
import '../../data/data_sources/youtube_datasource.dart';
import '../../services/history_service.dart';
import '../../services/favorites_service.dart';

class FavoriteDetailScreen extends StatefulWidget {
  final String breed;
  final Map<String, dynamic> breedInfo;

  const FavoriteDetailScreen({
    super.key,
    required this.breed,
    required this.breedInfo,
  });

  @override
  State<FavoriteDetailScreen> createState() => _FavoriteDetailScreenState();
}

class _FavoriteDetailScreenState extends State<FavoriteDetailScreen> {
  final DogApiDataSource _dogApi = DogApiDataSource();
  final YouTubeDataSource _youtubeDataSource = YouTubeDataSource();
  final HistoryService _historyService = HistoryService();
  final FavoritesService _favoritesService = FavoritesService();
  
  Map<String, dynamic>? _breedInfo;
  Map<String, String>? _videoData;
  bool _isLoading = true;
  int _scanCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
    _countScans();
  }

  Future<void> _loadData() async {
    final info = await _dogApi.getBreedInfo(widget.breed);
    final video = await _youtubeDataSource.getCareVideoForBreed(widget.breed);
    
    setState(() {
      _breedInfo = info ?? widget.breedInfo;
      _videoData = video;
      _isLoading = false;
    });
  }

  Future<void> _countScans() async {
    // Convertir a minúsculas para buscar correctamente en Firestore
    final breedLower = widget.breed.toLowerCase();
    final count = await _historyService.getScanCountForBreed(breedLower);
    setState(() {
      _scanCount = count;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFE85D04),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _confirmDelete,
            tooltip: 'Eliminar de favoritos',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Título de la raza en mayúsculas
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      widget.breed.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Contador de escaneos
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Has escaneado esta raza $_scanCount veces',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Información de la raza
                  if (_breedInfo != null) ...[
                    _BreedInfoCard(info: _breedInfo!),
                    const SizedBox(height: 16),
                  ],
                  
                  // Video de cuidados
                  if (_videoData != null)
                    _YouTubeVideoCard(videoData: _videoData!),
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }


  void _confirmDelete() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar de favoritos'),
        content: Text('¿Estás seguro de que quieres eliminar ${widget.breed} de tus favoritos?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      // Convertir a minúsculas para eliminar correctamente
      final breedLower = widget.breed.toLowerCase();
      await _favoritesService.removeFavorite(breedLower);
      if (mounted) {
        Navigator.pop(context, true); // Regresar y notificar que se eliminó
      }
    }
  }
}

// Widgets de apoyo
class _BreedInfoCard extends StatelessWidget {
  final Map<String, dynamic> info;
  const _BreedInfoCard({required this.info});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.deepOrange),
                SizedBox(width: 10),
                Text('Datos de la Raza', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(),
            _InfoRow(label: 'Origen', value: info['origin']),
            _InfoRow(label: 'Temperamento', value: info['temperament']),
            _InfoRow(label: 'Esperanza de vida', value: info['life_span']),
            if (info['bred_for'] != null && info['bred_for'].toString().isNotEmpty)
              _InfoRow(label: 'Criado para', value: info['bred_for']),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final dynamic value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final String safeValue = (value == null || value.toString().trim().isEmpty) 
        ? 'No registrado' 
        : value.toString();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black87, fontSize: 16),
          children: [
            TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: safeValue),
          ],
        ),
      ),
    );
  }
}

class _YouTubeVideoCard extends StatelessWidget {
  final Map<String, String> videoData;
  const _YouTubeVideoCard({required this.videoData});

  Future<void> _launchYouTube() async {
    final videoId = videoData['videoId'];
    final url = Uri.parse('https://www.youtube.com/watch?v=$videoId');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      print('No se pudo abrir YouTube');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.ondemand_video, color: Colors.red),
              SizedBox(width: 10),
              Text('Video de Cuidados', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _launchYouTube,
            child: Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                image: DecorationImage(
                  image: NetworkImage(videoData['thumbnail']!),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(0.3),
                    BlendMode.darken,
                  ),
                ),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))
                ],
              ),
              child: const Center(
                child: Icon(Icons.play_circle_fill, color: Colors.white, size: 60),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            videoData['title']!,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}