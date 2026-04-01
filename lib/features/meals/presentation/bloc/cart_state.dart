import 'package:equatable/equatable.dart';
import '../../domain/entities/cart_item.dart';

abstract class CartState extends Equatable {
  const CartState();

  @override
  List<Object?> get props => [];
}

class CartEmpty extends CartState {
  @override
  String toString() => 'CartEmpty()';
}

class CartLoaded extends CartState {
  final List<CartItem> items;

  const CartLoaded(this.items);

  double get subtotal => items.fold(0, (sum, item) => sum + item.total);

  double get total => subtotal;

  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);

  @override
  List<Object?> get props => [items];

  @override
  String toString() =>
      'CartLoaded(items: ${items.length}, total: \$${total.toStringAsFixed(2)})';
}

class CartError extends CartState {
  final String message;

  const CartError(this.message);

  @override
  List<Object?> get props => [message];

  @override
  String toString() => 'CartError(message: $message)';
}
