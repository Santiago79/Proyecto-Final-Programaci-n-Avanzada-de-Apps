import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ScannerScreen extends StatelessWidget {
  const ScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dog Scanner')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => context.push('/results'),
          child: const Text('Simular Escaneo (Ir a Resultados)'),
        ),
      ),
    );
  }
}