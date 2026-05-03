import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../services/api_service.dart';
import '../../domain/entities/cantador_aggregated_view.dart';
import '../../domain/entities/cantador_order.dart';
import 'cantador_event.dart';
import 'cantador_state.dart';

/// BLoC del cantador.
///
/// Fuente de verdad:
/// - Backend (pendingQuantity)
/// - NO estado local para tachados
class CantadorBloc extends Bloc<CantadorEvent, CantadorState> {
  CantadorBloc() : super(const CantadorInitial()) {
    on<LoadCantadorData>(_onLoadCantadorData);
    on<RefreshCantadorData>(_onRefreshCantadorData);
    on<ServeDishEvent>(_onServeDish);
    on<ServeOrderItemEvent>(_onServeOrderItem);
    on<MarkAsSungEvent>(_onMarkAsSung);
  }

  // ─────────────────────────────────────────────
  // LOAD INICIAL
  // ─────────────────────────────────────────────
  Future<void> _onLoadCantadorData(
    LoadCantadorData event,
    Emitter<CantadorState> emit,
  ) async {
    emit(const CantadorLoading());

    try {
      final results = await Future.wait([
        ApiService.getCantadorAggregated(),
        ApiService.getCantadorOrders(),
        ApiService.getCantadorHistory(),
      ]);

      emit(
        CantadorLoaded(
          aggregated: CantadorAggregatedView.fromJson(
            results[0] as Map<String, dynamic>,
          ),
          activeOrders: (results[1] as List<dynamic>)
              .map((j) => CantadorOrder.fromJson(j))
              .toList(),
          history: (results[2] as List<dynamic>)
              .map((j) => CantadorOrder.fromJson(j))
              .toList(),
        ),
      );
    } catch (e) {
      emit(CantadorError('No se pudieron cargar los datos: $e'));
    }
  }

  // ─────────────────────────────────────────────
  // REFRESH
  // ─────────────────────────────────────────────
  Future<void> _onRefreshCantadorData(
    RefreshCantadorData event,
    Emitter<CantadorState> emit,
  ) async {
    final current = state;
    if (current is! CantadorLoaded) {
      add(const LoadCantadorData());
      return;
    }

    emit(current.copyWith(isRefreshing: true));

    try {
      final results = await Future.wait([
        ApiService.getCantadorAggregated(),
        ApiService.getCantadorOrders(),
        ApiService.getCantadorHistory(),
      ]);

      emit(
        current.copyWith(
          aggregated: CantadorAggregatedView.fromJson(
            results[0] as Map<String, dynamic>,
          ),
          activeOrders: (results[1] as List<dynamic>)
              .map((j) => CantadorOrder.fromJson(j))
              .toList(),
          history: (results[2] as List<dynamic>)
              .map((j) => CantadorOrder.fromJson(j))
              .toList(),
          isRefreshing: false,
        ),
      );
    } catch (e) {
      emit(current.copyWith(isRefreshing: false));
    }
  }

  // ─────────────────────────────────────────────
  // SERVIR PLATO (SEGUNDOS / ENTRADAS)
  // ─────────────────────────────────────────────
  Future<void> _onServeDish(
    ServeDishEvent event,
    Emitter<CantadorState> emit,
  ) async {
    try {
      await ApiService.serveItem(event.productId);
      add(const RefreshCantadorData());
    } catch (e) {
      rethrow;
    }
  }

  // ─────────────────────────────────────────────
  // SERVIR ITEM ESPECÍFICO
  // ─────────────────────────────────────────────
  Future<void> _onServeOrderItem(
    ServeOrderItemEvent event,
    Emitter<CantadorState> emit,
  ) async {
    try {
      await ApiService.serveItemById(event.orderItemId);
      add(const RefreshCantadorData());
    } catch (e) {
      rethrow;
    }
  }

  // ─────────────────────────────────────────────
  // MARCAR ORDEN COMO CANTADA
  // ─────────────────────────────────────────────
  Future<void> _onMarkAsSung(
    MarkAsSungEvent event,
    Emitter<CantadorState> emit,
  ) async {
    try {
      await ApiService.markOrderAsSung(event.orderId);
      add(const RefreshCantadorData());
    } catch (e) {
      rethrow;
    }
  }
}
