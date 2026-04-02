import 'package:equatable/equatable.dart';

/// Entidad que representa una transacción (ingreso o gasto)
class Transaction extends Equatable {
  /// ID único de la transacción
  final String id;

  /// Tipo: 'ingreso' o 'gasto'
  final String type; // 'ingreso' or 'gasto'

  /// Monto de la transacción
  final double amount;

  /// Descripción
  final String description;

  /// Fecha y hora
  final DateTime dateTime;

  /// Número de mesa (si es ingreso de un pedido)
  final int? tableNumber;

  /// Constructor
  const Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.dateTime,
    this.tableNumber,
  });

  @override
  List<Object?> get props => [
    id,
    type,
    amount,
    description,
    dateTime,
    tableNumber,
  ];

  @override
  String toString() =>
      'Transaction(id: $id, type: $type, amount: \$$amount, description: $description)';
}
