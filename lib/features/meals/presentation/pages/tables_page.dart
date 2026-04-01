import 'package:app_restaurant/features/meals/domain/entities/RestaurantTable.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/routes/app_router.dart';

/// Página de selección de mesas
///
/// Muestra un grid de mesas disponibles para seleccionar.
/// Al hacer clic en una mesa, navega al catálogo de productos.
class TablesPage extends StatelessWidget {
  /// Tipo de comida seleccionada (Desayuno, Almuerzo, Cena)
  /// Se recibe como parámetro de navegación
  final String mealType;

  const TablesPage({super.key, required this.mealType});

  @override
  Widget build(BuildContext context) {
    // Crear 10 mesas de ejemplo
    final tables = _generateTables();

    return Scaffold(
      // ════════════════════════════════════
      // APP BAR
      // ════════════════════════════════════
      appBar: AppBar(
        title: Text('Selecciona tu mesa - $mealType'),
        elevation: 0,
      ),

      // ════════════════════════════════════
      // BODY
      // ════════════════════════════════════
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ════════════════════════════════════
              // INSTRUCCIÓN
              // ════════════════════════════════════
              Text(
                'Elige una mesa disponible',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: 24),

              // ════════════════════════════════════
              // GRID DE MESAS
              // ════════════════════════════════════
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // 2 columnas
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.0, // Cuadrado perfecto
                  ),
                  itemCount: tables.length,
                  itemBuilder: (context, index) {
                    final table = tables[index];
                    return _buildTableCard(context, table);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Widget para construir cada card de mesa (CLICKEABLE)
  Widget _buildTableCard(BuildContext context, RestaurantTable table) {
    return GestureDetector(
      // Al hacer clic en la mesa, navegar a ProductsPage
      onTap: () {
        context.goToProducts(mealType, table.number);
      },
      child: Container(
        // ════════════════════════════════════
        // ESTILOS DEL CARD
        // ════════════════════════════════════
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 1),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),

        // ════════════════════════════════════
        // CONTENIDO DEL CARD
        // ════════════════════════════════════
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ════════════════════════════════════
            // ÍCONO DE MESA
            // ════════════════════════════════════
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.table_restaurant,
                size: 32,
                color: AppColors.primary,
              ),
            ),

            const SizedBox(height: 16),

            // ════════════════════════════════════
            // NÚMERO DE MESA
            // ════════════════════════════════════
            Text(
              'Mesa ${table.number}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 4),

            // ════════════════════════════════════
            // CAPACIDAD
            // ════════════════════════════════════
            Text(
              '${table.capacity} personas',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  /// Genera 10 mesas de ejemplo
  List<RestaurantTable> _generateTables() {
    final tables = <RestaurantTable>[];

    // Crear 10 mesas con capacidades alternadas
    for (int i = 1; i <= 10; i++) {
      final capacity = i % 2 == 0 ? 4 : 2; // Alterna entre 2 y 4 personas

      tables.add(
        RestaurantTable(id: 'table_$i', number: i, capacity: capacity),
      );
    }

    return tables;
  }
}
