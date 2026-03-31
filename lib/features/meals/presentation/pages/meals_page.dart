import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/routes/app_router.dart';

/// Página de selección de comidas
///
/// Muestra 3 opciones: Desayuno, Almuerzo y Cena
/// Cada una en una card con ícono, nombre y descripción
class MealsPage extends StatelessWidget {
  const MealsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ════════════════════════════════════
      // APP BAR
      // ════════════════════════════════════
      appBar: AppBar(title: const Text('¿Qué deseas comer?'), elevation: 0),

      // ════════════════════════════════════
      // BODY
      // ════════════════════════════════════
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),

              // ════════════════════════════════════
              // CARD 1: DESAYUNO
              // ════════════════════════════════════
              _buildMealCard(
                context,
                icon: '🌅',
                name: 'Desayuno',
                description: 'Comidas ligeras y nutritivas para empezar el día',
                onPressed: () {
                  // Solo para Almuerzo, el resto no hace nada
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Funcionalidad próximamente'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              // ════════════════════════════════════
              // CARD 2: ALMUERZO
              // ════════════════════════════════════
              _buildMealCard(
                context,
                icon: '🍽️',
                name: 'Almuerzo',
                description: 'Platos principales y abundantes para el mediodía',
                onPressed: () {
                  // Navegar a TablesPage pasando "Almuerzo"
                  context.goToTables('Almuerzo');
                },
              ),

              const SizedBox(height: 20),

              // ════════════════════════════════════
              // CARD 3: CENA
              // ════════════════════════════════════
              _buildMealCard(
                context,
                icon: '🌙',
                name: 'Cena',
                description: 'Opciones deliciosas para la noche',
                onPressed: () {
                  // Solo para Almuerzo, el resto no hace nada
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Funcionalidad próximamente'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  /// Widget helper para construir cada card de comida
  Widget _buildMealCard(
    BuildContext context, {
    required String icon,
    required String name,
    required String description,
    required VoidCallback onPressed,
  }) {
    return Container(
      // ════════════════════════════════════
      // ESTILOS DEL CARD
      // ════════════════════════════════════
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),

      // ════════════════════════════════════
      // CONTENIDO DEL CARD
      // ════════════════════════════════════
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ════════════════════════════════════
          // ÍCONO GRANDE
          // ════════════════════════════════════
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(icon, style: const TextStyle(fontSize: 40)),
            ),
          ),

          const SizedBox(height: 16),

          // ════════════════════════════════════
          // NOMBRE DE LA COMIDA
          // ════════════════════════════════════
          Text(
            name,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 8),

          // ════════════════════════════════════
          // DESCRIPCIÓN
          // ════════════════════════════════════
          Text(
            description,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),

          const SizedBox(height: 16),

          // ════════════════════════════════════
          // BOTÓN "SELECCIONAR" (CLICKEABLE)
          // ════════════════════════════════════
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: onPressed,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Ver opciones →',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
