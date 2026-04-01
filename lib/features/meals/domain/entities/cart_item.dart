import 'package:equatable/equatable.dart';
import 'product.dart';

/// Entidad que representa un item en el carrito de compras
///
/// Contiene:
/// - El producto
/// - La cantidad seleccionada
/// - Cálculo automático del total (precio × cantidad)
class CartItem extends Equatable {
  /// Producto en el carrito
  final Product product;

  /// Cantidad seleccionada del producto
  final int quantity;

  /// Constructor
  const CartItem({required this.product, required this.quantity});

  /// Calcula el total para este item
  ///
  /// Total = precio del producto × cantidad
  double get total => product.price * quantity;

  /// Lista de propiedades para comparación (Equatable)
  @override
  List<Object?> get props => [product, quantity];

  /// Método toString para debugging
  @override
  String toString() {
    return 'CartItem(product: ${product.name}, quantity: $quantity, total: $total)';
  }

  /// Crea una copia del CartItem con algunos campos modificados
  ///
  /// Útil cuando necesitas cambiar la cantidad
  CartItem copyWith({Product? product, int? quantity}) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }
}
