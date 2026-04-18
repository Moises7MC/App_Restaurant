import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../services/api_service.dart';
import '../bloc/cart_bloc.dart';
import '../bloc/cart_state.dart';

class TablesPage extends StatefulWidget {
  final String mealType;
  const TablesPage({super.key, required this.mealType});

  @override
  State<TablesPage> createState() => _TablesPageState();
}

class _TablesPageState extends State<TablesPage> {
  List<Map<String, dynamic>> _floors = [];
  bool _loading = true;
  int _selectedFloor = 0;

  @override
  void initState() {
    super.initState();
    _loadTables();
  }

  Future<void> _loadTables() async {
    try {
      final data = await ApiService.getTablesByFloor();
      if (mounted) {
        setState(() {
          _floors = List<Map<String, dynamic>>.from(data);
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error cargando mesas: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _currentTables {
    if (_floors.isEmpty) return [];
    final tables = _floors[_selectedFloor]['tables'] as List<dynamic>;
    return List<Map<String, dynamic>>.from(tables);
  }

  int get _occupiedCount =>
      _currentTables.where((t) => t['isOccupied'] == true).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mesas — ${widget.mealType}'),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.goToMeals(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _loading = true);
              _loadTables();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _floors.isEmpty
            ? const Center(child: Text('No hay mesas disponibles'))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Tabs de pisos ──────────────────
                  if (_floors.length > 1)
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                      child: Row(
                        children: List.generate(_floors.length, (i) {
                          final floor = _floors[i];
                          final isSelected = _selectedFloor == i;
                          final tables = floor['tables'] as List<dynamic>;
                          final occupied = tables
                              .where((t) => t['isOccupied'] == true)
                              .length;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedFloor = i),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: EdgeInsets.only(
                                  right: i < _floors.length - 1 ? 8 : 0,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primary
                                      : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.primary
                                        : Colors.grey.shade300,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      floor['floorName'] as String,
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : AppColors.textSecondary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '$occupied ocupadas',
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.white70
                                            : Colors.grey,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),

                  // ── Leyenda ────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    child: Row(
                      children: [
                        _legendDot(AppColors.primary, 'Ocupada'),
                        const SizedBox(width: 16),
                        _legendDot(Colors.green, 'Libre'),
                        const Spacer(),
                        Text(
                          '$_occupiedCount de ${_currentTables.length} ocupadas',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Grid mesas ─────────────────────
                  Expanded(
                    child: BlocBuilder<CartBloc, CartState>(
                      builder: (context, cartState) {
                        return GridView.builder(
                          padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                                childAspectRatio: 0.9,
                              ),
                          itemCount: _currentTables.length,
                          itemBuilder: (context, index) {
                            return _buildTableCard(
                              context,
                              _currentTables[index],
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildTableCard(BuildContext context, Map<String, dynamic> table) {
    final tableNumber = table['tableNumber'] as int;
    final capacity = table['capacity'] as int;
    final isOccupiedBackend = table['isOccupied'] as bool;

    final cartBloc = context.read<CartBloc>();
    final isOccupiedLocal = cartBloc.isTableOccupied(
      widget.mealType,
      tableNumber,
    );
    final isOccupied = isOccupiedLocal || isOccupiedBackend;

    return GestureDetector(
      onTap: () => context.goToProducts(widget.mealType, tableNumber),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isOccupied
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isOccupied ? AppColors.primary : Colors.grey.shade200,
            width: isOccupied ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isOccupied
                  ? AppColors.primary.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icono
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isOccupied
                    ? AppColors.primary
                    : AppColors.primaryLight.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.table_restaurant,
                size: 20,
                color: isOccupied ? Colors.white : AppColors.primary,
              ),
            ),
            const SizedBox(height: 6),
            // Número
            Text(
              '$tableNumber',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isOccupied ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            // Estado
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isOccupied ? Icons.circle : Icons.check_circle,
                  size: 8,
                  color: isOccupied ? AppColors.primary : Colors.green,
                ),
                const SizedBox(width: 3),
                Text(
                  isOccupied ? 'Ocupada' : '$capacity p.',
                  style: TextStyle(
                    fontSize: 10,
                    color: isOccupied ? AppColors.primary : Colors.grey,
                    fontWeight: isOccupied
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
