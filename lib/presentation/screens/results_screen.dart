import 'dart:io';
import 'package:flutter/material.dart';
import '../../data/data_sources/dog_api_datasouce.dart'; // Importa tu DataSource de la API

class ResultsScreen extends StatelessWidget {
  final String breed;
  final double confidence;
  final String imagePath;

  const ResultsScreen({
    super.key, 
    required this.breed, 
    required this.confidence, 
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultados del Escaneo'),
        backgroundColor: const Color(0xFFE85D04), // Naranja USFQ
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. Imagen que tomaste con el iPhone
            _LocalImageHeader(imagePath: imagePath),

            // 2. Título de la raza detectada por TFLite
            Text(
              breed.toUpperCase(),
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            
            Chip(
              label: Text('IA local: ${(confidence * 100).toStringAsFixed(1)}% de seguridad'),
              backgroundColor: Colors.green.shade100,
            ),

            const Divider(height: 40, indent: 20, endIndent: 20),

            // 3. SECCIÓN DE LA API (Issue 7)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: FutureBuilder(
                // Llamamos a la API usando el nombre que detectó tu modelo
                future: DogApiDataSource().getBreedInfo(breed),
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
            
            // Placeholder para el Issue 8 (OpenAI)
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Text(
                'Próximamente: Chat con IA para saber más.',
                style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Widgets de apoyo para que el código sea legible ---

class _LocalImageHeader extends StatelessWidget {
  final String imagePath;
  const _LocalImageHeader({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 250,
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))],
        image: DecorationImage(
          image: FileImage(File(imagePath)),
          fit: BoxFit.cover,
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
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black87, fontSize: 16),
          children: [
            TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: value),
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