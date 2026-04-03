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
  const CashFlowInitial();
}

/// Caja cerrada
class CashFlowClosed extends CashFlowState {
  final List<Transaction> transactions;
  final double totalIncome;
  final double totalExpense;
  final double finalBalance;

  const CashFlowClosed({
    required this.transactions,
    required this.totalIncome,
    required this.totalExpense,
    required this.finalBalance,
  });

  @override
  List<Object?> get props => [
    transactions,
    totalIncome,
    totalExpense,
    finalBalance,
  ];
}

/// Flujo de caja cargado
class CashFlowLoaded extends CashFlowState {
  final List<Transaction> transactions;

  const CashFlowLoaded(this.transactions);

  @override
  List<Object?> get props => [transactions];
}

/// Estado de error
class CashFlowError extends CashFlowState {
  final String message;

  const CashFlowError(this.message);

  @override
  List<Object?> get props => [message];
}
