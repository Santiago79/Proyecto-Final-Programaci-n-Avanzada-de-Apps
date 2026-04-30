import 'dart:io';
import 'package:flutter/material.dart';
import 'package:proyecto_final/models/scan_history.dart';
import 'package:proyecto_final/presentation/widgets/favorite_button.dart';
import 'package:proyecto_final/services/history_service.dart';
import 'package:url_launcher/url_launcher.dart'; // Paquete para abrir YouTube
import '../../data/data_sources/dog_api_datasouce.dart'; 
import '../../data/data_sources/youtube_datasource.dart'; // Importa tu nuevo DataSource
import 'package:proyecto_final/services/storage_service.dart'; // Para subir la imagen a Firebase Storage

// Modifica la clase ResultsScreen a StatefulWidget
class ResultsScreen extends StatefulWidget {
  final String breed;
  final double confidence;
  final String imagePath;
  final Map<String, dynamic>? breedInfo; // Opcional, para guardar más info
  final String? existingScanId; // Para actualizar un escaneo existente en lugar de crear uno nuevo

  const ResultsScreen({
    super.key,
    required this.breed,
    required this.confidence,
    required this.imagePath,
    this.breedInfo,
    this.existingScanId,
  });

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  final HistoryService _historyService = HistoryService();
  final StorageService _storageService = StorageService();
  bool _isSaved = false;
  bool _isUploading = false;
  String? _uploadedImageUrl;

  @override
  void initState() {
    super.initState();
    if (widget.existingScanId == null) {
      _saveToHistory(); // Guardar solo si no es una actualización
    } else {
      _isSaved = true; // Ya está guardado, no necesitamos guardar de nuevo
    }
  }

  Future<void> _saveToHistory() async {
  if (_isSaved) return;
  if (widget.existingScanId != null) return;
  
  _isSaved = true;
  
  // Mostrar indicador de carga
  setState(() => _isUploading = true);
  
  // 1. Subir la imagen a Firebase Storage
  final imageUrl = await _storageService.uploadScanImage(
    widget.imagePath, 
    widget.breed
  );
  
  setState(() {
    _uploadedImageUrl = imageUrl;
    _isUploading = false;
  });
  
  // 2. Guardar en Firestore con la URL
  final scan = ScanHistory(
    breed: widget.breed,
    confidence: widget.confidence,
    imagePath: widget.imagePath,
    timestamp: DateTime.now(),
    breedInfo: widget.breedInfo,
    imageUrl: imageUrl, // 👈 Ahora sí guardamos la URL
  );

  await _historyService.saveScan(scan);
  
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
   appBar: AppBar(
  title: const Text('Resultados del Escaneo'),
  backgroundColor: const Color(0xFFE85D04),
  actions: [
    FavoriteButton(
      breed: widget.breed,
      imageUrl: _uploadedImageUrl ?? widget.breedInfo?['imageUrl'] ?? '',
      breedInfo: widget.breedInfo ?? {},
    ),
  ],
),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. Imagen que tomaste con el iPhone
            _LocalImageHeader(imagePath: widget.imagePath),

            // 2. Título de la raza detectada por TFLite
            Text(
              widget.breed.toUpperCase(),
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            
            Chip(
              label: Text('${(widget.confidence * 100).toStringAsFixed(1)}% de seguridad'),
              backgroundColor: Colors.green.shade100,
            ),

            const Divider(height: 40, indent: 20, endIndent: 20),

            // 3. SECCIÓN DE LA API (TheDogAPI)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: FutureBuilder(
                future: DogApiDataSource().getBreedInfo(widget.breed),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
                    return const _NoDataWidget();
                  }

                  final info = snapshot.data!;
                  return _BreedInfoCard(info: info);
                },
              ),
            ),

            const SizedBox(height: 30),

            // 4. SECCIÓN DE YOUTUBE (Video de cuidados)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: FutureBuilder(
                future: YouTubeDataSource().getCareVideoForBreed(widget.breed),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Colors.red));
                  }

                  // Falla elegante: Si no hay video o falla el internet, no mostramos nada
                  if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
                    return const SizedBox.shrink(); 
                  }

                  final videoData = snapshot.data!;
                  return _YouTubeVideoCard(videoData: videoData);
                },
              ),
            ),
            
            // Placeholder para el Issue 8 (OpenAI)
            const Padding(
              padding: EdgeInsets.all(30.0),
             
            ),
            
            const SizedBox(height: 20), // Espacio final
          ],
        ),
      ),
    );
  }
}

// --- Widgets de apoyo ---

class _LocalImageHeader extends StatelessWidget {
  final String imagePath;
  const _LocalImageHeader({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: AspectRatio(
          aspectRatio: 1, 
          child: Image.file(
            File(imagePath),
            fit: BoxFit.cover, 
          ),
        ),
      ),
    );
  }
}

class _BreedInfoCard extends StatelessWidget {
  final Map<String, dynamic> info;
  const _BreedInfoCard({required this.info});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.deepOrange),
                SizedBox(width: 10),
                Text('Datos de la Nube', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(),
            // Usamos la versión blindada de _InfoRow
            _InfoRow(label: 'Origen', value: info['origin']),
            _InfoRow(label: 'Temperamento', value: info['temperament']),
            _InfoRow(label: 'Esperanza de vida', value: info['life_span']),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final dynamic value; // <-- Cambiado a dynamic para aceptar nulos (¡Importante para el Pug!)

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    // Lógica anti-crasheo: Si no hay dato, mostramos un texto por defecto
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

class _NoDataWidget extends StatelessWidget {
  const _NoDataWidget();
  @override
  Widget build(BuildContext context) {
    return const Text('No se encontró información adicional de esta raza en TheDogAPI.');
  }
}

// --- NUEVO: Widget de la Tarjeta de YouTube ---
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.ondemand_video, color: Colors.red),
            SizedBox(width: 10),
            Text(
              'Video de Cuidados',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
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
              child: Icon(
                Icons.play_circle_fill,
                color: Colors.white, // Blanco para que contraste bien con el fondo oscurecido
                size: 60,
              ),
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
    );
  }
}