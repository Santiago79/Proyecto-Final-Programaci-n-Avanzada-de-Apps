import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'presentation/routes/app_router.dart';
import 'presentation/theme/app_theme.dart';

void main() {
  runApp(
    // ProviderScope es OBLIGATORIO para que Riverpod funcione en toda la app
    const ProviderScope(
      child: MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'DogScanner',
      debugShowCheckedModeBanner: false,
      theme: AppTheme().getTheme(),
      // Conectamos GoRouter
      routerConfig: appRouter, 
    );
  }
}