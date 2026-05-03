import 'package:equatable/equatable.dart';

/// Entrada (cortesía) agregada en la vista "POR CANTIDADES".
///
/// Las entradas NO son productos:
/// - No tienen productId
/// - No se sirven en BD
/// - Solo se descuentan visualmente
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
      pendingTables: List<String>.from(json['pendingTables'] ?? const []),
    );
  }

  /// 🔽 Descuenta UNA entrada:
  /// - resta 1 a la cantidad
  /// - elimina UNA mesa
  AggregatedEntrada serveOne() {
    if (pendingQuantity <= 0) return this;

    final newTables = List<String>.from(pendingTables);
    if (newTables.isNotEmpty) {
      newTables.removeAt(0);
    }

    return AggregatedEntrada(
      name: name,
      pendingQuantity: pendingQuantity - 1,
      pendingTables: newTables,
    );
  }

  /// Util para el BLoC
  bool get isCompleted => pendingQuantity <= 0;

  @override
  List<Object?> get props => [name, pendingQuantity, pendingTables];

  @override
  String toString() =>
      'AggregatedEntrada($name x$pendingQuantity, mesas: $pendingTables)';
}
