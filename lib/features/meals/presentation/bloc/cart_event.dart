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
  final String productId;

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

/// Evento: Seleccionar una mesa
///
/// Se dispara cuando el usuario llega a ProductsPage
/// para cargar el carrito específico de esa mesa
class SelectTable extends CartEvent {
  /// Tipo de comida (Almuerzo, Desayuno, Cena)
  final String mealType;

  /// Número de mesa
  final int tableNumber;

  const SelectTable({required this.mealType, required this.tableNumber});

  @override
  List<Object?> get props => [mealType, tableNumber];

  @override
  String toString() =>
      'SelectTable(mealType: $mealType, tableNumber: $tableNumber)';
}

/// Evento: Liberar una mesa
///
/// Se ejecuta cuando el usuario confirma que termina de usar la mesa
/// Limpia el carrito de esa mesa específica
class LiberarMesa extends CartEvent {
  /// Tipo de comida (Almuerzo, Desayuno, Cena)
  final String mealType;

  /// Número de mesa
  final int tableNumber;

  const LiberarMesa({required this.mealType, required this.tableNumber});

  @override
  List<Object?> get props => [mealType, tableNumber];

  @override
  String toString() =>
      'LiberarMesa(mealType: $mealType, tableNumber: $tableNumber)';
}
