import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/routes/app_router.dart';
import '../bloc/cart_bloc.dart';
import '../bloc/cart_event.dart';
import '../bloc/cart_state.dart';
import '../bloc/cash_flow_bloc.dart';
import '../bloc/cash_flow_event.dart';
import '../../domain/entities/cart_item.dart';
import '../../../../services/api_service.dart';

/// Página del carrito de compras
///
/// Muestra:
/// - Lista de items en el carrito
/// - Cantidad y precio de cada item
/// - Subtotal y total
/// - Botón para confirmar el pedido
class CartPage extends StatelessWidget {
  /// Tipo de comida seleccionada
  final String mealType;

  /// Número de mesa
  final int tableNumber;

  const CartPage({
    super.key,
    required this.mealType,
    required this.tableNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ════════════════════════════════════
      // APP BAR
      // ════════════════════════════════════
      appBar: AppBar(
        title: Text('Mi pedido - Mesa $tableNumber'),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      // ════════════════════════════════════
      // BODY
      // ════════════════════════════════════
      body: SafeArea(
        child: BlocBuilder<CartBloc, CartState>(
          builder: (context, state) {
            if (state is CartLoaded) {
              final items = state.items;

              return Column(
                children: [
                  // ════════════════════════════════════
                  // LISTA DE ITEMS
                  // ════════════════════════════════════
                  Expanded(
                    child: items.isEmpty
                        ? Center(
                            child: Text(
                              'Tu carrito está vacío',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          )
                        : SingleChildScrollView(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              children: items.map((item) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16.0),
                                  child: _buildCartItemCard(context, item),
                                );
                              }).toList(),
                            ),
                          ),
                  ),
                  // ════════════════════════════════════
                  // RESUMEN Y BOTONES
                  // ════════════════════════════════════
                  Container(
                    padding: const EdgeInsets.all(24.0),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadow,
                          blurRadius: 10,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ════════════════════════════════════
                        // DESGLOSE DE PRECIOS
                        // ════════════════════════════════════
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Subtotal',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            Text(
                              'S/.${state.subtotal.toStringAsFixed(2)}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Descuento (placeholder)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Descuento',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            Text(
                              '-S/. 0.00',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: AppColors.success),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Línea divisoria
                        Divider(color: AppColors.border, thickness: 1),
                        const SizedBox(height: 16),
                        // ════════════════════════════════════
                        // TOTAL
                        // ════════════════════════════════════
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                            ),
                            Text(
                              'S/. ${state.total.toStringAsFixed(2)}',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // ════════════════════════════════════
                        // BOTONES: CONFIRMAR PEDIDO Y LIBERAR MESA
                        // ════════════════════════════════════
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Botón enviar a cocina
                            ElevatedButton(
                              onPressed: () async {
                                if (state.totalItems > 0) {
                                  try {
                                    // Buscar si existe orden pendiente en esta mesa hoy
                                    final lastOrder =
                                        await ApiService.getLastPendingOrder(
                                          tableNumber,
                                        );

                                    List<Map<String, dynamic>> itemsToSend = [];

                                    if (lastOrder != null) {
                                      // Existe orden → Enviar TODOS los items actuales
                                      // (el backend se encargará de no duplicar)
                                      print(
                                        'Orden existente encontrada: ${lastOrder['id']}',
                                      );

                                      itemsToSend = state.items
                                          .map(
                                            (item) => {
                                              'productId': item.product.id,
                                              'quantity': item.quantity,
                                              'unitPrice': item.product.price,
                                            },
                                          )
                                          .toList();

                                      // Actualizar total de la orden
                                      await ApiService.updateOrderTotal(
                                        lastOrder['id'],
                                        state.total,
                                      );

                                      await ApiService.addItemToExistingOrder(
                                        lastOrder['id'],
                                        itemsToSend,
                                      );

                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Items agregados a la orden existente',
                                          ),
                                          backgroundColor: AppColors.success,
                                        ),
                                      );
                                    } else {
                                      // No existe orden → Crear nueva
                                      print('Creando nueva orden');

                                      final orderData = {
                                        'tableNumber': tableNumber,
                                        'mealType': mealType,
                                        'items': state.items
                                            .map(
                                              (item) => {
                                                'productId': item.product.id,
                                                'quantity': item.quantity,
                                                'unitPrice': item.product.price,
                                              },
                                            )
                                            .toList(),
                                        'total': state.total,
                                        'status': 'Enviado a cocina',
                                      };

                                      await ApiService.createOrder(orderData);

                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Pedido enviado a cocina',
                                          ),
                                          backgroundColor: AppColors.success,
                                        ),
                                      );
                                    }

                                    // Agregar ingreso al CashFlowBloc
                                    context.read<CashFlowBloc>().add(
                                      AddIncome(
                                        amount: state.total,
                                        description:
                                            'Venta - Mesa $tableNumber',
                                        tableNumber: tableNumber,
                                      ),
                                    );

                                    context.goToTables(mealType);
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Error: ${e.toString()}'),
                                        backgroundColor: AppColors.error,
                                      ),
                                    );
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.warning,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                              ),
                              child: Text(
                                'Enviar a cocina',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      color: AppColors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Botón Liberar Mesa
                            ElevatedButton(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (dialogContext) => AlertDialog(
                                    title: const Text('Liberar Mesa'),
                                    content: const Text(
                                      '¿Confirmas que los clientes terminaron de comer?',
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(dialogContext).pop(),
                                        child: const Text('Cancelar'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () {
                                          Navigator.of(dialogContext).pop();
                                          context.read<CartBloc>().add(
                                            LiberarMesa(
                                              mealType: mealType,
                                              tableNumber: tableNumber,
                                            ),
                                          );
                                          Navigator.of(context).pop();
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text('Mesa liberada'),
                                              backgroundColor:
                                                  AppColors.success,
                                            ),
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.error,
                                        ),
                                        child: const Text('Liberar Mesa'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                backgroundColor: AppColors.error,
                              ),
                              child: Text(
                                'Liberar Mesa',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      color: AppColors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }

  /// Widget para construir cada item del carrito
  Widget _buildCartItemCard(BuildContext context, CartItem item) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          // ════════════════════════════════════
          // IMAGEN
          // ════════════════════════════════════
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text('🍽️', style: TextStyle(fontSize: 32)),
            ),
          ),
          const SizedBox(width: 16),
          // ════════════════════════════════════
          // INFORMACIÓN
          // ════════════════════════════════════
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nombre
                Text(
                  item.product.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // Cantidad y precio unitario
                Text(
                  '${item.quantity}x S/. ${item.product.price.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // ════════════════════════════════════
          // TOTAL DEL ITEM
          // ════════════════════════════════════
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'S/. ${item.total.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
