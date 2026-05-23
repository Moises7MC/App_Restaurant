import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../services/api_service.dart';
import '../bloc/cantador_bloc.dart';
import '../bloc/cantador_event.dart';
import '../bloc/cantador_state.dart';
import '../../data/services/piso_resolver.dart';

class PisoTabsPage extends StatefulWidget {
  final PisoResolver pisoResolver;
  const PisoTabsPage({super.key, required this.pisoResolver});

  @override
  State<PisoTabsPage> createState() => _PisoTabsPageState();
}

class _PisoTabsPageState extends State<PisoTabsPage> {
  int _selectedPiso = 0;
  int _selectedSubTab = 1;
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
                    : _buildSegundosContent(state),
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
  // SUB TABS
  // ─────────────────────────────────────────────

  Widget _buildSubTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [_buildSubTab(0, 'Entradas'), _buildSubTab(1, 'Segundos')],
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
  // ENTRADAS
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
          if (trimmed.isEmpty) continue;

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

    // ✅ Sincronizar estado local con backend — respetando cantidad por unidad
    for (final order in pisoOrders) {
      // Contar cuántas de cada entrada están servidas en el backend
      final conteoServidas = <String, int>{};
      for (final servida in order.entradasServidas) {
        final k = servida.toLowerCase().trim();
        conteoServidas[k] = (conteoServidas[k] ?? 0) + 1;
      }

      // Marcar solo las unidades que corresponden según el conteo
      for (final entries in grouped.values) {
        for (final entry in entries) {
          if (entry.orderId != order.id) continue;
          final k = entry.entradaName.toLowerCase().trim();
          final servidasCount = conteoServidas[k] ?? 0;
          if (servidasCount > 0) {
            _servidosEntradas.add(entry.key);
            conteoServidas[k] = servidasCount - 1;
          }
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
                : 'Mesa ${entry.tableNumber} - ${entry.waiterName}'
                      '${entry.isParaLlevar ? ' 🛍' : ''}',
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
              // ✅ Agregar este print para verificar
              debugPrint(
                '📡 Llamando servirEntrada: orderId=${entry.orderId}, entrada=${entry.entradaName}, servida=$nuevoEstado',
              );

              await ApiService.servirEntrada(
                entry.orderId,
                entry.entradaName,
                nuevoEstado,
              );

              debugPrint('✅ servirEntrada OK');

              if (mounted) {
                context.read<CantadorBloc>().add(const RefreshCantadorData());
              }
            } catch (e) {
              debugPrint('❌ servirEntrada ERROR: $e');
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
  // SEGUNDOS
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
                : 'Mesa ${entry.tableNumber} - ${entry.waiterName}'
                      '${entry.isParaLlevar ? ' 🛍' : ''}',
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
}

// ─────────────────────────────────────────────
// MODELOS
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
