import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../../core/constants/app_colors.dart';

/// Pantalla principal después del login
///
/// Por ahora es una pantalla simple que muestra:
/// - Datos del usuario autenticado
/// - Botón de logout
/// - Mensaje de "Próximamente" para futuras funcionalidades
///
/// En los próximos pasos agregaremos:
/// - Catálogo de productos
/// - Carrito de compras
/// - Historial de órdenes
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ════════════════════════════════════
      // APP BAR
      // ════════════════════════════════════
      appBar: AppBar(
        title: const Text('Restaurant App'),
        actions: [
          // Botón de logout
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () {
              // Mostrar confirmación
              _showLogoutDialog(context);
            },
          ),
        ],
      ),

      // ════════════════════════════════════
      // BODY
      // ════════════════════════════════════
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          // Si el usuario está autenticado, mostrar su info
          if (state is AuthAuthenticated) {
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ════════════════════════════════════
                    // ÍCONO DE ÉXITO
                    // ════════════════════════════════════
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        size: 80,
                        color: AppColors.white,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ════════════════════════════════════
                    // MENSAJE DE BIENVENIDA
                    // ════════════════════════════════════
                    Text(
                      '¡Bienvenido!',
                      style: Theme.of(context).textTheme.displayMedium,
                    ),

                    const SizedBox(height: 16),

                    // ════════════════════════════════════
                    // NOMBRE DEL USUARIO
                    // ════════════════════════════════════
                    Text(
                      state.user.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // ════════════════════════════════════
                    // EMAIL DEL USUARIO
                    // ════════════════════════════════════
                    Text(
                      state.user.email,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),

                    const SizedBox(height: 48),

                    // ════════════════════════════════════
                    // CARD DE "PRÓXIMAMENTE"
                    // ════════════════════════════════════
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.shadow,
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.construction,
                            size: 48,
                            color: AppColors.primary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Próximamente',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Aquí verás el catálogo de productos, carrito de compras y más funcionalidades.',
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ════════════════════════════════════
                    // INFORMACIÓN DE ID (para debugging)
                    // ════════════════════════════════════
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'ID: ${state.user.id}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // Si no está autenticado, mostrar loading
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  /// Muestra diálogo de confirmación para logout
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro que deseas cerrar sesión?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          // Botón CANCELAR
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),

          // Botón CERRAR SESIÓN
          ElevatedButton(
            onPressed: () {
              // Cerrar el diálogo
              Navigator.of(dialogContext).pop();

              // Enviar evento de logout
              context.read<AuthBloc>().add(LogoutButtonPressed());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
  }
}
