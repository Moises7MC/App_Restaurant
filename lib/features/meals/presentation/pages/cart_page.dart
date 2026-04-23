import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  final int? activeOrderId;
  final Map<int, int> backendItemIds;

  const CartPage({
    super.key,
    required this.mealType,
    required this.tableNumber,
    this.itemsFromBackend = const {},
    this.activeOrderId,
    this.backendItemIds = const {},
  });

  Future<String> _getWaiterName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('WAITER_FULL_NAME') ?? 'Mozo';
  }

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
              return Column(
                children: [
                  Expanded(
                    child: state.items.isEmpty
                        ? Center(
                            child: Text(
                              'Tu carrito está vacío',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          )
                        : SingleChildScrollView(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              children: state.items
                                  .map(
                                    (item) => Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 16.0,
                                      ),
                                      child: _buildCartItemCard(context, item),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                  ),
                  _buildBottomBar(context, state),
                ],
              );
            }
            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, CartLoaded state) {
    return Container(
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
                'Total',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                'S/. ${state.total.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Enviar a cocina ──
          ElevatedButton(
            onPressed: () async {
              if (state.totalItems == 0) return;
              try {
                final waiterName = await _getWaiterName();
                final lastOrder = await ApiService.getLastPendingOrder(
                  tableNumber,
                );

                if (lastOrder != null) {
                  final itemsToSend = state.items
                      .where((item) {
                        final bQty = itemsFromBackend[item.product.id] ?? 0;
                        return item.quantity > bQty;
                      })
                      .map(
                        (item) => {
                          'productId': item.product.id,
                          'quantity':
                              item.quantity -
                              (itemsFromBackend[item.product.id] ?? 0),
                          'unitPrice': item.product.price,
                        },
                      )
                      .toList();

                  if (itemsToSend.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('No hay items nuevos para enviar'),
                        backgroundColor: AppColors.warning,
                      ),
                    );
                    return;
                  }
                  await ApiService.addItemToExistingOrder(
                    lastOrder['id'],
                    itemsToSend,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Items agregados a la orden'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                } else {
                  // Nueva orden — incluye waiterName
                  await ApiService.createOrder({
                    'tableNumber': tableNumber,
                    'mealType': mealType,
                    'waiterName': waiterName,
                    'entradas': state.entradas ?? '',
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
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Pedido enviado a cocina'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }

                context.read<CashFlowBloc>().add(
                  AddIncome(
                    amount: state.total,
                    description: 'Venta - Mesa $tableNumber',
                    tableNumber: tableNumber,
                  ),
                );
                context.read<CartBloc>().add(LimpiarCarrito());
                context.goToTables(mealType);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: ${e.toString()}'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(
              'Enviar a cocina',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ── Liberar mesa ──
          ElevatedButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (dlg) => AlertDialog(
                  title: const Text('Liberar Mesa'),
                  content: const Text(
                    '¿Confirmas que los clientes terminaron?',
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(dlg).pop(),
                      child: const Text('Cancelar'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(dlg).pop();
                        context.read<CartBloc>().add(
                          LiberarMesa(
                            mealType: mealType,
                            tableNumber: tableNumber,
                          ),
                        );
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Mesa liberada'),
                            backgroundColor: AppColors.success,
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
              backgroundColor: AppColors.error,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(
              'Liberar Mesa',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItemCard(BuildContext context, CartItem item) {
    final isFromBackend = itemsFromBackend.containsKey(item.product.id);
    final backendItemId = backendItemIds[item.product.id];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
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
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${item.quantity}x S/. ${item.product.price.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'S/. ${item.total.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),

          if (isFromBackend &&
              activeOrderId != null &&
              backendItemId != null) ...[
            const SizedBox(height: 12),
            Divider(color: AppColors.border, thickness: 0.5),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Ya enviado a cocina',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const Spacer(),
                _actionBtn(
                  context,
                  'Editar',
                  Icons.edit,
                  AppColors.primary,
                  () => _showEditQuantityDialog(
                    context,
                    item,
                    activeOrderId!,
                    backendItemId,
                  ),
                ),
                const SizedBox(width: 8),
                _actionBtn(
                  context,
                  'Eliminar',
                  Icons.delete_outline,
                  AppColors.error,
                  () => _confirmDeleteItem(
                    context,
                    item,
                    activeOrderId!,
                    backendItemId,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _actionBtn(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditQuantityDialog(
    BuildContext context,
    CartItem item,
    int orderId,
    int itemId,
  ) {
    int newQty = item.quantity;
    showDialog(
      context: context,
      builder: (dlg) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text('Editar: ${item.product.name}'),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () {
                  if (newQty > 1) setState(() => newQty--);
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: newQty > 1 ? AppColors.primary : AppColors.border,
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dlg).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: newQty == item.quantity
                  ? null
                  : () async {
                      Navigator.of(dlg).pop();
                      try {
                        await ApiService.updateItemQuantity(
                          orderId,
                          itemId,
                          newQty,
                        );
                        final diff = newQty - item.quantity;
                        if (diff > 0) {
                          for (int i = 0; i < diff; i++) {
                            context.read<CartBloc>().add(
                              AddToCart(item.product),
                            );
                          }
                        } else if (diff < 0) {
                          for (int i = 0; i < diff.abs(); i++) {
                            context.read<CartBloc>().add(
                              RemoveFromCart(item.product.id),
                            );
                          }
                        }
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

  void _confirmDeleteItem(
    BuildContext context,
    CartItem item,
    int orderId,
    int itemId,
  ) {
    showDialog(
      context: context,
      builder: (dlg) => AlertDialog(
        title: const Text('Eliminar plato'),
        content: Text('¿Eliminar "${item.product.name}"?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dlg).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dlg).pop();
              try {
                await ApiService.removeItemFromOrder(orderId, itemId);
                for (int i = 0; i < item.quantity; i++) {
                  context.read<CartBloc>().add(RemoveFromCart(item.product.id));
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Plato eliminado'),
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
