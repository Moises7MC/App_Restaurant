import 'package:equatable/equatable.dart';
import '../../domain/entities/transaction.dart';

/// Estados del flujo de caja
abstract class CashFlowState extends Equatable {
  const CashFlowState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial
class CashFlowInitial extends CashFlowState {
  @override
  String toString() => 'CashFlowInitial()';
}

/// Estado: Flujo de caja cargado
class CashFlowLoaded extends CashFlowState {
  /// Lista de transacciones
  final List<Transaction> transactions;

  const CashFlowLoaded(this.transactions);

  /// Calcula el total de ingresos
  double get totalIncome => transactions
      .where((t) => t.type == 'ingreso')
      .fold(0, (sum, t) => sum + t.amount);

  /// Calcula el total de gastos
  double get totalExpense => transactions
      .where((t) => t.type == 'gasto')
      .fold(0, (sum, t) => sum + t.amount);

  /// Calcula el balance neto
  double get balance => totalIncome - totalExpense;

  /// Cantidad total de transacciones
  int get transactionCount => transactions.length;

  @override
  List<Object?> get props => [transactions];

  @override
  String toString() =>
      'CashFlowLoaded(transactions: ${transactions.length}, income: \$$totalIncome, expense: \$$totalExpense, balance: \$$balance)';
}

/// Estado: Error
class CashFlowError extends CashFlowState {
  final String message;

  const CashFlowError(this.message);

  @override
  List<Object?> get props => [message];

  @override
  String toString() => 'CashFlowError(message: $message)';
}
