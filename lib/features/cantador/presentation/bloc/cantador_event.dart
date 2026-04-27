import 'package:equatable/equatable.dart';

abstract class CantadorEvent extends Equatable {
  const CantadorEvent();
  @override
  List<Object?> get props => [];
}

/// Cargar todos los datos (vista agregada + órdenes activas + historial)
class LoadCantadorData extends CantadorEvent {
  const LoadCantadorData();
}

/// Refrescar — se dispara desde SignalR cuando llega un evento del backend
class RefreshCantadorData extends CantadorEvent {
  const RefreshCantadorData();
}

/// Descontar 1 plato del agregado (FIFO)
class ServeDishEvent extends CantadorEvent {
  final int productId;
  const ServeDishEvent(this.productId);
  @override
  List<Object?> get props => [productId];
}

/// Descontar 1 unidad de un OrderItem específico (tab POR MESA)
class ServeOrderItemEvent extends CantadorEvent {
  final int orderItemId;
  const ServeOrderItemEvent(this.orderItemId);
  @override
  List<Object?> get props => [orderItemId];
}

/// Marcar una orden como cantada al chef
class MarkAsSungEvent extends CantadorEvent {
  final int orderId;
  const MarkAsSungEvent(this.orderId);
  @override
  List<Object?> get props => [orderId];
}

/// Tachar/destachar una entrada localmente (no persiste en BD)
class ToggleEntradaServidaEvent extends CantadorEvent {
  final String entradaName;
  const ToggleEntradaServidaEvent(this.entradaName);
  @override
  List<Object?> get props => [entradaName];
}
