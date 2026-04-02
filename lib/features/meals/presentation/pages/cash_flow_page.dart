import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../bloc/cash_flow_bloc.dart';
import '../bloc/cash_flow_event.dart';
import '../bloc/cash_flow_state.dart';

class CashFlowPage extends StatelessWidget {
  const CashFlowPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flujo de Caja'),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: BlocBuilder<CashFlowBloc, CashFlowState>(
        builder: (context, state) {
          if (state is CashFlowLoaded) {
            return SingleChildScrollView(
              child: Column(
                children: [
                  // ════════════════════════════════════
                  // RESUMEN DE CAJA
                  // ════════════════════════════════════
                  _buildCashSummary(context, state),

                  const SizedBox(height: 24),

                  // ════════════════════════════════════
                  // TRANSACCIONES
                  // ════════════════════════════════════
                  if (state.transactions.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Center(
                        child: Text(
                          'No hay transacciones',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    )
                  else
                    _buildTransactionsList(context, state),

                  const SizedBox(height: 24),

                  // ════════════════════════════════════
                  // BOTONES DE ACCIÓN
                  // ════════════════════════════════════
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Botón Agregar Gasto
                        ElevatedButton(
                          onPressed: () => _showAddExpenseDialog(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.remove_circle_outline),
                              const SizedBox(width: 8),
                              Text(
                                'Agregar Gasto',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      color: AppColors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Botón Cierre de Caja
                        ElevatedButton(
                          onPressed: () => _showCloseCashDialog(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.textPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle_outline),
                              const SizedBox(width: 8),
                              Text(
                                'Cierre de Caja',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      color: AppColors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  /// Widget: Resumen de caja
  Widget _buildCashSummary(BuildContext context, CashFlowLoaded state) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          // INGRESOS
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.success.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ingresos',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${state.totalIncome.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Icon(
                  Icons.add_circle,
                  size: 40,
                  color: AppColors.success.withOpacity(0.7),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // GASTOS
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.error.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gastos',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${state.totalExpense.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Icon(
                  Icons.remove_circle,
                  size: 40,
                  color: AppColors.error.withOpacity(0.7),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // BALANCE NETO
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Balance Neto',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${state.balance.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Icon(
                  Icons.account_balance_wallet,
                  size: 40,
                  color: AppColors.primary.withOpacity(0.7),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Widget: Lista de transacciones
  Widget _buildTransactionsList(BuildContext context, CashFlowLoaded state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Historial de Transacciones',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...state.transactions.map((transaction) {
            final isIncome = transaction.type == 'ingreso';
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isIncome
                        ? AppColors.success.withOpacity(0.3)
                        : AppColors.error.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    // Ícono
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: isIncome
                            ? AppColors.success.withOpacity(0.2)
                            : AppColors.error.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          isIncome ? Icons.add : Icons.remove,
                          color: isIncome ? AppColors.success : AppColors.error,
                          size: 28,
                        ),
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Información
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            transaction.description,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat(
                              'dd/MM/yyyy HH:mm',
                            ).format(transaction.dateTime),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Monto
                    Text(
                      '${isIncome ? '+' : '-'}\$${transaction.amount.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isIncome ? AppColors.success : AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  /// Diálogo: Agregar gasto
  void _showAddExpenseDialog(BuildContext context) {
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Agregar Gasto'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Monto',
                hintText: '0.00',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Descripción',
                hintText: 'Ej: Compra de ingredientes',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(amountController.text) ?? 0;
              final description = descriptionController.text;

              if (amount > 0 && description.isNotEmpty) {
                context.read<CashFlowBloc>().add(
                  AddExpense(amount: amount, description: description),
                );
                Navigator.of(dialogContext).pop();
              }
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }

  /// Diálogo: Cierre de caja
  void _showCloseCashDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cierre de Caja'),
        content: const Text(
          '¿Confirmas el cierre de caja? Se limpiarán todas las transacciones.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<CashFlowBloc>().add(const ClearCashFlow());
              Navigator.of(dialogContext).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Caja cerrada'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Confirmar Cierre'),
          ),
        ],
      ),
    );
  }
}
