import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/cart_item.dart';
import 'cart_event.dart';
import 'cart_state.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  /// Mapa de carritos por mesa: mealType_tableNumber -> items
  /// Ejemplo: "Almuerzo_3" -> [CartItem, CartItem, ...]
  final Map<String, List<CartItem>> _cartsByTable = {};

  /// Mesa actual (para saber cuál carrito estamos usando)
  String _currentTableKey = '';

  CartBloc() : super(CartEmpty()) {
    on<AddToCart>(_onAddToCart);
    on<RemoveFromCart>(_onRemoveFromCart);
    on<UpdateQuantity>(_onUpdateQuantity);
    on<ClearCart>(_onClearCart);
    on<SelectTable>(_onSelectTable);
    on<LiberarMesa>(_onLiberarMesa);
  }

  /// Genera la clave única para una mesa
  /// Ejemplo: "Almuerzo_3"
  String _getTableKey(String mealType, int tableNumber) {
    return '${mealType}_$tableNumber';
  }

  /// Obtiene los items del carrito actual
  List<CartItem> _getCurrentItems() {
    return _cartsByTable[_currentTableKey] ?? [];
  }

  /// Maneja el evento SelectTable
  /// Se ejecuta cuando cambias de mesa
  Future<void> _onSelectTable(
    SelectTable event,
    Emitter<CartState> emit,
  ) async {
    try {
      _currentTableKey = _getTableKey(event.mealType, event.tableNumber);

      final items = _cartsByTable[_currentTableKey] ?? [];

      if (items.isEmpty) {
        emit(CartEmpty());
      } else {
        emit(CartLoaded(List.from(items)));
      }
    } catch (e) {
      emit(CartError('Error al seleccionar mesa: $e'));
    }
  }

  Future<void> _onAddToCart(AddToCart event, Emitter<CartState> emit) async {
    try {
      final items = _getCurrentItems();
      final index = items.indexWhere(
        (item) => item.product.id == event.product.id,
      );

      if (index >= 0) {
        final itemActual = items[index];
        items[index] = CartItem(
          product: itemActual.product,
          quantity: itemActual.quantity + 1,
        );
      } else {
        items.add(CartItem(product: event.product, quantity: 1));
      }

      _cartsByTable[_currentTableKey] = items;
      emit(CartLoaded(List.from(items)));
    } catch (e) {
      emit(CartError('Error al agregar al carrito: $e'));
    }
  }

  Future<void> _onRemoveFromCart(
    RemoveFromCart event,
    Emitter<CartState> emit,
  ) async {
    try {
      final items = _getCurrentItems();
      final index = items.indexWhere(
        (item) => item.product.id == event.productId,
      );

      if (index >= 0) {
        final itemActual = items[index];

        if (itemActual.quantity > 1) {
          items[index] = CartItem(
            product: itemActual.product,
            quantity: itemActual.quantity - 1,
          );
        } else {
          items.removeAt(index);
        }

        _cartsByTable[_currentTableKey] = items;

        if (items.isEmpty) {
          emit(CartEmpty());
        } else {
          emit(CartLoaded(List.from(items)));
        }
      }
    } catch (e) {
      emit(CartError('Error al quitar del carrito: $e'));
    }
  }

  Future<void> _onUpdateQuantity(
    UpdateQuantity event,
    Emitter<CartState> emit,
  ) async {
    try {
      final items = _getCurrentItems();
      final index = items.indexWhere(
        (item) => item.product.id == event.productId,
      );

      if (index >= 0) {
        if (event.quantity > 0) {
          final itemActual = items[index];
          items[index] = CartItem(
            product: itemActual.product,
            quantity: event.quantity,
          );
          _cartsByTable[_currentTableKey] = items;
          emit(CartLoaded(List.from(items)));
        } else {
          items.removeAt(index);
          _cartsByTable[_currentTableKey] = items;

          if (items.isEmpty) {
            emit(CartEmpty());
          } else {
            emit(CartLoaded(List.from(items)));
          }
        }
      }
    } catch (e) {
      emit(CartError('Error al actualizar cantidad: $e'));
    }
  }

  Future<void> _onClearCart(ClearCart event, Emitter<CartState> emit) async {
    try {
      _cartsByTable.clear();
      _currentTableKey = '';
      emit(CartEmpty());
    } catch (e) {
      emit(CartError('Error al limpiar carrito: $e'));
    }
  }

  List<CartItem> get items => List.from(_getCurrentItems());

  CartLoaded? get currentCart {
    final items = _getCurrentItems();
    if (items.isEmpty) return null;
    return CartLoaded(List.from(items));
  }

  /// Verifica si una mesa específica tiene items en el carrito
  ///
  /// Retorna true si la mesa está ocupada (tiene items)
  /// Retorna false si la mesa está libre (sin items)
  bool isTableOccupied(String mealType, int tableNumber) {
    final tableKey = _getTableKey(mealType, tableNumber);
    final items = _cartsByTable[tableKey] ?? [];
    return items.isNotEmpty;
  }

  /// Obtiene la cantidad de items en una mesa específica
  int getTableItemCount(String mealType, int tableNumber) {
    final tableKey = _getTableKey(mealType, tableNumber);
    final items = _cartsByTable[tableKey] ?? [];
    return items.fold(0, (sum, item) => sum + item.quantity);
  }

  /// Maneja el evento LiberarMesa
  ///
  /// Limpia el carrito de la mesa específica
  Future<void> _onLiberarMesa(
    LiberarMesa event,
    Emitter<CartState> emit,
  ) async {
    try {
      final tableKey = _getTableKey(event.mealType, event.tableNumber);
      _cartsByTable.remove(tableKey);

      // Si era la mesa actual, limpiar el estado
      if (_currentTableKey == tableKey) {
        _currentTableKey = '';
        emit(CartEmpty());
      }
    } catch (e) {
      emit(CartError('Error al liberar mesa: $e'));
    }
  }
}
