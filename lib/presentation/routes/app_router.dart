import 'package:go_router/go_router.dart';
// Imports de pantallas
import 'package:proyecto_final/presentation/screens/scanner_screen.dart';
import 'package:proyecto_final/presentation/screens/history_screen.dart';
import 'package:proyecto_final/presentation/screens/results_screen.dart';
// Import del widget de la barra (AQUÍ ESTABA EL ERROR)
import 'package:proyecto_final/presentation/widgets/scaffold_with_navbar.dart'; 

final appRouter = GoRouter(
  initialLocation: '/scanner',
  routes: [
    ShellRoute(
      builder: (context, state, child) => ScaffoldWithNavbar(child: child),
      routes: [
        GoRoute(
          path: '/scanner',
          builder: (context, state) => const ScannerScreen(),
        ),
        GoRoute(
          path: '/history',
          builder: (context, state) => const HistoryScreen(),
        ),
      ],
    ),
    GoRoute(
      path: '/results',
      builder: (context, state) {
        final data = state.extra as Map<String, dynamic>;
        return ResultsScreen(
          breed: data['breed'],
          confidence: data['confidence'],
          imagePath: data['imagePath'],
        );
      },
    ),
  ],
);