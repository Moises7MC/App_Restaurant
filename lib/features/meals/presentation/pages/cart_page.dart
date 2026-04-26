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

class CartPage extends StatefulWidget {
  final String mealType;
  final int tableNumber;
  final Map<int, int> itemsFromBackend;
  final int? activeOrderId;
  final Map<int, int> backendItemIds;
  final bool isParaLlevar;

  const CartPage({
    super.key,
    required this.mealType,
    required this.tableNumber,
    this.itemsFromBackend = const {},
    this.activeOrderId,
    this.backendItemIds = const {},
    this.isParaLlevar = false,
  });

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  // ✅ Copias mutables de los datos del backend.
  //    Se inicializan con lo que viene de ProductsPage y se actualizan
  //    cuando el mozo edita/elimina items ya enviados a cocina.
  late Map<int, int> _itemsFromBackend;
  late Map<int, int> _backendItemIds;

  @override
  void initState() {
    super.initState();
    _itemsFromBackend = Map<int, int>.from(widget.itemsFromBackend);
    _backendItemIds = Map<int, int>.from(widget.backendItemIds);
  }

  Future<String> _getWaiterName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('WAITER_FULL_NAME') ?? 'Mozo';
  }

  // ✅ Calcula si hay items realmente nuevos respecto a lo enviado al backend.
  //    - Sin orden activa → cualquier item del carrito es "nuevo".
  //    - Con orden activa → comparar contra _itemsFromBackend (que ya está sincronizado).
  bool _hasNewItems(CartLoaded state) {
    if (widget.activeOrderId == null) {
      return state.items.isNotEmpty;
    }
    for (final item in state.items) {
      final bQty = _itemsFromBackend[item.product.id] ?? 0;
      if (item.quantity > bQty) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isParaLlevar
              ? 'Para llevar — Mesa ${widget.tableNumber}'
              : 'Mi pedido - Mesa ${widget.tableNumber}',
        ),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.goToTables(widget.mealType);
            }
          },
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
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.shopping_bag_outlined,
                                  size: 64,
                                  color: Colors.grey.shade300,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Carrito vacío',
                                  style: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.isParaLlevar
                                      ? 'Agrega productos para llevar'
                                      : 'Agrega productos al carrito',
                                  style: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
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
    final hasNewItems = _hasNewItems(state);

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

          // ── Enviar a cocina / Para llevar ──
          ElevatedButton(
            onPressed: !hasNewItems
                ? null
                : () async {
                    if (state.totalItems == 0) return;

                    final cartBloc = context.read<CartBloc>();
                    final cashFlowBloc = context.read<CashFlowBloc>();
                    final navigator = Navigator.of(context);
                    final messenger = ScaffoldMessenger.of(context);
                    final totalSnapshot = state.total;

                    try {
                      final waiterName = await _getWaiterName();

                      final lastOrder = await ApiService.getLastPendingOrder(
                        widget.tableNumber,
                        isParaLlevar: widget.isParaLlevar,
                      );

                      if (lastOrder != null) {
                        final itemsToSend = state.items
                            .where((item) {
                              final bQty =
                                  _itemsFromBackend[item.product.id] ?? 0;
                              return item.quantity > bQty;
                            })
                            .map(
                              (item) => {
                                'productId': item.product.id,
                                'quantity':
                                    item.quantity -
                                    (_itemsFromBackend[item.product.id] ?? 0),
                                'unitPrice': item.product.price,
                              },
                            )
                            .toList();

                        if (itemsToSend.isEmpty) {
                          messenger.showSnackBar(
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
                      } else {
                        await ApiService.createOrder({
                          'tableNumber': widget.tableNumber,
                          'mealType': widget.mealType,
                          'waiterName': waiterName,
                          'isParaLlevar': widget.isParaLlevar,
                          'entradas':
                              (state.entradas != null &&
                                  state.entradas!.trim().isNotEmpty)
                              ? state.entradas
                              : null,
                          'items': state.items
                              .map(
                                (item) => {
                                  'productId': item.product.id,
                                  'quantity': item.quantity,
                                  'unitPrice': item.product.price,
                                },
                              )
                              .toList(),
                          'total': totalSnapshot,
                          'status': 'Enviado a cocina',
                        });
                      }

                      cashFlowBloc.add(
                        AddIncome(
                          amount: totalSnapshot,
                          description: widget.isParaLlevar
                              ? 'Para llevar - Mesa ${widget.tableNumber}'
                              : 'Venta - Mesa ${widget.tableNumber}',
                          tableNumber: widget.tableNumber,
                        ),
                      );

                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            widget.isParaLlevar
                                ? '✓ Pedido para llevar enviado a cocina'
                                : '✓ Pedido enviado a cocina',
                          ),
                          backgroundColor: AppColors.success,
                          duration: const Duration(seconds: 2),
                        ),
                      );

                      cartBloc.add(LimpiarCarrito());
                      navigator.pop();
                    } catch (e) {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text('Error: ${e.toString()}'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: !hasNewItems
                  ? Colors.grey.shade400
                  : (widget.isParaLlevar
                        ? const Color(0xFF7c3aed)
                        : AppColors.warning),
              disabledBackgroundColor: Colors.grey.shade300,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(
              !hasNewItems
                  ? 'Sin cambios para enviar'
                  : (widget.isParaLlevar
                        ? '🛍 Enviar para llevar'
                        : 'Enviar a cocina'),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: !hasNewItems ? Colors.grey.shade600 : AppColors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          if (!widget.isParaLlevar) ...[
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
                              mealType: widget.mealType,
                              tableNumber: widget.tableNumber,
                            ),
                          );
                          context.goToTables(widget.mealType);
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
        ],
      ),
    );
  }

  Widget _buildCartItemCard(BuildContext context, CartItem item) {
    final isFromBackend = _itemsFromBackend.containsKey(item.product.id);
    final backendItemId = _backendItemIds[item.product.id];

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
          // Mostrar opciones de Editar/Eliminar para items ya enviados
          if (isFromBackend &&
              widget.activeOrderId != null &&
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
                    widget.activeOrderId!,
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
                    widget.activeOrderId!,
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
        builder: (ctx, setStateDialog) => AlertDialog(
          title: Text('Editar: ${item.product.name}'),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () {
                  if (newQty > 1) setStateDialog(() => newQty--);
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
                onTap: () => setStateDialog(() => newQty++),
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
                      final cartBloc = context.read<CartBloc>();
                      final messenger = ScaffoldMessenger.of(context);
                      try {
                        await ApiService.updateItemQuantity(
                          orderId,
                          itemId,
                          newQty,
                        );
                        final diff = newQty - item.quantity;
                        if (diff > 0) {
                          for (int i = 0; i < diff; i++) {
                            cartBloc.add(AddToCart(item.product));
                          }
                        } else if (diff < 0) {
                          for (int i = 0; i < diff.abs(); i++) {
                            cartBloc.add(RemoveFromCart(item.product.id));
                          }
                        }
                        // ✅ Sincronizar el mapa local con la nueva cantidad
                        //    para que el botón "Enviar" se mantenga deshabilitado.
                        if (mounted) {
                          setState(() {
                            _itemsFromBackend[item.product.id] = newQty;
                          });
                        }
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Cantidad actualizada'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      } catch (e) {
                        messenger.showSnackBar(
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
              final cartBloc = context.read<CartBloc>();
              final messenger = ScaffoldMessenger.of(context);
              try {
                await ApiService.removeItemFromOrder(orderId, itemId);
                for (int i = 0; i < item.quantity; i++) {
                  cartBloc.add(RemoveFromCart(item.product.id));
                }
                // ✅ Quitar el item de los mapas locales
                if (mounted) {
                  setState(() {
                    _itemsFromBackend.remove(item.product.id);
                    _backendItemIds.remove(item.product.id);
                  });
                }
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Plato eliminado'),
                    backgroundColor: AppColors.success,
                  ),
                );
              } catch (e) {
                messenger.showSnackBar(
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
