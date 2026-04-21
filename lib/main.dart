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

class MainApp extends ConsumerWidget { // Cambiado a ConsumerWidget
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) { // Agregado WidgetRef
    return MaterialApp.router(
      title: 'Scanner de Perros',
      debugShowCheckedModeBanner: false,
      theme: AppTheme().getTheme(),
      routerConfig: appRouter, 
    );
  }
}