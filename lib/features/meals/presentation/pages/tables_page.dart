import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:signalr_netcore/signalr_client.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/routes/app_router.dart';
import '../../../meals/domain/entities/RestaurantTable.dart';
import '../bloc/cart_bloc.dart';
import '../bloc/cart_state.dart';
import '../../../../services/api_service.dart';

class TablesPage extends StatefulWidget {
  final String mealType;
  const TablesPage({super.key, required this.mealType});

  @override
  State<TablesPage> createState() => _TablesPageState();
}

class _TablesPageState extends State<TablesPage> {
  Set<int> _occupiedFromBackend = {};
  bool _loadingTables = true;

  // SignalR para tiempo real
  HubConnection? _hubConnection;

  @override
  void initState() {
    super.initState();
    _loadOccupiedTables();
    _connectSignalR();
  }

  @override
  void dispose() {
    _hubConnection?.stop();
    super.dispose();
  }

  // ════════════════════════════════════════════════════════════
  // SIGNALR — Escuchar cambios de mesas en tiempo real
  // ════════════════════════════════════════════════════════════
  Future<void> _connectSignalR() async {
    try {
      _hubConnection = HubConnectionBuilder()
          .withUrl('http://localhost:5245/hubs/orders')
          .withAutomaticReconnect()
          .build();

      // Escuchar cuando una mesa cambia de estado
      _hubConnection!.on('MesaCambio', (args) {
        if (args != null && args.isNotEmpty && mounted) {
          final data = args[0] as Map<String, dynamic>?;
          if (data != null) {
            final tableNumber = data['tableNumber'] as int;
            final isOccupied = data['isOccupied'] as bool;

            setState(() {
              if (isOccupied) {
                _occupiedFromBackend.add(tableNumber);
              } else {
                _occupiedFromBackend.remove(tableNumber);
              }
            });
          }
        }
      });

      // Escuchar actualizaciones de pedidos (también afecta las mesas)
      _hubConnection!.on('ActualizacionPedido', (args) {
        // Recargar mesas cuando hay una actualización general
        _loadOccupiedTables();
      });

      _hubConnection!.on('NuevoPedido', (args) {
        _loadOccupiedTables();
      });

      await _hubConnection!.start();

      // Unirse al grupo de mozos para recibir notificaciones de mesas
      await _hubConnection!.invoke('JoinWaitersGroup');

      print('✅ SignalR conectado en TablesPage');
    } catch (e) {
      print('⚠️ SignalR no disponible en TablesPage: $e');
    }
  }

  Future<void> _loadOccupiedTables() async {
    try {
      final occupied = await ApiService.getOccupiedTableNumbers();
      if (mounted) {
        setState(() {
          _occupiedFromBackend = occupied.toSet();
          _loadingTables = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingTables = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tables = _generateTables();

    return Scaffold(
      appBar: AppBar(
        title: Text('Mesas — ${widget.mealType}'),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.goToMeals(),
        ),
        actions: [
          // Indicador de conexión SignalR
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Icon(
              _hubConnection?.state == HubConnectionState.Connected
                  ? Icons.wifi
                  : Icons.wifi_off,
              color: _hubConnection?.state == HubConnectionState.Connected
                  ? AppColors.success
                  : AppColors.error,
              size: 20,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _loadingTables = true);
              _loadOccupiedTables();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: _loadingTables
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Leyenda
                    Row(
                      children: [
                        _buildLegendDot(AppColors.primary, 'Ocupada'),
                        const SizedBox(width: 16),
                        _buildLegendDot(AppColors.success, 'Libre'),
                        const Spacer(),
                        Text(
                          '${_occupiedFromBackend.length} ocupadas',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 1.0,
                            ),
                        itemCount: tables.length,
                        itemBuilder: (context, index) {
                          return _buildTableCard(context, tables[index]);
                        },
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildTableCard(BuildContext context, RestaurantTable table) {
    return BlocBuilder<CartBloc, CartState>(
      builder: (context, state) {
        final cartBloc = context.read<CartBloc>();
        final isOccupiedLocal = cartBloc.isTableOccupied(
          widget.mealType,
          table.number,
        );
        final isOccupiedBackend = _occupiedFromBackend.contains(table.number);
        final isOccupied = isOccupiedLocal || isOccupiedBackend;

        return GestureDetector(
          onTap: () => context.goToProducts(widget.mealType, table.number),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              color: isOccupied
                  ? AppColors.primary.withOpacity(0.15)
                  : AppColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isOccupied ? AppColors.primary : AppColors.border,
                width: isOccupied ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isOccupied
                      ? AppColors.primary.withOpacity(0.2)
                      : AppColors.shadow,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: isOccupied
                        ? AppColors.primary
                        : AppColors.primaryLight.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.table_restaurant,
                    size: 32,
                    color: isOccupied ? AppColors.white : AppColors.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Mesa ${table.number}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isOccupied
                        ? AppColors.primary
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                if (isOccupied)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '🔴 Ocupada',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else
                  Text(
                    '✅ Libre • ${table.capacity} pers.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<RestaurantTable> _generateTables() {
    return List.generate(
      10,
      (i) => RestaurantTable(
        id: 'table_${i + 1}',
        number: i + 1,
        capacity: (i + 1) % 2 == 0 ? 4 : 2,
      ),
    );
  }
}
