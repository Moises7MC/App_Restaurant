import 'package:equatable/equatable.dart';
import '../../domain/entities/product.dart';

abstract class CartEvent extends Equatable {
  const CartEvent();

  @override
  List<Object?> get props => [];
}

class AddToCart extends CartEvent {
  final Product product;
  const AddToCart(this.product);
  @override
  List<Object?> get props => [product];
  @override
  String toString() => 'AddToCart(product: ${product.name})';
}

class RemoveFromCart extends CartEvent {
  final int productId;
  const RemoveFromCart(this.productId);
  @override
  List<Object?> get props => [productId];
  @override
  String toString() => 'RemoveFromCart(productId: $productId)';
}

class UpdateQuantity extends CartEvent {
  final String productId;
  final int quantity;
  const UpdateQuantity({required this.productId, required this.quantity});
  @override
  List<Object?> get props => [productId, quantity];
  @override
  String toString() =>
      'UpdateQuantity(productId: $productId, quantity: $quantity)';
}

class ClearCart extends CartEvent {
  const ClearCart();
  @override
  String toString() => 'ClearCart()';
}

class SelectTable extends CartEvent {
  final String mealType;
  final int tableNumber;
  const SelectTable({required this.mealType, required this.tableNumber});
  @override
  List<Object?> get props => [mealType, tableNumber];
  @override
  String toString() =>
      'SelectTable(mealType: $mealType, tableNumber: $tableNumber)';
}

class LiberarMesa extends CartEvent {
  final String mealType;
  final int tableNumber;
  const LiberarMesa({required this.mealType, required this.tableNumber});
  @override
  List<Object?> get props => [mealType, tableNumber];
  @override
  String toString() =>
      'LiberarMesa(mealType: $mealType, tableNumber: $tableNumber)';
}

class LimpiarCarrito extends CartEvent {
  const LimpiarCarrito();
}

// ✅ NUEVO: guardar texto de entradas seleccionadas
class SetEntradas extends CartEvent {
  final String entradas;
  const SetEntradas(this.entradas);
  @override
  List<Object?> get props => [entradas];
  @override
  String toString() => 'SetEntradas($entradas)';
}
