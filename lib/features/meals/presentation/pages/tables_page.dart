import 'package:app_restaurant/features/meals/domain/entities/RestaurantTable.dart';
import 'package:app_restaurant/features/meals/presentation/bloc/cart_bloc.dart';
import 'package:app_restaurant/features/meals/presentation/bloc/cart_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/routes/app_router.dart';
import '../bloc/cart_bloc.dart';

class TablesPage extends StatefulWidget {
  final String mealType;

  const TablesPage({super.key, required this.mealType});

  @override
  State<TablesPage> createState() => _TablesPageState();
}

class _TablesPageState extends State<TablesPage> {
  @override
  Widget build(BuildContext context) {
    final tables = _generateTables();

    return Scaffold(
      appBar: AppBar(
        title: Text('Selecciona tu mesa - ${widget.mealType}'),
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Elige una mesa disponible',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.0,
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

  Widget _buildTableCard(BuildContext context, RestaurantTable table) {
    return BlocBuilder<CartBloc, CartState>(
      builder: (context, state) {
        final cartBloc = context.read<CartBloc>();
        final isOccupied = cartBloc.isTableOccupied(
          widget.mealType,
          table.number,
        );
        final itemCount = cartBloc.getTableItemCount(
          widget.mealType,
          table.number,
        );

        return GestureDetector(
          onTap: () {
            context.goToProducts(widget.mealType, table.number);
          },
          child: Container(
            decoration: BoxDecoration(
              color: isOccupied
                  ? AppColors.primary.withOpacity(0.15)
                  : AppColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isOccupied ? AppColors.primary : AppColors.border,
                width: isOccupied ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isOccupied
                      ? AppColors.primary.withOpacity(0.2)
                      : AppColors.shadow,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: isOccupied
                        ? AppColors.primary
                        : AppColors.primaryLight.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.table_restaurant,
                    size: 32,
                    color: isOccupied ? AppColors.white : AppColors.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Mesa ${table.number}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isOccupied
                        ? AppColors.primary
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                if (isOccupied)
                  Text(
                    '🔴 Ocupada ($itemCount items)',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                else
                  Text(
                    '✅ Libre • ${table.capacity} personas',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<RestaurantTable> _generateTables() {
    final tables = <RestaurantTable>[];
    for (int i = 1; i <= 10; i++) {
      final capacity = i % 2 == 0 ? 4 : 2;
      tables.add(
        RestaurantTable(id: 'table_$i', number: i, capacity: capacity),
      );
    }
    return tables;
  }
}
