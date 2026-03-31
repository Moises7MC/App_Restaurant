import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/home_page.dart';
import '../../features/meals/presentation/pages/meals_page.dart';
import '../../features/meals/presentation/pages/tables_page.dart';

/// Configuración de rutas de la aplicación
///
/// Usa GoRouter para navegación declarativa.
///
/// ¿Por qué GoRouter?
/// - Navegación declarativa (más fácil de mantener)
/// - Deep linking automático
/// - Soporte para web
/// - Manejo de errores integrado
class AppRouter {
  // ═══════════════════════════════════════
  // NOMBRES DE RUTAS
  // ═══════════════════════════════════════

  /// Ruta de login
  static const String login = '/login';

  /// Ruta de selección de comidas (Desayuno, Almuerzo, Cena)
  static const String meals = '/meals';

  /// Ruta de selección de mesas
  static const String tables = '/tables';

  /// Ruta de home
  static const String home = '/home';

  // ═══════════════════════════════════════
  // CONFIGURACIÓN DEL ROUTER
  // ═══════════════════════════════════════

  /// Configuración del router
  ///
  /// Define todas las rutas de la aplicación.
  static final GoRouter router = GoRouter(
    // Ruta inicial (primera pantalla que se muestra)
    initialLocation: login,

    // Lista de rutas
    routes: [
      // ════════════════════════════════════
      // RUTA: LOGIN
      // ════════════════════════════════════
      GoRoute(
        path: login,
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),

      // ════════════════════════════════════
      // RUTA: MEALS (SELECCIONAR COMIDA)
      // ════════════════════════════════════
      GoRoute(
        path: meals,
        name: 'meals',
        builder: (context, state) => const MealsPage(),
      ),

      // ════════════════════════════════════
      // RUTA: TABLES (SELECCIONAR MESA)
      // ════════════════════════════════════
      GoRoute(
        path: '/tables/:mealType',
        name: 'tables',
        builder: (context, state) {
          // Obtener el parámetro mealType de la URL
          final mealType = state.pathParameters['mealType'] ?? 'Almuerzo';
          return TablesPage(mealType: mealType);
        },
      ),

      // ════════════════════════════════════
      // RUTA: HOME
      // ════════════════════════════════════
      GoRoute(
        path: home,
        name: 'home',
        builder: (context, state) => const HomePage(),
      ),

      // Aquí agregarás más rutas en el futuro:
      // - /products
      // - /cart
      // - /checkout
      // - /orders
    ],

    // ════════════════════════════════════
    // MANEJO DE ERRORES
    // ════════════════════════════════════

    /// Página de error (cuando la ruta no existe)
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

/// Extensión para facilitar la navegación
///
/// Permite usar:
/// ```dart
/// context.goToMeals();
/// context.goToTables('Almuerzo');
/// context.goToHome();
/// context.goToLogin();
/// ```
///
/// En lugar de:
/// ```dart
/// context.go('/meals');
/// context.go('/tables/Almuerzo');
/// ```
extension NavigationExtension on BuildContext {
  /// Navega a la pantalla de login
  void goToLogin() => go(AppRouter.login);

  /// Navega a la pantalla de selección de comidas
  void goToMeals() => go(AppRouter.meals);

  /// Navega a la pantalla de selección de mesas
  ///
  /// [mealType] Tipo de comida seleccionada (Desayuno, Almuerzo, Cena)

  // void goToTables(String mealType) =>
  //     pushNamed('tables', pathParameters: {'mealType': mealType});

  void goToTables(String mealType) => go('/tables/$mealType');

  /// Navega a la pantalla de home
  void goToHome() => go(AppRouter.home);

  /// Regresa a la pantalla anterior
  void goBack() => pop();
}
