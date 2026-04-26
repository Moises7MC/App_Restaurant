import 'package:app_restaurant/features/meals/presentation/pages/products_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../services/api_service.dart';
import '../bloc/cart_bloc.dart';
import '../bloc/cart_event.dart';

class EntradaSelectionPage extends StatefulWidget {
  final String mealType;
  final int tableNumber;
  final int customerCount;

  const EntradaSelectionPage({
    super.key,
    required this.mealType,
    required this.tableNumber,
    required this.customerCount,
  });

  @override
  State<EntradaSelectionPage> createState() => _EntradaSelectionPageState();
}

class _EntradaSelectionPageState extends State<EntradaSelectionPage> {
  List<Map<String, dynamic>> _entradas = [];
  bool _loading = true;
  String? _error;

  // cantidad por entrada: nombre → cantidad
  final Map<String, int> _quantities = {};

  @override
  void initState() {
    super.initState();
    _loadEntradas();
  }

  Future<void> _loadEntradas() async {
    try {
      final data = await ApiService.getTodayEntradas();
      if (mounted) {
        setState(() {
          _entradas = List<Map<String, dynamic>>.from(data);
          for (final e in _entradas) {
            _quantities[e['name'] as String] = 0;
          }
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'No se pudieron cargar las entradas';
          _loading = false;
        });
      }
    }
  }

  int get _totalSelected => _quantities.values.fold(0, (sum, q) => sum + q);

  String _buildEntradasText() {
    final parts = _quantities.entries
        .where((e) => e.value > 0)
        .map((e) => '${e.value}x ${e.key}')
        .toList();
    return parts.join(', ');
  }

  void _confirm() {
    final entradasText = _buildEntradasText();
    final cartBloc = context.read<CartBloc>();

    cartBloc.add(
      SelectTable(mealType: widget.mealType, tableNumber: widget.tableNumber),
    );

    if (entradasText.isNotEmpty) {
      cartBloc.add(SetEntradas(entradasText));
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: cartBloc,
          child: ProductsPage(
            mealType: widget.mealType,
            tableNumber: widget.tableNumber,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Entradas — Mesa ${widget.tableNumber}'),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? _buildError()
            : _buildBody(),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 12),
          Text(_error!),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _loading = true;
                _error = null;
              });
              _loadEntradas();
            },
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              const Text('🥣', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Entradas del día',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${widget.customerCount} cliente${widget.customerCount > 1 ? 's' : ''} · selecciona las cantidades',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (_totalSelected > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$_totalSelected selec.',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        Expanded(
          child: _entradas.isEmpty
              ? _buildNoEntradas()
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  itemCount: _entradas.length,
                  itemBuilder: (context, i) => _buildEntradaCard(_entradas[i]),
                ),
        ),

        // Botón confirmar
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: _confirm,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              _totalSelected > 0
                  ? 'Continuar con $_totalSelected entrada${_totalSelected > 1 ? 's' : ''}'
                  : 'Continuar sin entradas',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEntradaCard(Map<String, dynamic> entrada) {
    final name = entrada['name'] as String;
    final qty = _quantities[name] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: qty > 0
              ? AppColors.primary.withValues(alpha: 0.4)
              : Colors.grey.shade200,
          width: qty > 0 ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icono
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: qty > 0
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Text('🥣', style: TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 14),

          // Nombre
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontSize: 15,
                fontWeight: qty > 0 ? FontWeight.w600 : FontWeight.normal,
                color: qty > 0 ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
          ),

          // Controles cantidad
          Row(
            children: [
              GestureDetector(
                onTap: qty > 0
                    ? () => setState(() => _quantities[name] = qty - 1)
                    : null,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: qty > 0 ? AppColors.primary : AppColors.border,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.remove,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ),
              Container(
                width: 40,
                height: 34,
                alignment: Alignment.center,
                child: Text(
                  '$qty',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: qty > 0
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _quantities[name] = qty + 1),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.add, size: 18, color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoEntradas() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🍵', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(
            'No hay entradas definidas para hoy',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 6),
          Text(
            'El chef aún no cargó las entradas del día',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _confirm,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
            child: const Text(
              'Continuar sin entradas',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
