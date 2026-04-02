import 'package:equatable/equatable.dart';

/// Eventos del flujo de caja
abstract class CashFlowEvent extends Equatable {
  const CashFlowEvent();

  @override
  List<Object?> get props => [];
}

/// Evento: Agregar ingreso (cuando confirma un pedido)
class AddIncome extends CashFlowEvent {
  /// Monto del ingreso
  final double amount;

  /// Descripción (ej: "Pedido Mesa 3")
  final String description;

  /// Número de mesa
  final int tableNumber;

  const AddIncome({
    required this.amount,
    required this.description,
    required this.tableNumber,
  });

  @override
  List<Object?> get props => [amount, description, tableNumber];

  @override
  String toString() =>
      'AddIncome(amount: \$$amount, description: $description, table: $tableNumber)';
}

/// Evento: Agregar gasto
class AddExpense extends CashFlowEvent {
  /// Monto del gasto
  final double amount;

  /// Descripción
  final String description;

  const AddExpense({required this.amount, required this.description});

  @override
  List<Object?> get props => [amount, description];

  @override
  String toString() =>
      'AddExpense(amount: \$$amount, description: $description)';
}

/// Evento: Obtener transacciones
class LoadTransactions extends CashFlowEvent {
  const LoadTransactions();

  @override
  String toString() => 'LoadTransactions()';
}

/// Evento: Limpiar flujo de caja (cierre de caja diario)
class ClearCashFlow extends CashFlowEvent {
  const ClearCashFlow();

  @override
  String toString() => 'ClearCashFlow()';
}
