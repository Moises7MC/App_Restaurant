import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../services/api_service.dart';
import '../bloc/cantador_bloc.dart';
import '../bloc/cantador_event.dart';
import '../bloc/cantador_state.dart';
import '../../data/services/piso_resolver.dart';
import '../../domain/entities/cantador_order.dart';

class PisoTabsPage extends StatefulWidget {
  final PisoResolver pisoResolver;
  const PisoTabsPage({super.key, required this.pisoResolver});

  @override
  State<PisoTabsPage> createState() => _PisoTabsPageState();
}

class _PisoTabsPageState extends State<PisoTabsPage> {
  int _selectedPiso = 0;
  int _selectedSubTab = 1; // 0=Entradas, 1=Segundos, 2=Mesas
  final Set<String> _servidosSegundos = {};
  final Set<String> _servidosEntradas = {};
  final Set<int> _expandedSegundos = {};
  final Set<String> _expandedEntradas = {};
  final Set<String> _procesando = {};

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CantadorBloc, CantadorState>(
      builder: (context, state) {
        if (state is CantadorLoading || state is CantadorInitial) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is CantadorError) {
          return Center(child: Text(state.message));
        }
        if (state is! CantadorLoaded) {
          return const SizedBox.shrink();
        }
        return Column(
          children: [
            _buildPisoTabs(),
            const SizedBox(height: 16),
            _buildSubTabs(),
            const SizedBox(height: 12),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  context.read<CantadorBloc>().add(const RefreshCantadorData());
                  await Future.delayed(const Duration(milliseconds: 600));
                },
                child: _selectedSubTab == 0
                    ? _buildEntradasContent(state)
                    : _selectedSubTab == 1
                    ? _buildSegundosContent(state)
                    : _buildMesasContent(state),
              ),
            ),
          ],
        );
      },
    );
  }

  // ─────────────────────────────────────────────
  // PISO TABS
  // ─────────────────────────────────────────────

  Widget _buildPisoTabs() {
    final floors = widget.pisoResolver.floors;
    if (floors.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: List.generate(floors.length, (i) {
          final selected = _selectedPiso == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedPiso = i),
              child: Container(
                margin: EdgeInsets.only(right: i < floors.length - 1 ? 8 : 0),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? Colors.amber : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  floors[i].floorName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: selected ? Colors.white : Colors.grey.shade600,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // SUB TABS (ahora 3)
  // ─────────────────────────────────────────────

  Widget _buildSubTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          _buildSubTab(0, 'Entradas'),
          _buildSubTab(1, 'Segundos'),
          _buildSubTab(2, 'Mesas'),
        ],
      ),
    );
  }

  Widget _buildSubTab(int index, String label) {
    final selected = _selectedSubTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedSubTab = index),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  color: selected ? Colors.black : Colors.grey.shade400,
                ),
              ),
            ),
            Container(
              height: 2,
              color: selected ? Colors.black : Colors.transparent,
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // ENTRADAS (sin cambios)
  // ─────────────────────────────────────────────

  Widget _buildEntradasContent(CantadorLoaded state) {
    final pisoOrders = state.activeOrders
        .where(
          (o) =>
              widget.pisoResolver.getFloorIndex(o.tableNumber) == _selectedPiso,
        )
        .toList();

    final Map<String, List<_EntradaEntry>> grouped = {};

    for (final order in pisoOrders) {
      if (order.entradas != null && order.entradas!.isNotEmpty) {
        final lineas = order.entradas!.split('\n');
        for (final linea in lineas) {
          final trimmed = linea.trim();
          if (trimmed.isEmpty || trimmed == '🔸 NUEVO:') continue;

          final match = RegExp(r'^(\d+)x\s+(.+)$').firstMatch(trimmed);
          final nombre = match != null ? match.group(2)! : trimmed;
          final cantidad = match != null ? int.parse(match.group(1)!) : 1;

          for (int u = 0; u < cantidad; u++) {
            grouped.putIfAbsent(nombre, () => []);
            grouped[nombre]!.add(
              _EntradaEntry(
                key: '${order.id}-${order.tableNumber}-$nombre-$u',
                orderId: order.id,
                entradaName: nombre,
                tableNumber: order.tableNumber,
                waiterName: order.waiterName ?? 'Mozo',
                isParaLlevar: order.isParaLlevar,
              ),
            );
          }
        }
      }
    }

    for (final order in pisoOrders) {
      final conteoServidas = <String, int>{};
      for (final servida in order.entradasServidas) {
        final k = servida.toLowerCase().trim();
        conteoServidas[k] = (conteoServidas[k] ?? 0) + 1;
      }

      for (final key in grouped.keys.toList()) {
        grouped[key]!.removeWhere((entry) {
          if (entry.orderId != order.id) return false;
          final kName = entry.entradaName.toLowerCase().trim();
          if ((conteoServidas[kName] ?? 0) > 0) {
            conteoServidas[kName] = conteoServidas[kName]! - 1;
            _servidosEntradas.remove(entry.key);
            return true;
          }
          return false;
        });

        if (grouped[key]!.isEmpty) {
          grouped.remove(key);
        }
      }
    }

    if (grouped.isEmpty) {
      return const Center(child: Text('Sin entradas pendientes'));
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: grouped.entries.map((e) {
        final expanded = _expandedEntradas.contains(e.key);
        final pending = e.value
            .where((x) => !_servidosEntradas.contains(x.key))
            .length;

        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              ListTile(
                title: Text(
                  '${e.key} ($pending)',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                leading: Icon(
                  expanded ? Icons.arrow_drop_down : Icons.arrow_right,
                ),
                onTap: () => setState(() {
                  expanded
                      ? _expandedEntradas.remove(e.key)
                      : _expandedEntradas.add(e.key);
                }),
              ),
              if (expanded)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 14, 12),
                  child: Column(
                    children: e.value.map(_buildEntradaEntry).toList(),
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEntradaEntry(_EntradaEntry entry) {
    final servido = _servidosEntradas.contains(entry.key);

    return Row(
      children: [
        const Text('•'),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            entry.tableNumber == 0
                ? '🛍 Para llevar - ${entry.waiterName}'
                : entry.isParaLlevar
                ? '🛍 Mesa ${entry.tableNumber} - ${entry.waiterName}'
                : 'Mesa ${entry.tableNumber} - ${entry.waiterName}',
            style: TextStyle(
              decoration: servido ? TextDecoration.lineThrough : null,
              color: servido ? Colors.grey : null,
            ),
          ),
        ),
        GestureDetector(
          onTap: () async {
            final nuevoEstado = !servido;
            setState(() {
              nuevoEstado
                  ? _servidosEntradas.add(entry.key)
                  : _servidosEntradas.remove(entry.key);
            });

            try {
              await ApiService.servirEntrada(
                entry.orderId,
                entry.entradaName,
                nuevoEstado,
              );
              if (mounted) {
                context.read<CantadorBloc>().add(const RefreshCantadorData());
              }
            } catch (e) {
              if (mounted) {
                setState(() {
                  nuevoEstado
                      ? _servidosEntradas.remove(entry.key)
                      : _servidosEntradas.add(entry.key);
                });
              }
            }
          },
          child: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: servido ? Colors.amber : Colors.white,
              border: Border.all(color: Colors.amber, width: 2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: servido
                ? const Icon(Icons.check, size: 18, color: Colors.white)
                : null,
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // SEGUNDOS (sin cambios)
  // ─────────────────────────────────────────────

  Widget _buildSegundosContent(CantadorLoaded state) {
    final pisoOrders = state.activeOrders.where(
      (o) => widget.pisoResolver.getFloorIndex(o.tableNumber) == _selectedPiso,
    );

    final Map<int, _GroupedDish> grouped = {};

    for (final order in pisoOrders) {
      for (final item in order.items) {
        for (int i = 0; i < item.pendingQuantity; i++) {
          grouped.putIfAbsent(
            item.productId,
            () => _GroupedDish(
              productId: item.productId,
              productName: item.productName,
              entries: [],
            ),
          );
          grouped[item.productId]!.entries.add(
            _OrderEntry(
              orderId: order.id,
              orderItemId: item.id,
              waiterName: order.waiterName ?? 'Mozo',
              tableNumber: order.tableNumber,
              isParaLlevar: order.isParaLlevar,
              individualIndex: i,
            ),
          );
        }
      }
    }

    if (grouped.isEmpty) {
      return const Center(child: Text('Sin segundos pendientes'));
    }

    final dishes = grouped.values.toList()
      ..sort(
        (a, b) =>
            b.totalPending(_servidosSegundos) -
            a.totalPending(_servidosSegundos),
      );

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: dishes.length,
      itemBuilder: (_, i) => _buildSegundoCard(dishes[i]),
    );
  }

  Widget _buildSegundoCard(_GroupedDish dish) {
    final expanded = _expandedSegundos.contains(dish.productId);
    final pending = dish.totalPending(_servidosSegundos);

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          ListTile(
            title: Text(
              '${dish.productName} ($pending)',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            leading: Icon(expanded ? Icons.arrow_drop_down : Icons.arrow_right),
            onTap: () => setState(() {
              expanded
                  ? _expandedSegundos.remove(dish.productId)
                  : _expandedSegundos.add(dish.productId);
            }),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 14, 12),
              child: Column(
                children: dish.entries.map(_buildSegundoEntry).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSegundoEntry(_OrderEntry entry) {
    final key = '${entry.orderItemId}_${entry.individualIndex}';
    final servido = _servidosSegundos.contains(key);

    return Row(
      children: [
        const Text('•'),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            entry.tableNumber == 0
                ? '🛍 Para llevar - ${entry.waiterName}'
                : entry.isParaLlevar
                ? '🛍 Mesa ${entry.tableNumber} - ${entry.waiterName}'
                : 'Mesa ${entry.tableNumber} - ${entry.waiterName}',
            style: TextStyle(
              decoration: servido ? TextDecoration.lineThrough : null,
              color: servido ? Colors.grey : null,
            ),
          ),
        ),
        GestureDetector(
          onTap: () async {
            if (servido) {
              setState(() => _servidosSegundos.remove(key));
              return;
            }
            setState(() {
              _servidosSegundos.add(key);
              _procesando.add(key);
            });
            try {
              await ApiService.serveItemById(entry.orderItemId);
              setState(() => _servidosSegundos.remove(key));
              context.read<CantadorBloc>().add(const RefreshCantadorData());
            } finally {
              setState(() => _procesando.remove(key));
            }
          },
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: servido ? Colors.amber : Colors.white,
              border: Border.all(color: Colors.amber, width: 2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: servido
                ? const Icon(Icons.check, size: 18, color: Colors.white)
                : null,
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // MESAS (nuevo sub-tab)
  // ─────────────────────────────────────────────

  Widget _buildMesasContent(CantadorLoaded state) {
    final pisoOrders = state.activeOrders
        .where(
          (o) =>
              widget.pisoResolver.getFloorIndex(o.tableNumber) == _selectedPiso,
        )
        .toList();

    if (pisoOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🍽️', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 12),
            Text(
              'Sin mesas activas',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Cuando lleguen pedidos aparecerán aquí',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    // Resumen superior
    final totalPendientes = pisoOrders.fold<int>(
      0,
      (sum, o) =>
          sum +
          o.items.fold<int>(0, (s, i) => s + (i.quantity - i.servedQuantity)),
    );
    final totalServidos = pisoOrders.fold<int>(
      0,
      (sum, o) => sum + o.items.fold<int>(0, (s, i) => s + i.servedQuantity),
    );

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(12),
      children: [
        // ── Resumen ──
        Row(
          children: [
            _buildResumenCard(
              '${pisoOrders.length}',
              'Mesas activas',
              const Color(0xFFBA7517),
              const Color(0xFFFAEEDA),
            ),
            const SizedBox(width: 8),
            _buildResumenCard(
              '$totalPendientes',
              'Pendientes',
              Colors.grey.shade700,
              Colors.grey.shade100,
            ),
            const SizedBox(width: 8),
            _buildResumenCard(
              '$totalServidos',
              'Servidos',
              const Color(0xFF0F6E56),
              const Color(0xFFE1F5EE),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // ── Grid de mesas ──
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.5,
          ),
          itemCount: pisoOrders.length,
          itemBuilder: (context, i) => _buildMesaCard(pisoOrders[i], state),
        ),
      ],
    );
  }

  Widget _buildResumenCard(
    String value,
    String label,
    Color textColor,
    Color bgColor,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: textColor.withOpacity(0.8)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMesaCard(CantadorOrder order, CantadorLoaded state) {
    final mins = order.minutesInKitchen;
    final borderColor = mins >= 20
        ? const Color(0xFFE24B4A)
        : mins >= 8
        ? const Color(0xFFBA7517)
        : Colors.grey.shade300;
    final borderWidth = (mins >= 8) ? 1.5 : 0.5;

    final timerColor = mins >= 20
        ? const Color(0xFFA32D2D)
        : mins >= 8
        ? const Color(0xFF854F0B)
        : const Color(0xFF0F6E56);
    final timerBg = mins >= 20
        ? const Color(0xFFFCEBEB)
        : mins >= 8
        ? const Color(0xFFFAEEDA)
        : const Color(0xFFE1F5EE);

    final entradasList = _parsearEntradasIndividuales(
      order.entradas ?? '',
      order.entradasServidas,
    );
    final segundosList = _expandirItems(order.items, order.id);
    final totalItems = entradasList.length + segundosList.length;
    final servidosCount =
        entradasList.where((e) => e.servida).length +
        segundosList.where((s) => s.servido).length;

    return GestureDetector(
      onTap: () => _showMesaModal(order, state),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: borderWidth),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Fila 1: nombre + timer ──
            Row(
              children: [
                Expanded(
                  child: Text(
                    order.tableNumber == 0
                        ? 'Para llevar'
                        : 'Mesa ${order.tableNumber.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: timerBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.access_time, size: 11, color: timerColor),
                      const SizedBox(width: 3),
                      Text(
                        '${mins}min',
                        style: TextStyle(
                          fontSize: 11,
                          color: timerColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // ── Fila 2: mozo + badge ──
            Row(
              children: [
                Icon(
                  Icons.person_outline,
                  size: 12,
                  color: Colors.grey.shade500,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    order.waiterName ?? 'Mozo',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _buildStatusBadge(order.wasSung),
              ],
            ),
            const SizedBox(height: 8),
            // ── Barra de progreso compacta ──
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: totalItems > 0 ? servidosCount / totalItems : 0,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: const AlwaysStoppedAnimation(
                        Color(0xFF1D9E75),
                      ),
                      minHeight: 3,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '$servidosCount/$totalItems',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showMesaModal(CantadorOrder initialOrder, CantadorLoaded state) {
    // 1. CAPTURAMOS EL BLOC ANTES DE ABRIR EL MODAL
    final cantadorBloc = context.read<CantadorBloc>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BlocProvider.value(
        // 2. INYECTAMOS EL BLOC AL CONTEXTO DEL MODAL
        value: cantadorBloc,
        child: StatefulBuilder(
          builder: (ctx, setModalState) {
            return BlocBuilder<CantadorBloc, CantadorState>(
              builder: (ctx, blocState) {
                // Buscamos la orden actualizada en el estado fresco del BLoC
                final order = (blocState is CantadorLoaded)
                    ? blocState.activeOrders.firstWhere(
                        (o) => o.id == initialOrder.id,
                        orElse: () => initialOrder,
                      )
                    : initialOrder;

                debugPrint('=== ORDEN ${order.id} ===');
                debugPrint('entradasServidas: ${order.entradasServidas}');
                debugPrint('entradasAdicionales: ${order.entradasAdicionales}');

                final entradasList = _parsearEntradasIndividuales(
                  order.entradas ?? '',
                  order.entradasServidas,
                );
                final segundosList = _expandirItems(order.items, order.id);
                final totalItems = entradasList.length + segundosList.length;
                final servidosCount =
                    entradasList.where((e) => e.servida).length +
                    segundosList.where((s) => s.servido).length;

                return Container(
                  margin: const EdgeInsets.only(top: 60),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Handle
                      Container(
                        margin: const EdgeInsets.only(top: 12),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      // Header
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                        child: Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  order.tableNumber == 0
                                      ? 'Para llevar'
                                      : 'Mesa ${order.tableNumber.toString().padLeft(2, '0')}',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  order.waiterName ?? 'Mozo',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.of(ctx).pop(),
                            ),
                          ],
                        ),
                      ),
                      // Progreso
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(3),
                                child: LinearProgressIndicator(
                                  value: totalItems > 0
                                      ? servidosCount / totalItems
                                      : 0,
                                  backgroundColor: Colors.grey.shade200,
                                  valueColor: const AlwaysStoppedAnimation(
                                    Color(0xFF1D9E75),
                                  ),
                                  minHeight: 5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '$servidosCount/$totalItems',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 20),
                      // Lista de platos
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          children: [
                            if (entradasList.isNotEmpty ||
                                order.entradasAdicionales.isNotEmpty) ...[
                              _buildSectionLabel('ENTRADAS'),
                              ...entradasList.map(
                                (e) => _buildItemRow(
                                  name: '1 ${e.nombre}',
                                  servido: e.servida,
                                  procesando: _procesando.contains(
                                    'entrada_${e.key}',
                                  ),
                                  onTap: () async {
                                    final key = 'entrada_${e.key}';
                                    if (_procesando.contains(key)) return;
                                    setModalState(() => _procesando.add(key));
                                    try {
                                      await ApiService.servirEntrada(
                                        order.id,
                                        e.nombre,
                                        !e.servida,
                                      );
                                      if (ctx.mounted) {
                                        ctx.read<CantadorBloc>().add(
                                          const RefreshCantadorData(),
                                        );
                                      }
                                    } catch (error) {
                                      debugPrint(
                                        "Error al servir entrada: $error",
                                      );
                                    } finally {
                                      if (ctx.mounted) {
                                        setModalState(
                                          () => _procesando.remove(key),
                                        );
                                      }
                                    }
                                  },
                                ),
                              ),
                              // ✅ NUEVO: Entradas adicionales (cobradas aparte)
                              if (order.entradasAdicionales.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                ...order.entradasAdicionales.asMap().entries.map((
                                  entry,
                                ) {
                                  final idx = entry.key;
                                  final nombre = entry.value;
                                  final key =
                                      'entrada_adicional_${order.id}_$idx';
                                  final procesandoEsta = _procesando.contains(
                                    key,
                                  );

                                  // Calcular servida comparando con entradasServidas de la orden fresca
                                  final servidasNormalizadas = order
                                      .entradasServidas
                                      .map((s) => s.toLowerCase().trim())
                                      .toList();
                                  final mismoNombreAntes = order
                                      .entradasAdicionales
                                      .sublist(0, idx)
                                      .where(
                                        (n) =>
                                            n.toLowerCase().trim() ==
                                            nombre.toLowerCase().trim(),
                                      )
                                      .length;
                                  final totalServidasDeEsteNombre =
                                      servidasNormalizadas
                                          .where(
                                            (s) =>
                                                s ==
                                                nombre.toLowerCase().trim(),
                                          )
                                          .length;
                                  final servida =
                                      mismoNombreAntes <
                                      totalServidasDeEsteNombre;

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 3,
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  '1 $nombre',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: servida
                                                        ? Colors.grey.shade400
                                                        : Colors.black87,
                                                    decoration: servida
                                                        ? TextDecoration
                                                              .lineThrough
                                                        : TextDecoration.none,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 7,
                                                      vertical: 2,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                    0xFFFEF3C7,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color: const Color(
                                                      0xFFFBBF24,
                                                    ),
                                                    width: 1,
                                                  ),
                                                ),
                                                child: const Text(
                                                  '💰 adicional',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF92400E),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        GestureDetector(
                                          onTap: procesandoEsta
                                              ? null
                                              : () async {
                                                  if (_procesando.contains(key))
                                                    return;
                                                  setModalState(
                                                    () => _procesando.add(key),
                                                  );
                                                  try {
                                                    await ApiService.servirEntrada(
                                                      order.id,
                                                      nombre,
                                                      !servida,
                                                    );
                                                    if (ctx.mounted) {
                                                      ctx.read<CantadorBloc>().add(
                                                        const RefreshCantadorData(),
                                                      );
                                                    }
                                                  } catch (error) {
                                                    debugPrint(
                                                      'Error al servir entrada adicional: $error',
                                                    );
                                                  } finally {
                                                    if (ctx.mounted) {
                                                      setModalState(
                                                        () => _procesando
                                                            .remove(key),
                                                      );
                                                    }
                                                  }
                                                },
                                          child: AnimatedContainer(
                                            duration: const Duration(
                                              milliseconds: 150,
                                            ),
                                            width: 22,
                                            height: 22,
                                            decoration: BoxDecoration(
                                              color: servida
                                                  ? const Color(0xFF1D9E75)
                                                  : Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(5),
                                              border: Border.all(
                                                color: servida
                                                    ? const Color(0xFF1D9E75)
                                                    : Colors.grey.shade400,
                                                width: 1.5,
                                              ),
                                            ),
                                            child: procesandoEsta
                                                ? const Padding(
                                                    padding: EdgeInsets.all(3),
                                                    child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          color: Colors.white,
                                                        ),
                                                  )
                                                : servida
                                                ? const Icon(
                                                    Icons.check,
                                                    size: 14,
                                                    color: Colors.white,
                                                  )
                                                : null,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                              const SizedBox(height: 12),
                            ],
                            if (segundosList.isNotEmpty) ...[
                              _buildSectionLabel('SEGUNDOS'),
                              ...segundosList.map(
                                (s) => _buildItemRow(
                                  name: '1 ${s.nombre}',
                                  servido: s.servido,
                                  procesando: _procesando.contains(
                                    'segundo_${s.key}',
                                  ),
                                  onTap: () async {
                                    final key = 'segundo_${s.key}';
                                    // Si ya está procesando o ya está servido, no hacemos nada
                                    if (_procesando.contains(key) || s.servido)
                                      return;

                                    // Activamos el spinner en el modal
                                    setModalState(() => _procesando.add(key));

                                    try {
                                      await ApiService.serveItemById(
                                        s.orderItemId,
                                      );
                                      if (ctx.mounted) {
                                        ctx.read<CantadorBloc>().add(
                                          const RefreshCantadorData(),
                                        );
                                      }
                                    } catch (error) {
                                      debugPrint(
                                        "Error al servir segundo: $error",
                                      );
                                    } finally {
                                      if (ctx.mounted) {
                                        // Quitamos el spinner en el modal
                                        setModalState(
                                          () => _procesando.remove(key),
                                        );
                                      }
                                    }
                                  },
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                        child: SizedBox(
                          width: double.infinity,
                          child: GestureDetector(
                            onTap: () {
                              Navigator.of(ctx).pop();
                              _onTodoListoTap(order);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE1F5EE),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFF1D9E75),
                                  width: 1,
                                ),
                              ),
                              child: const Text(
                                '✓  Todo listo',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F6E56),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3, top: 2),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _buildItemRow({
    required String name,
    required bool servido,
    required bool procesando,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontSize: 12,
                color: servido ? Colors.grey.shade400 : Colors.black87,
                decoration: servido
                    ? TextDecoration.lineThrough
                    : TextDecoration.none,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: procesando ? null : onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: servido ? const Color(0xFF1D9E75) : Colors.white,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                  color: servido
                      ? const Color(0xFF1D9E75)
                      : Colors.grey.shade400,
                  width: 1.5,
                ),
              ),
              child: procesando
                  ? const Padding(
                      padding: EdgeInsets.all(3),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : servido
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(bool wasSung) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: wasSung ? const Color(0xFFEEEDFE) : const Color(0xFFFAEEDA),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        wasSung ? 'en cocina' : 'nuevo',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: wasSung ? const Color(0xFF3C3489) : const Color(0xFF854F0B),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // ACCIONES MESAS
  // ─────────────────────────────────────────────

  Future<void> _onEntradaTap(_EntradaIndividual e, CantadorOrder order) async {
    final key = 'entrada_${e.key}';
    if (_procesando.contains(key)) return;

    final nuevoEstado = !e.servida;
    setState(() => _procesando.add(key));

    try {
      await ApiService.servirEntrada(order.id, e.nombre, nuevoEstado);
      if (mounted) {
        context.read<CantadorBloc>().add(const RefreshCantadorData());
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _procesando.remove(key));
    }
  }

  Future<void> _onSegundoTap(_SegundoIndividual s, CantadorOrder order) async {
    final key = 'segundo_${s.key}';
    if (_procesando.contains(key) || s.servido) return;

    setState(() => _procesando.add(key));

    try {
      await ApiService.serveItemById(s.orderItemId);
      if (mounted) {
        context.read<CantadorBloc>().add(const RefreshCantadorData());
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _procesando.remove(key));
    }
  }

  Future<void> _onTodoListoTap(CantadorOrder order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Mesa ${order.tableNumber} — todo listo'),
        content: const Text(
          '¿Confirmas que todos los platos de esta mesa fueron entregados?',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1D9E75),
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ApiService.updateOrderStatus(order.id, 'Listo');
      if (mounted) {
        context.read<CantadorBloc>().add(const RefreshCantadorData());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ Mesa ${order.tableNumber} marcada como lista'),
            backgroundColor: const Color(0xFF1D9E75),
            duration: const Duration(milliseconds: 1500),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(12),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showDetalleDialog(CantadorOrder order, CantadorLoaded state) {
    final entradasList = _parsearEntradasIndividuales(
      order.entradas ?? '',
      order.entradasServidas,
    );
    final segundosList = _expandirItems(order.items, order.id);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Mesa ${order.tableNumber.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(ctx).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              Text(
                order.waiterName ?? 'Mozo',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
              ),
              const Divider(height: 20),
              if (entradasList.isNotEmpty) ...[
                const Text(
                  'ENTRADAS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 6),
                ...entradasList.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Icon(
                          e.servida
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          size: 16,
                          color: e.servida
                              ? const Color(0xFF1D9E75)
                              : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '1 ${e.nombre}',
                          style: TextStyle(
                            fontSize: 14,
                            color: e.servida ? Colors.grey : Colors.black87,
                            decoration: e.servida
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              if (segundosList.isNotEmpty) ...[
                const Text(
                  'SEGUNDOS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 6),
                ...segundosList.map(
                  (s) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Icon(
                          s.servido
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          size: 16,
                          color: s.servido
                              ? const Color(0xFF1D9E75)
                              : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '1 ${s.nombre}',
                          style: TextStyle(
                            fontSize: 14,
                            color: s.servido ? Colors.grey : Colors.black87,
                            decoration: s.servido
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // HELPERS DE DATOS
  // ─────────────────────────────────────────────

  /// Expande las entradas en filas individuales y marca cuáles ya fueron servidas
  List<_EntradaIndividual> _parsearEntradasIndividuales(
    String entradasRaw,
    List<String> entradasServidas,
  ) {
    final result = <_EntradaIndividual>[];
    if (entradasRaw.isEmpty) return result;

    final lineas = entradasRaw
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty && l != '🔸 NUEVO:')
        .toList();

    final List<String> nombres = [];
    for (final linea in lineas) {
      final match = RegExp(r'^(\d+)x\s+(.+)$').firstMatch(linea);
      if (match != null) {
        final qty = int.parse(match.group(1)!);
        final nombre = match.group(2)!.trim();
        for (int i = 0; i < qty; i++) {
          nombres.add(nombre);
        }
      } else {
        nombres.add(linea);
      }
    }

    // Contar cuántas están servidas por nombre
    final servidasCopy = List<String>.from(
      entradasServidas.map((s) => s.toLowerCase().trim()),
    );

    for (int i = 0; i < nombres.length; i++) {
      final nombre = nombres[i];
      final nombreNorm = nombre.toLowerCase().trim();
      final idx = servidasCopy.indexOf(nombreNorm);
      final servida = idx >= 0;
      if (servida) servidasCopy.removeAt(idx);

      result.add(
        _EntradaIndividual(
          key: '${nombre}_$i',
          nombre: nombre,
          servida: servida,
        ),
      );
    }

    return result;
  }

  /// Expande los items en filas individuales (1 fila por unidad)
  List<_SegundoIndividual> _expandirItems(
    List<CantadorOrderItem> items,
    int orderId,
  ) {
    final result = <_SegundoIndividual>[];
    for (final item in items) {
      for (int i = 0; i < item.quantity; i++) {
        final servido = i < item.servedQuantity;
        result.add(
          _SegundoIndividual(
            key: '${item.id}_$i',
            orderItemId: item.id,
            nombre: item.productName,
            servido: servido,
            individualIndex: i,
          ),
        );
      }
    }
    return result;
  }
}

// ─────────────────────────────────────────────
// MODELOS INTERNOS
// ─────────────────────────────────────────────

class _EntradaEntry {
  final String key;
  final int orderId;
  final String entradaName;
  final int tableNumber;
  final String waiterName;
  final bool isParaLlevar;

  _EntradaEntry({
    required this.key,
    required this.orderId,
    required this.entradaName,
    required this.tableNumber,
    required this.waiterName,
    required this.isParaLlevar,
  });
}

class _GroupedDish {
  final int productId;
  final String productName;
  final List<_OrderEntry> entries;

  _GroupedDish({
    required this.productId,
    required this.productName,
    required this.entries,
  });

  int totalPending(Set<String> servidos) {
    return entries.where((e) {
      final k = '${e.orderItemId}_${e.individualIndex}';
      return !servidos.contains(k);
    }).length;
  }
}

class _OrderEntry {
  final int orderId;
  final int orderItemId;
  final String waiterName;
  final int tableNumber;
  final bool isParaLlevar;
  final int individualIndex;

  _OrderEntry({
    required this.orderId,
    required this.orderItemId,
    required this.waiterName,
    required this.tableNumber,
    required this.isParaLlevar,
    required this.individualIndex,
  });
}

class _EntradaIndividual {
  final String key;
  final String nombre;
  final bool servida;

  _EntradaIndividual({
    required this.key,
    required this.nombre,
    required this.servida,
  });
}

class _SegundoIndividual {
  final String key;
  final int orderItemId;
  final String nombre;
  final bool servido;
  final int individualIndex;

  _SegundoIndividual({
    required this.key,
    required this.orderItemId,
    required this.nombre,
    required this.servido,
    required this.individualIndex,
  });
}
