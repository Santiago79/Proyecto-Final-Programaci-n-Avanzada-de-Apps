import 'package:flutter/material.dart';

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Resultados')),
      body: const Center(
        child: Text('Aquí irá la info de la raza y el chat con OpenAI'),
      ),
    );
  }
}