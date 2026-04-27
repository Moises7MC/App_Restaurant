import 'package:equatable/equatable.dart';
import '../../domain/entities/cantador_aggregated_view.dart';
import '../../domain/entities/cantador_order.dart';

abstract class CantadorState extends Equatable {
  const CantadorState();
  @override
  List<Object?> get props => [];
}

/// Estado inicial — antes de cargar nada
class CantadorInitial extends CantadorState {
  const CantadorInitial();
}

/// Cargando datos por primera vez (mostrar spinner)
class CantadorLoading extends CantadorState {
  const CantadorLoading();
}

/// Datos cargados — se muestra normalmente
class CantadorLoaded extends CantadorState {
  final CantadorAggregatedView aggregated;
  final List<CantadorOrder> activeOrders;
  final List<CantadorOrder> history;

  /// Set de nombres de entradas que el cantador ya tachó visualmente
  /// (estado solo en memoria, no se persiste en BD)
  final Set<String> entradasServidasLocales;

  /// Indica si está refrescando en background (para mostrar indicador sutil)
  final bool isRefreshing;

  const CantadorLoaded({
    required this.aggregated,
    required this.activeOrders,
    required this.history,
    this.entradasServidasLocales = const {},
    this.isRefreshing = false,
  });

  CantadorLoaded copyWith({
    CantadorAggregatedView? aggregated,
    List<CantadorOrder>? activeOrders,
    List<CantadorOrder>? history,
    Set<String>? entradasServidasLocales,
    bool? isRefreshing,
  }) {
    return CantadorLoaded(
      aggregated: aggregated ?? this.aggregated,
      activeOrders: activeOrders ?? this.activeOrders,
      history: history ?? this.history,
      entradasServidasLocales:
          entradasServidasLocales ?? this.entradasServidasLocales,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  @override
  List<Object?> get props => [
    aggregated,
    activeOrders,
    history,
    entradasServidasLocales,
    isRefreshing,
  ];
}

/// Error al cargar datos
class CantadorError extends CantadorState {
  final String message;
  const CantadorError(this.message);
  @override
  List<Object?> get props => [message];
}
