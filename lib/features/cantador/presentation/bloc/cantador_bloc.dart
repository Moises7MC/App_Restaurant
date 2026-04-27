import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../services/api_service.dart';
import '../../domain/entities/cantador_aggregated_view.dart';
import '../../domain/entities/cantador_order.dart';
import 'cantador_event.dart';
import 'cantador_state.dart';

/// BLoC del cantador.
///
/// Maneja:
///  - Carga inicial y refrescos (LoadCantadorData / RefreshCantadorData)
///  - Descuento de platos (ServeDishEvent / ServeOrderItemEvent)
///  - Marcar como cantado (MarkAsSungEvent)
///  - Tacheo local de entradas (ToggleEntradaServidaEvent)
class CantadorBloc extends Bloc<CantadorEvent, CantadorState> {
  CantadorBloc() : super(const CantadorInitial()) {
    on<LoadCantadorData>(_onLoadCantadorData);
    on<RefreshCantadorData>(_onRefreshCantadorData);
    on<ServeDishEvent>(_onServeDish);
    on<ServeOrderItemEvent>(_onServeOrderItem);
    on<MarkAsSungEvent>(_onMarkAsSung);
    on<ToggleEntradaServidaEvent>(_onToggleEntradaServida);
  }

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

      final aggregated = CantadorAggregatedView.fromJson(
        results[0] as Map<String, dynamic>,
      );
      final orders = (results[1] as List<dynamic>)
          .map((j) => CantadorOrder.fromJson(j as Map<String, dynamic>))
          .toList();
      final history = (results[2] as List<dynamic>)
          .map((j) => CantadorOrder.fromJson(j as Map<String, dynamic>))
          .toList();

      emit(
        CantadorLoaded(
          aggregated: aggregated,
          activeOrders: orders,
          history: history,
        ),
      );
    } catch (e) {
      print('❌ Error cargando datos del cantador: $e');
      emit(CantadorError('No se pudieron cargar los datos: $e'));
    }
  }

  Future<void> _onRefreshCantadorData(
    RefreshCantadorData event,
    Emitter<CantadorState> emit,
  ) async {
    final current = state;

    // Si no hay datos previos, hacer carga normal
    if (current is! CantadorLoaded) {
      add(const LoadCantadorData());
      return;
    }

    // Mostrar indicador de refrescando sin esconder los datos
    emit(current.copyWith(isRefreshing: true));

    try {
      final results = await Future.wait([
        ApiService.getCantadorAggregated(),
        ApiService.getCantadorOrders(),
        ApiService.getCantadorHistory(),
      ]);

      final aggregated = CantadorAggregatedView.fromJson(
        results[0] as Map<String, dynamic>,
      );
      final orders = (results[1] as List<dynamic>)
          .map((j) => CantadorOrder.fromJson(j as Map<String, dynamic>))
          .toList();
      final history = (results[2] as List<dynamic>)
          .map((j) => CantadorOrder.fromJson(j as Map<String, dynamic>))
          .toList();

      // Limpiar entradas tachadas que ya no están en el agregado
      // (porque se cobraron o ya no quedan pendientes)
      final stillPending = aggregated.entradas
          .map((e) => e.name.toLowerCase().trim())
          .toSet();
      final cleanedServidas = current.entradasServidasLocales
          .where((s) => stillPending.contains(s.toLowerCase().trim()))
          .toSet();

      emit(
        CantadorLoaded(
          aggregated: aggregated,
          activeOrders: orders,
          history: history,
          entradasServidasLocales: cleanedServidas,
          isRefreshing: false,
        ),
      );
    } catch (e) {
      print('❌ Error refrescando datos: $e');
      // No romper el estado actual ante un error de refresh
      emit(current.copyWith(isRefreshing: false));
    }
  }

  Future<void> _onServeDish(
    ServeDishEvent event,
    Emitter<CantadorState> emit,
  ) async {
    try {
      await ApiService.serveItem(event.productId);
      // Después de servir, refrescar
      add(const RefreshCantadorData());
    } catch (e) {
      print('❌ Error sirviendo plato: $e');
      // No emitir error para no romper la UI; el SnackBar lo maneja la pantalla
      rethrow;
    }
  }

  Future<void> _onServeOrderItem(
    ServeOrderItemEvent event,
    Emitter<CantadorState> emit,
  ) async {
    try {
      await ApiService.serveItemById(event.orderItemId);
      add(const RefreshCantadorData());
    } catch (e) {
      print('❌ Error sirviendo item: $e');
      rethrow;
    }
  }

  Future<void> _onMarkAsSung(
    MarkAsSungEvent event,
    Emitter<CantadorState> emit,
  ) async {
    try {
      await ApiService.markOrderAsSung(event.orderId);
      add(const RefreshCantadorData());
    } catch (e) {
      print('❌ Error marcando como cantado: $e');
      rethrow;
    }
  }

  Future<void> _onToggleEntradaServida(
    ToggleEntradaServidaEvent event,
    Emitter<CantadorState> emit,
  ) async {
    final current = state;
    if (current is! CantadorLoaded) return;

    final key = event.entradaName.toLowerCase().trim();
    final newSet = Set<String>.from(current.entradasServidasLocales);

    if (newSet.contains(key)) {
      newSet.remove(key);
    } else {
      newSet.add(key);
    }

    emit(current.copyWith(entradasServidasLocales: newSet));
  }
}
