import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/transaction.dart';
import 'cash_flow_event.dart';
import 'cash_flow_state.dart';

class CashFlowBloc extends Bloc<CashFlowEvent, CashFlowState> {
  /// Lista de transacciones en memoria
  final List<Transaction> _transactions = [];

  CashFlowBloc() : super(CashFlowInitial()) {
    on<AddIncome>(_onAddIncome);
    on<AddExpense>(_onAddExpense);
    on<LoadTransactions>(_onLoadTransactions);
    on<ClearCashFlow>(_onClearCashFlow);
  }

  /// Maneja agregar ingreso
  Future<void> _onAddIncome(
    AddIncome event,
    Emitter<CashFlowState> emit,
  ) async {
    try {
      final transaction = Transaction(
        id: const Uuid().v4(),
        type: 'ingreso',
        amount: event.amount,
        description: event.description,
        dateTime: DateTime.now(),
        tableNumber: event.tableNumber,
      );

      _transactions.add(transaction);
      _transactions.sort((a, b) => b.dateTime.compareTo(a.dateTime));

      emit(CashFlowLoaded(List.from(_transactions)));
    } catch (e) {
      emit(CashFlowError('Error al agregar ingreso: $e'));
    }
  }

  /// Maneja agregar gasto
  Future<void> _onAddExpense(
    AddExpense event,
    Emitter<CashFlowState> emit,
  ) async {
    try {
      final transaction = Transaction(
        id: const Uuid().v4(),
        type: 'gasto',
        amount: event.amount,
        description: event.description,
        dateTime: DateTime.now(),
      );

      _transactions.add(transaction);
      _transactions.sort((a, b) => b.dateTime.compareTo(a.dateTime));

      emit(CashFlowLoaded(List.from(_transactions)));
    } catch (e) {
      emit(CashFlowError('Error al agregar gasto: $e'));
    }
  }

  /// Maneja cargar transacciones
  Future<void> _onLoadTransactions(
    LoadTransactions event,
    Emitter<CashFlowState> emit,
  ) async {
    try {
      if (_transactions.isEmpty) {
        emit(CashFlowLoaded(const []));
      } else {
        emit(CashFlowLoaded(List.from(_transactions)));
      }
    } catch (e) {
      emit(CashFlowError('Error al cargar transacciones: $e'));
    }
  }

  /// Maneja cerrar caja (cierre de caja diario)
  Future<void> _onClearCashFlow(
    ClearCashFlow event,
    Emitter<CashFlowState> emit,
  ) async {
    try {
      // Calcular totales antes de limpiar
      final ingresos = _transactions
          .where((t) => t.type == 'ingreso')
          .fold<double>(0, (sum, t) => sum + t.amount);

      final gastos = _transactions
          .where((t) => t.type == 'gasto')
          .fold<double>(0, (sum, t) => sum + t.amount);

      final balance = ingresos - gastos;

      // Emitir estado de caja cerrada con el resumen
      emit(
        CashFlowClosed(
          transactions: List.from(_transactions),
          totalIncome: ingresos,
          totalExpense: gastos,
          finalBalance: balance,
        ),
      );

      // Limpiar transacciones después de guardar el resumen
      _transactions.clear();
    } catch (e) {
      emit(CashFlowError('Error al cerrar caja: $e'));
    }
  }

  /// Getter para obtener transacciones actuales
  List<Transaction> get transactions => List.from(_transactions);

  /// Obtener el estado actual como CashFlowLoaded
  CashFlowLoaded? get currentCashFlow {
    if (_transactions.isEmpty) return null;
    return CashFlowLoaded(List.from(_transactions));
  }
}
