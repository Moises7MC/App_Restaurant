import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/routes/app_router.dart';
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

  // Selección por cliente: índice → nombre entrada (null = sin entrada)
  late List<String?> _selections;

  @override
  void initState() {
    super.initState();
    _selections = List.filled(widget.customerCount, null);
    _loadEntradas();
  }

  Future<void> _loadEntradas() async {
    try {
      final data = await ApiService.getTodayEntradas();
      if (mounted) {
        setState(() {
          _entradas = List<Map<String, dynamic>>.from(data);
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

  // ✅ Construir texto resumen: "2x Tamal, 1x Sopa, 1x Sin entrada"
  String _buildEntradasText() {
    final counter = <String, int>{};
    for (final sel in _selections) {
      final key = sel ?? 'Sin entrada';
      counter[key] = (counter[key] ?? 0) + 1;
    }
    return counter.entries.map((e) => '${e.value}x ${e.key}').join(', ');
  }

  void _confirm() {
    final entradasText = _buildEntradasText();
    // Guardar en el BLoC para que cart_page lo incluya al crear la orden
    context.read<CartBloc>().add(SetEntradas(entradasText));
    context.goToProducts(widget.mealType, widget.tableNumber);
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
              const Text('🍽️', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selecciona las entradas',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${widget.customerCount} cliente${widget.customerCount > 1 ? 's' : ''} · una entrada por persona',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
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
                  itemCount: widget.customerCount,
                  itemBuilder: (context, i) => _buildClientCard(i),
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
              'Continuar a platos',
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

  Widget _buildClientCard(int clientIndex) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${clientIndex + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Cliente ${clientIndex + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Opción sin entrada
          // Opción sin entrada
          _buildOption(
            clientIndex: clientIndex,
            value: null,
            name: 'Sin entrada',
            icon: '🚫',
          ),

          // Opciones del día
          ..._entradas.map(
            (e) => _buildOption(
              clientIndex: clientIndex,
              value: e['name'] as String,
              name: e['name'] as String,
              icon: '🥣',
            ),
          ),

          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildOption({
    required int clientIndex,
    required String? value,
    required String name,
    required String icon,
  }) {
    final isSelected = _selections[clientIndex] == value;
    return GestureDetector(
      onTap: () => setState(() => _selections[clientIndex] = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.fromLTRB(10, 4, 10, 0),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.4)
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: AppColors.primary, size: 20),
          ],
        ),
      ),
    );
  }
}
