import 'package:equatable/equatable.dart';

/// Entrada (cortesía) agregada en la vista "POR CANTIDADES".
///
/// A diferencia de AggregatedDish, las entradas NO son productos sino
/// strings del campo Order.Entradas. No tienen ServedQuantity en BD;
/// el cantador solo las "tacha visualmente" cuando las da.
class AggregatedEntrada extends Equatable {
  final String name;
  final int pendingQuantity;
  final List<String> pendingTables;

  const AggregatedEntrada({
    required this.name,
    required this.pendingQuantity,
    required this.pendingTables,
  });

  factory AggregatedEntrada.fromJson(Map<String, dynamic> json) {
    return AggregatedEntrada(
      name: json['name'] as String,
      pendingQuantity: json['pendingQuantity'] as int,
      pendingTables: List<String>.from(json['pendingTables'] ?? []),
    );
  }

  @override
  List<Object?> get props => [name, pendingQuantity, pendingTables];

  @override
  String toString() =>
      'AggregatedEntrada($name x$pendingQuantity, mesas: $pendingTables)';
}
