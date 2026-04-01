import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../meals/domain/entities/cart_item.dart';

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

  /// Items en el carrito
  final List<CartItem> cartItems;

  const CartPage({
    super.key,
    required this.mealType,
    required this.tableNumber,
    required this.cartItems,
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
        child: Column(
          children: [
            // ════════════════════════════════════
            // LISTA DE ITEMS
            // ════════════════════════════════════
            Expanded(
              child: cartItems.isEmpty
                  ? Center(
                      child: Text(
                        'Tu carrito está vacío',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: cartItems.map((item) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: _buildCartItemCard(context, item),
                          );
                        }).toList(),
                      ),
                    ),
            ),

            // ════════════════════════════════════
            // RESUMEN Y BOTÓN CONFIRMAR
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
                        '\$${_calculateSubtotal().toStringAsFixed(2)}',
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
                        '-\$0.00',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.success,
                        ),
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
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '\$${_calculateTotal().toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ════════════════════════════════════
                  // BOTÓN CONFIRMAR PEDIDO
                  // ════════════════════════════════════
                  ElevatedButton(
                    onPressed: cartItems.isEmpty
                        ? null
                        : () {
                            // TODO: Navegar a CheckoutPage o mostrar confirmación
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Pedido confirmado: \$${_calculateTotal().toStringAsFixed(2)}',
                                ),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: cartItems.isEmpty
                          ? AppColors.border
                          : AppColors.primary,
                    ),
                    child: Text(
                      'Confirmar Pedido',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
              color: AppColors.primaryLight.withOpacity(0.2),
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
                  '${item.quantity}x \$${item.product.price.toStringAsFixed(2)}',
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
                '\$${item.total.toStringAsFixed(2)}',
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

  /// Calcula el subtotal
  double _calculateSubtotal() {
    return cartItems.fold(0, (sum, item) => sum + item.total);
  }

  /// Calcula el total (por ahora igual al subtotal)
  double _calculateTotal() {
    return _calculateSubtotal();
  }
}
