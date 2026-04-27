import 'package:equatable/equatable.dart';
import 'aggregated_dish.dart';
import 'aggregated_entrada.dart';

/// Vista completa "POR CANTIDADES" del cantador.
///
/// Contiene las entradas (cortesías) y los segundos (productos) agregados
/// de todas las mesas activas del día.
class CantadorAggregatedView extends Equatable {
  final List<AggregatedEntrada> entradas;
  final List<AggregatedDish> segundos;

  const CantadorAggregatedView({
    required this.entradas,
    required this.segundos,
  });

  factory CantadorAggregatedView.fromJson(Map<String, dynamic> json) {
    return CantadorAggregatedView(
      entradas: (json['entradas'] as List<dynamic>? ?? [])
          .map((e) => AggregatedEntrada.fromJson(e as Map<String, dynamic>))
          .toList(),
      segundos: (json['segundos'] as List<dynamic>? ?? [])
          .map((e) => AggregatedDish.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Total de entradas pendientes (suma de cantidades)
  int get totalEntradas =>
      entradas.fold(0, (sum, e) => sum + e.pendingQuantity);

  /// Total de segundos pendientes (suma de cantidades)
  int get totalSegundos =>
      segundos.fold(0, (sum, d) => sum + d.pendingQuantity);

  bool get isEmpty => entradas.isEmpty && segundos.isEmpty;

  static const empty = CantadorAggregatedView(entradas: [], segundos: []);

  @override
  List<Object?> get props => [entradas, segundos];
}
