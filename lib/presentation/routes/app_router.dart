import 'package:go_router/go_router.dart';
import 'package:proyecto_final/presentation/screens/favorite_screen.dart';
// Imports de pantallas
import 'package:proyecto_final/presentation/screens/scanner_screen.dart';
import 'package:proyecto_final/presentation/screens/history_screen.dart';
import 'package:proyecto_final/presentation/screens/results_screen.dart';
import 'package:proyecto_final/presentation/screens/stats_screen.dart';

import 'package:proyecto_final/presentation/widgets/scaffold_with_navbar.dart'; 

final appRouter = GoRouter(
  initialLocation: '/scanner',
  routes: [
    ShellRoute(
      builder: (context, state, child) => ScaffoldWithNavbar(child: child),
      routes: [
        GoRoute(
          path: '/scanner',
          name: 'scanner',
          builder: (context, state) => const ScannerScreen(),
        ),
        // GoRoute(
        //   path: '/favorites',
        //   name: 'favorites',
        //   builder: (context, state) => const FavoritesScreen(),
        // ),
        GoRoute(
          path: '/stats',
          name: 'stats',
          builder: (context, state) => const StatsScreen(),
        ),
        GoRoute(
          path: '/favorites',
          name: 'favorites',
          builder: (context, state) => const FavoritesScreen(),
        ),
         GoRoute(
      path: '/results',
      name: 'results',
      builder: (context, state) {
        final data = state.extra as Map<String, dynamic>;
        return ResultsScreen(
          breed: data['breed'],
          confidence: data['confidence'],
          imagePath: data['imagePath'],
          breedInfo: data['breedInfo'],  // 👈 Agregado
          existingScanId: data['existingScanId'],  // 👈 Agregado para evitar duplicados
        );
      },
    ),
      ],
    ),
    // Rutas que NO tienen la barra de navegación
   
  ],
);