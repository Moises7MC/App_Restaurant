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

class CartPage extends StatelessWidget {
  final String mealType;
  final int tableNumber;
  final Map<int, int> itemsFromBackend;

  // ID de la orden activa (si ya existe una en el backend)
  // Si es null, aún no se ha enviado nada a cocina
  final int? activeOrderId;

  // Items del backend con su itemId real (productId -> itemId)
  final Map<int, int> backendItemIds;

  const CartPage({
    super.key,
    required this.mealType,
    required this.tableNumber,
    this.itemsFromBackend = const {},
    this.activeOrderId,
    this.backendItemIds = const {},
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mi pedido - Mesa $tableNumber'),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: BlocBuilder<CartBloc, CartState>(
          builder: (context, state) {
            if (state is CartLoaded) {
              final items = state.items;

              return Column(
                children: [
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

                  // RESUMEN Y BOTONES
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
                        Divider(color: AppColors.border, thickness: 1),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
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
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ElevatedButton(
                              onPressed: () async {
                                if (state.totalItems > 0) {
                                  try {
                                    final lastOrder =
                                        await ApiService.getLastPendingOrder(
                                          tableNumber,
                                        );

                                    if (lastOrder != null) {
                                      // Enviar solo items nuevos
                                      final itemsToSend = state.items
                                          .where((item) {
                                            final backendQty =
                                                itemsFromBackend[item
                                                    .product
                                                    .id] ??
                                                0;
                                            return item.quantity > backendQty;
                                          })
                                          .map((item) {
                                            final backendQty =
                                                itemsFromBackend[item
                                                    .product
                                                    .id] ??
                                                0;
                                            return {
                                              'productId': item.product.id,
                                              'quantity':
                                                  item.quantity - backendQty,
                                              'unitPrice': item.product.price,
                                            };
                                          })
                                          .toList();

                                      if (itemsToSend.isEmpty) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'No hay items nuevos para enviar',
                                            ),
                                            backgroundColor: AppColors.warning,
                                          ),
                                        );
                                        return;
                                      }

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
                                      context.read<CartBloc>().add(
                                        LimpiarCarrito(),
                                      );
                                    } else {
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
                                      context.read<CartBloc>().add(
                                        LimpiarCarrito(),
                                      );
                                    }

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

  Widget _buildCartItemCard(BuildContext context, CartItem item) {
    // ¿Este item ya fue enviado al backend?
    final isFromBackend = itemsFromBackend.containsKey(item.product.id);
    final backendItemId = backendItemIds[item.product.id];

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
      child: Column(
        children: [
          Row(
            children: [
              // Imagen / ícono
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
              Text(
                'S/. ${item.total.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),

          // ─────────────────────────────────────────────
          // Botones de editar/eliminar SOLO si ya fue
          // enviado al backend (tiene orderId activo)
          // ─────────────────────────────────────────────
          if (isFromBackend &&
              activeOrderId != null &&
              backendItemId != null) ...[
            const SizedBox(height: 12),
            Divider(color: AppColors.border, thickness: 0.5),
            const SizedBox(height: 8),
            Row(
              children: [
                // Texto indicativo
                Text(
                  'Ya enviado a cocina',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const Spacer(),

                // Botón editar cantidad
                GestureDetector(
                  onTap: () => _showEditQuantityDialog(
                    context,
                    item,
                    activeOrderId!,
                    backendItemId,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit, size: 14, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          'Editar',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Botón eliminar
                GestureDetector(
                  onTap: () => _confirmDeleteItem(
                    context,
                    item,
                    activeOrderId!,
                    backendItemId,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.delete_outline,
                          size: 14,
                          color: AppColors.error,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Eliminar',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppColors.error,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // Dialog para editar la cantidad
  void _showEditQuantityDialog(
    BuildContext context,
    CartItem item,
    int orderId,
    int itemId,
  ) {
    int newQty = item.quantity;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text('Editar: ${item.product.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Cantidad actual: ${item.quantity}',
                style: Theme.of(ctx).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Botón -
                  GestureDetector(
                    onTap: () {
                      if (newQty > 1) setState(() => newQty--);
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: newQty > 1
                            ? AppColors.primary
                            : AppColors.border,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.remove,
                        color: AppColors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Text(
                    '$newQty',
                    style: Theme.of(ctx).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 24),
                  // Botón +
                  GestureDetector(
                    onTap: () => setState(() => newQty++),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.add,
                        color: AppColors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Total: S/. ${(newQty * item.product.price).toStringAsFixed(2)}',
                style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: newQty == item.quantity
                  ? null
                  : () async {
                      Navigator.of(dialogContext).pop();
                      try {
                        await ApiService.updateItemQuantity(
                          orderId,
                          itemId,
                          newQty,
                        );
                        // Actualizar también el carrito local
                        context.read<CartBloc>().add(
                          UpdateQuantity(
                            productId: item.product.id.toString(),
                            quantity: newQty,
                          ),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Cantidad actualizada'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    },
              child: const Text('Confirmar'),
            ),
          ],
        ),
      ),
    );
  }

  // Confirmación para eliminar item
  void _confirmDeleteItem(
    BuildContext context,
    CartItem item,
    int orderId,
    int itemId,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar plato'),
        content: Text(
          '¿Eliminar "${item.product.name}" del pedido?\nEsto notificará a cocina.',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              try {
                await ApiService.removeItemFromOrder(orderId, itemId);
                // Quitar del carrito local también
                context.read<CartBloc>().add(RemoveFromCart(item.product.id));
                // Quitar varias veces hasta que quede en 0
                for (int i = 1; i < item.quantity; i++) {
                  context.read<CartBloc>().add(RemoveFromCart(item.product.id));
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Plato eliminado del pedido'),
                    backgroundColor: AppColors.success,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
