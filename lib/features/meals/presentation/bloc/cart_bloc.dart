import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/cart_item.dart';
import 'cart_event.dart';
import 'cart_state.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  final Map<String, List<CartItem>> _cartsByTable = {};
  final Map<String, String?> _entradasByTable = {}; // ✅ NUEVO
  String _currentTableKey = '';

  CartBloc() : super(CartEmpty()) {
    on<AddToCart>(_onAddToCart);
    on<RemoveFromCart>(_onRemoveFromCart);
    on<UpdateQuantity>(_onUpdateQuantity);
    on<ClearCart>(_onClearCart);
    on<SelectTable>(_onSelectTable);
    on<LiberarMesa>(_onLiberarMesa);
    on<LimpiarCarrito>(_onLimpiarCarrito);
    on<SetEntradas>(_onSetEntradas); // ✅ NUEVO
  }

  String _getTableKey(String mealType, int tableNumber) =>
      '${mealType}_$tableNumber';

  List<CartItem> _getCurrentItems() => _cartsByTable[_currentTableKey] ?? [];

  String? _getCurrentEntradas() => _entradasByTable[_currentTableKey];

  // ✅ Emitir estado con entradas incluidas
  void _emitLoaded(Emitter<CartState> emit) {
    final items = _getCurrentItems();
    final entradas = _getCurrentEntradas();
    print('📦 _emitLoaded - key: "$_currentTableKey" - entradas: "$entradas"');
    // ← Siempre CartLoaded, nunca CartEmpty desde aquí
    emit(CartLoaded(List.from(items), entradas: entradas));
  }

  Future<void> _onSelectTable(
    SelectTable event,
    Emitter<CartState> emit,
  ) async {
    try {
      _currentTableKey = _getTableKey(event.mealType, event.tableNumber);
      _emitLoaded(emit);
    } catch (e) {
      emit(CartError('Error al seleccionar mesa: $e'));
    }
  }

  // ✅ NUEVO: guardar entradas para la mesa actual
  Future<void> _onSetEntradas(
    SetEntradas event,
    Emitter<CartState> emit,
  ) async {
    print(
      '💾 SetEntradas - key: "$_currentTableKey" - valor: "${event.entradas}"',
    );
    _entradasByTable[_currentTableKey] = event.entradas;
    _emitLoaded(emit);
  }

  Future<void> _onAddToCart(AddToCart event, Emitter<CartState> emit) async {
    try {
      final items = _getCurrentItems();
      final index = items.indexWhere((i) => i.product.id == event.product.id);
      if (index >= 0) {
        final cur = items[index];
        items[index] = CartItem(
          product: cur.product,
          quantity: cur.quantity + 1,
        );
      } else {
        items.add(CartItem(product: event.product, quantity: 1));
      }
      _cartsByTable[_currentTableKey] = items;
      _emitLoaded(emit);
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
      final index = items.indexWhere((i) => i.product.id == event.productId);
      if (index >= 0) {
        final cur = items[index];
        if (cur.quantity > 1) {
          items[index] = CartItem(
            product: cur.product,
            quantity: cur.quantity - 1,
          );
        } else {
          items.removeAt(index);
        }
        _cartsByTable[_currentTableKey] = items;
        _emitLoaded(emit);
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
      final index = items.indexWhere((i) => i.product.id == event.productId);
      if (index >= 0) {
        if (event.quantity > 0) {
          final cur = items[index];
          items[index] = CartItem(
            product: cur.product,
            quantity: event.quantity,
          );
        } else {
          items.removeAt(index);
        }
        _cartsByTable[_currentTableKey] = items;
        _emitLoaded(emit);
      }
    } catch (e) {
      emit(CartError('Error al actualizar cantidad: $e'));
    }
  }

  Future<void> _onClearCart(ClearCart event, Emitter<CartState> emit) async {
    _cartsByTable.clear();
    _entradasByTable.clear();
    _currentTableKey = '';
    emit(CartEmpty());
  }

  Future<void> _onLiberarMesa(
    LiberarMesa event,
    Emitter<CartState> emit,
  ) async {
    try {
      final tableKey = _getTableKey(event.mealType, event.tableNumber);
      _cartsByTable.remove(tableKey);
      _entradasByTable.remove(tableKey); // ✅
      if (_currentTableKey == tableKey) {
        _currentTableKey = '';
        emit(CartEmpty());
      }
    } catch (e) {
      emit(CartError('Error al liberar mesa: $e'));
    }
  }

  Future<void> _onLimpiarCarrito(
    LimpiarCarrito event,
    Emitter<CartState> emit,
  ) async {
    try {
      _cartsByTable[_currentTableKey] = [];
      // _entradasByTable.remove(_currentTableKey); // ✅
      // emit(CartEmpty());
      emit(CartLoaded([], entradas: null));
    } catch (e) {
      emit(CartError('Error al limpiar carrito: $e'));
    }
  }

  List<CartItem> get items => List.from(_getCurrentItems());

  CartLoaded? get currentCart {
    final items = _getCurrentItems();
    if (items.isEmpty) return null;
    return CartLoaded(List.from(items), entradas: _getCurrentEntradas());
  }

  bool isTableOccupied(String mealType, int tableNumber) {
    final tableKey = _getTableKey(mealType, tableNumber);
    return (_cartsByTable[tableKey] ?? []).isNotEmpty;
  }

  int getTableItemCount(String mealType, int tableNumber) {
    final tableKey = _getTableKey(mealType, tableNumber);
    return (_cartsByTable[tableKey] ?? []).fold(
      0,
      (sum, i) => sum + i.quantity,
    );
  }
}
