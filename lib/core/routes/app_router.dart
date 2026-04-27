import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/home_page.dart';
import '../../features/meals/presentation/pages/meals_page.dart';
import '../../features/meals/presentation/pages/tables_page.dart';
import '../../features/meals/presentation/pages/products_page.dart';
import '../../features/cantador/presentation/pages/cantador_home_page.dart';

/// Configuración de rutas de la aplicación
class AppRouter {
  // ═══════════════════════════════════════
  // NOMBRES DE RUTAS
  // ═══════════════════════════════════════

  static const String login = '/login';
  static const String meals = '/meals';
  static const String tables = '/tables';
  static const String products = '/products';
  static const String home = '/home';

  /// ✅ NUEVO: pantalla principal del cantador (3 tabs)
  static const String cantador = '/cantador';

  // ═══════════════════════════════════════
  // CONFIGURACIÓN DEL ROUTER
  // ═══════════════════════════════════════

  static final GoRouter router = GoRouter(
    initialLocation: login,

    routes: [
      GoRoute(
        path: login,
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),

      GoRoute(
        path: meals,
        name: 'meals',
        builder: (context, state) => const MealsPage(),
      ),

      GoRoute(
        path: '/tables/:mealType',
        name: 'tables',
        builder: (context, state) {
          final mealType = state.pathParameters['mealType'] ?? 'Almuerzo';
          return TablesPage(mealType: mealType);
        },
      ),

      GoRoute(
        path: '/products/:mealType/:tableNumber',
        name: 'products',
        builder: (context, state) {
          final mealType = state.pathParameters['mealType'] ?? 'Almuerzo';
          final tableNumberStr = state.pathParameters['tableNumber'] ?? '1';
          final tableNumber = int.tryParse(tableNumberStr) ?? 1;

          return ProductsPage(mealType: mealType, tableNumber: tableNumber);
        },
      ),

      GoRoute(
        path: home,
        name: 'home',
        builder: (context, state) => const HomePage(),
      ),

      // ════════════════════════════════════
      // ✅ RUTA: CANTADOR (3 tabs)
      // ════════════════════════════════════
      GoRoute(
        path: cantador,
        name: 'cantador',
        builder: (context, state) => const CantadorHomePage(),
      ),
    ],

    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 80, color: Colors.red),
              const SizedBox(height: 24),
              Text(
                'Página no encontrada',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                state.uri.toString(),
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go(login),
                child: const Text('Ir al inicio'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

// ═══════════════════════════════════════
// EXTENSIONES PARA NAVEGACIÓN FÁCIL
// ═══════════════════════════════════════

extension NavigationExtension on BuildContext {
  void goToLogin() => go(AppRouter.login);
  void goToMeals() => go(AppRouter.meals);
  void goToTables(String mealType) => go('/tables/$mealType');
  void goToProducts(String mealType, int tableNumber) =>
      go('/products/$mealType/$tableNumber');
  void goToHome() => go(AppRouter.home);

  /// ✅ NUEVO
  void goToCantador() => go(AppRouter.cantador);

  void goBack() => pop();
}
