import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/di/dependency_injection.dart';
import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/auth/presentation/bloc/auth_state.dart';

/// Punto de entrada de la aplicación
///
/// Este es el primer método que se ejecuta cuando
/// se inicia la app.
void main() async {
  // ═══════════════════════════════════════
  // INICIALIZACIÓN
  // ═══════════════════════════════════════

  // Asegurar que Flutter esté inicializado
  // IMPORTANTE: Necesario cuando usamos async en main
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar dependencias
  debugPrint('🚀 Iniciando Restaurant App...\n');
  final di = DependencyInjection();
  await di.init();

  // Ejecutar la app
  runApp(MyApp(di: di));
}

/// Widget raíz de la aplicación
///
/// Este es el widget principal que contiene toda la app.
class MyApp extends StatelessWidget {
  /// Dependency Injection
  final DependencyInjection di;

  const MyApp({super.key, required this.di});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      // ════════════════════════════════════
      // PROVEER AuthBloc A TODA LA APP
      // ════════════════════════════════════

      /// Creamos el AuthBloc y lo proveemos a toda la app.
      /// Cualquier widget puede acceder a él con:
      /// context.read<AuthBloc>() o context.watch<AuthBloc>()
      create: (context) =>
          di.createAuthBloc()
            ..add(CheckAuthStatus()), // Verificar sesión al inicio

      child: BlocListener<AuthBloc, AuthState>(
        // ════════════════════════════════════
        // ESCUCHAR CAMBIOS DE AUTENTICACIÓN
        // ════════════════════════════════════

        /// Este listener escucha cambios en el estado de autenticación
        /// y navega automáticamente a la pantalla correspondiente.
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            // Usuario autenticado → ir a MEALS (seleccionar comida)
            // CAMBIO: Antes iba a /home, ahora va a /meals
            debugPrint('✅ Usuario autenticado: ${state.user.name}');
            AppRouter.router.go(AppRouter.meals);
          } else if (state is AuthUnauthenticated) {
            // Usuario no autenticado → ir a Login
            debugPrint('⚠️  Usuario no autenticado');
            AppRouter.router.go(AppRouter.login);
          } else if (state is AuthError) {
            // Error de autenticación
            debugPrint('❌ Error de autenticación: ${state.message}');
          }
        },

        child: MaterialApp.router(
          // ════════════════════════════════════
          // CONFIGURACIÓN DE LA APP
          // ════════════════════════════════════

          /// Título de la aplicación
          title: 'Restaurant App',

          /// Ocultar banner de debug
          debugShowCheckedModeBanner: false,

          /// Aplicar tema personalizado
          theme: AppTheme.lightTheme,

          /// Configuración de rutas con GoRouter
          routerConfig: AppRouter.router,
        ),
      ),
    );
  }
}
