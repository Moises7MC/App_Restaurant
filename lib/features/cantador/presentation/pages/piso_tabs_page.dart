import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../services/api_service.dart';
import '../bloc/cantador_bloc.dart';
import '../bloc/cantador_event.dart';
import '../bloc/cantador_state.dart';
import '../../data/services/piso_resolver.dart';

/// Pantalla principal del cantador (versión "Por pisos").
///
/// Estructura:
///   - 2 tabs grandes: Piso 1 / Piso 2 (amber el activo)
///   - 2 sub-tabs debajo: Entradas / Segundos (negrita el activo)
///   - Lista de platos colapsables (acordeones)
///   - Cada plato muestra "(N)" = pendientes
///   - Al expandir, lista de pedidos individuales con checkbox
///
/// Por defecto abre Piso 1 → Segundos (lo más usado).
class PisoTabsPage extends StatefulWidget {
  final PisoResolver pisoResolver;

  const PisoTabsPage({super.key, required this.pisoResolver});

  @override
  State<PisoTabsPage> createState() => _PisoTabsPageState();
}

class _PisoTabsPageState extends State<PisoTabsPage> {
  int _selectedPiso = 0; // 0 = Piso 1, 1 = Piso 2
  int _selectedSubTab = 1; // 0 = Entradas, 1 = Segundos (default)

  /// Set de OrderItem.id ya servidos (segundos) — solo en memoria
  final Set<int> _servidosSegundos = {};

  /// Set de "orderId|entradaName" ya servidos (entradas) — solo en memoria
  final Set<String> _servidosEntradas = {};

  /// Set de productIds expandidos en segundos
  final Set<int> _expandedSegundos = {};

  /// Set de nombres de entradas expandidas
  final Set<String> _expandedEntradas = {};

  /// Items que están siendo procesados (para evitar doble-click)
  final Set<int> _procesando = {};

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CantadorBloc, CantadorState>(
      builder: (context, state) {
        if (state is CantadorLoading || state is CantadorInitial) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is CantadorError) {
          return _buildError(context, state.message);
        }
        if (state is! CantadorLoaded) {
          return const SizedBox.shrink();
        }

        return Column(
          children: [
            // Tabs de piso
            _buildPisoTabs(),

            const SizedBox(height: 16),

            // Sub-tabs Entradas / Segundos
            _buildSubTabs(),

            const SizedBox(height: 12),

            // Contenido
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  context.read<CantadorBloc>().add(const RefreshCantadorData());
                  await Future.delayed(const Duration(milliseconds: 600));
                },
                child: _selectedSubTab == 0
                    ? _buildEntradasContent(context, state)
                    : _buildSegundosContent(context, state),
              ),
            ),
          ],
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════
  // TABS DE PISO
  // ═══════════════════════════════════════════════════

  Widget _buildPisoTabs() {
    final pisos = widget.pisoResolver.floors;

    if (pisos.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: List.generate(pisos.length, (i) {
          final isSelected = _selectedPiso == i;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i < pisos.length - 1 ? 8 : 0),
              child: GestureDetector(
                onTap: () => setState(() => _selectedPiso = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: 44,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFFFC107) // amber
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    pisos[i].floorName,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // SUB-TABS Entradas / Segundos
  // ═══════════════════════════════════════════════════

  Widget _buildSubTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedSubTab = 0),
              child: Column(
                children: [
                  Text(
                    'Entradas',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: _selectedSubTab == 0
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: _selectedSubTab == 0
                          ? Colors.black
                          : Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 2,
                    color: _selectedSubTab == 0
                        ? Colors.black
                        : Colors.transparent,
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedSubTab = 1),
              child: Column(
                children: [
                  Text(
                    'Segundos',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: _selectedSubTab == 1
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: _selectedSubTab == 1
                          ? Colors.black
                          : Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 2,
                    color: _selectedSubTab == 1
                        ? Colors.black
                        : Colors.transparent,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // CONTENIDO: SEGUNDOS
  // ═══════════════════════════════════════════════════

  Widget _buildSegundosContent(BuildContext context, CantadorLoaded state) {
    // Filtrar órdenes del piso seleccionado
    final pisoOrders = state.activeOrders.where((o) {
      return widget.pisoResolver.getFloorIndex(o.tableNumber) == _selectedPiso;
    }).toList();

    // Agrupar items por productId
    final grouped = <int, _GroupedDish>{};
    for (final order in pisoOrders) {
      for (final item in order.items) {
        final pendingQty = item.pendingQuantity;
        if (pendingQty <= 0) continue;
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
            quantity: pendingQty,
            isParaLlevar: order.isParaLlevar,
          ),
        );
      }
    }

    if (grouped.isEmpty) {
      return _buildEmpty('Sin segundos pendientes');
    }

    final dishes = grouped.values.toList()
      ..sort(
        (a, b) => b
            .totalPending(_servidosSegundos)
            .compareTo(a.totalPending(_servidosSegundos)),
      );

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
      itemCount: dishes.length,
      itemBuilder: (_, i) => _buildSegundoCard(dishes[i]),
    );
  }

  Widget _buildSegundoCard(_GroupedDish dish) {
    final isExpanded = _expandedSegundos.contains(dish.productId);
    final pending = dish.totalPending(_servidosSegundos);

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedSegundos.remove(dish.productId);
                } else {
                  _expandedSegundos.add(dish.productId);
                }
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                children: [
                  Icon(
                    isExpanded ? Icons.arrow_drop_down : Icons.arrow_right,
                    size: 22,
                    color: Colors.black87,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${dish.productName} ($pending)',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 14, 12),
              child: Column(
                children: dish.entries
                    .map((entry) => _buildSegundoEntry(entry))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSegundoEntry(_OrderEntry entry) {
    final isServido = _servidosSegundos.contains(entry.orderItemId);
    final isProcessing = _procesando.contains(entry.orderItemId);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Text(
            '•',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Pedidos: ${entry.quantity.toString().padLeft(2, '0')} - '
              'Mozo: ${entry.waiterName} - '
              'Mesa: ${entry.tableNumber}'
              '${entry.isParaLlevar ? ' 🛍' : ''}',
              style: TextStyle(
                fontSize: 13,
                color: isServido ? Colors.grey.shade400 : Colors.black87,
                decoration: isServido
                    ? TextDecoration.lineThrough
                    : TextDecoration.none,
              ),
            ),
          ),
          GestureDetector(
            onTap: isProcessing ? null : () => _toggleSegundo(entry),
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isServido ? const Color(0xFFFFC107) : Colors.white,
                border: Border.all(color: const Color(0xFFFFC107), width: 2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: isProcessing
                  ? const Padding(
                      padding: EdgeInsets.all(3),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFFFFC107),
                      ),
                    )
                  : isServido
                  ? const Icon(Icons.check, size: 18, color: Colors.white)
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleSegundo(_OrderEntry entry) async {
    final messenger = ScaffoldMessenger.of(context);
    final isServido = _servidosSegundos.contains(entry.orderItemId);

    if (isServido) {
      // Destachar — solo visual (no se llama al backend)
      setState(() => _servidosSegundos.remove(entry.orderItemId));
      return;
    }

    // Tachar y enviar al backend N veces (descontar todas las unidades)
    setState(() {
      _servidosSegundos.add(entry.orderItemId);
      _procesando.add(entry.orderItemId);
    });

    try {
      // Llamar serveItemById N veces (uno por unidad pendiente)
      for (int i = 0; i < entry.quantity; i++) {
        await ApiService.serveItemById(entry.orderItemId);
      }

      if (!mounted) return;

      messenger.showSnackBar(
        SnackBar(
          content: Text('✓ ${entry.quantity}x servido(s)'),
          backgroundColor: const Color(0xFF1D9E75),
          duration: const Duration(milliseconds: 800),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(12),
        ),
      );

      // Refrescar datos del backend
      // ignore: use_build_context_synchronously
      context.read<CantadorBloc>().add(const RefreshCantadorData());
    } catch (e) {
      if (!mounted) return;
      // Revertir el tachado si falló
      setState(() => _servidosSegundos.remove(entry.orderItemId));
      messenger.showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _procesando.remove(entry.orderItemId));
      }
    }
  }

  // ═══════════════════════════════════════════════════
  // CONTENIDO: ENTRADAS
  // ═══════════════════════════════════════════════════

  Widget _buildEntradasContent(BuildContext context, CantadorLoaded state) {
    final pisoOrders = state.activeOrders.where((o) {
      return widget.pisoResolver.getFloorIndex(o.tableNumber) == _selectedPiso;
    }).toList();

    final grouped = <String, _GroupedEntrada>{};
    for (final order in pisoOrders) {
      if (order.entradas == null || order.entradas!.trim().isEmpty) continue;
      final parsed = _parseEntradas(order.entradas!);
      for (final p in parsed) {
        final key = p.name.toLowerCase().trim();
        grouped.putIfAbsent(
          key,
          () => _GroupedEntrada(name: p.name, entries: []),
        );
        grouped[key]!.entries.add(
          _EntradaEntry(
            orderId: order.id,
            entradaName: p.name,
            waiterName: order.waiterName ?? 'Mozo',
            tableNumber: order.tableNumber,
            quantity: p.quantity,
            isParaLlevar: order.isParaLlevar,
          ),
        );
      }
    }

    if (grouped.isEmpty) {
      return _buildEmpty('Sin entradas pendientes');
    }

    final entradas = grouped.values.toList()
      ..sort(
        (a, b) => b
            .totalPending(_servidosEntradas)
            .compareTo(a.totalPending(_servidosEntradas)),
      );

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
      itemCount: entradas.length,
      itemBuilder: (_, i) => _buildEntradaCard(entradas[i]),
    );
  }

  Widget _buildEntradaCard(_GroupedEntrada entrada) {
    final key = entrada.name.toLowerCase().trim();
    final isExpanded = _expandedEntradas.contains(key);
    final pending = entrada.totalPending(_servidosEntradas);

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedEntradas.remove(key);
                } else {
                  _expandedEntradas.add(key);
                }
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                children: [
                  Icon(
                    isExpanded ? Icons.arrow_drop_down : Icons.arrow_right,
                    size: 22,
                    color: Colors.black87,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${entrada.name} ($pending)',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 14, 12),
              child: Column(
                children: entrada.entries
                    .map((entry) => _buildEntradaEntry(entry))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEntradaEntry(_EntradaEntry entry) {
    final servidoKey =
        '${entry.orderId}|${entry.entradaName.toLowerCase().trim()}';
    final isServido = _servidosEntradas.contains(servidoKey);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Text(
            '•',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Pedidos: ${entry.quantity.toString().padLeft(2, '0')} - '
              'Mozo: ${entry.waiterName} - '
              'Mesa: ${entry.tableNumber}'
              '${entry.isParaLlevar ? ' 🛍' : ''}',
              style: TextStyle(
                fontSize: 13,
                color: isServido ? Colors.grey.shade400 : Colors.black87,
                decoration: isServido
                    ? TextDecoration.lineThrough
                    : TextDecoration.none,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                if (isServido) {
                  _servidosEntradas.remove(servidoKey);
                } else {
                  _servidosEntradas.add(servidoKey);
                }
              });
            },
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isServido ? const Color(0xFFFFC107) : Colors.white,
                border: Border.all(color: const Color(0xFFFFC107), width: 2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: isServido
                  ? const Icon(Icons.check, size: 18, color: Colors.white)
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  /// Parsea el string Entradas de una orden.
  /// Soporta "2x sopa de fideos, 1x ensalada" → [(sopa, 2), (ensalada, 1)]
  /// y también "sopa x2, ensalada x1" (sufijo)
  List<_ParsedEntrada> _parseEntradas(String raw) {
    final result = <_ParsedEntrada>[];
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return result;

    final parts = trimmed.split(RegExp(r'[,;]'));
    for (final part in parts) {
      var item = part.trim();
      if (item.isEmpty) continue;

      int qty = 1;

      // Buscar "Nx prefijo"
      final prefixMatch = RegExp(
        r'^\s*(\d+)\s*x\s+(.+)$',
        caseSensitive: false,
      ).firstMatch(item);

      if (prefixMatch != null) {
        qty = int.parse(prefixMatch.group(1)!);
        item = prefixMatch.group(2)!.trim();
      } else {
        // Buscar "nombre xN" al final
        final suffixMatch = RegExp(
          r'(.+?)\s*x\s*(\d+)\s*$',
          caseSensitive: false,
        ).firstMatch(item);
        if (suffixMatch != null) {
          qty = int.parse(suffixMatch.group(2)!);
          item = suffixMatch.group(1)!.trim();
        }
      }

      if (item.isEmpty) continue;
      result.add(_ParsedEntrada(name: item, quantity: qty));
    }
    return result;
  }

  // ═══════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════

  Widget _buildEmpty(String message) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 80),
        Center(
          child: Column(
            children: [
              const Text('🍽️', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 12),
              Text(
                message,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildError(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 56, color: Colors.red),
            const SizedBox(height: 12),
            Text(
              'Error al cargar datos',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              onPressed: () {
                context.read<CantadorBloc>().add(const LoadCantadorData());
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
// MODELOS LOCALES
// ═══════════════════════════════════════════════════

class _GroupedDish {
  final int productId;
  final String productName;
  final List<_OrderEntry> entries;

  _GroupedDish({
    required this.productId,
    required this.productName,
    required this.entries,
  });

  int totalPending(Set<int> servidos) {
    return entries.fold(0, (sum, e) {
      if (servidos.contains(e.orderItemId)) return sum;
      return sum + e.quantity;
    });
  }
}

class _OrderEntry {
  final int orderId;
  final int orderItemId;
  final String waiterName;
  final int tableNumber;
  final int quantity;
  final bool isParaLlevar;

  _OrderEntry({
    required this.orderId,
    required this.orderItemId,
    required this.waiterName,
    required this.tableNumber,
    required this.quantity,
    required this.isParaLlevar,
  });
}

class _GroupedEntrada {
  final String name;
  final List<_EntradaEntry> entries;

  _GroupedEntrada({required this.name, required this.entries});

  int totalPending(Set<String> servidos) {
    return entries.fold(0, (sum, e) {
      final key = '${e.orderId}|${e.entradaName.toLowerCase().trim()}';
      if (servidos.contains(key)) return sum;
      return sum + e.quantity;
    });
  }
}

class _EntradaEntry {
  final int orderId;
  final String entradaName;
  final String waiterName;
  final int tableNumber;
  final int quantity;
  final bool isParaLlevar;

  _EntradaEntry({
    required this.orderId,
    required this.entradaName,
    required this.waiterName,
    required this.tableNumber,
    required this.quantity,
    required this.isParaLlevar,
  });
}

class _ParsedEntrada {
  final String name;
  final int quantity;
  _ParsedEntrada({required this.name, required this.quantity});
}
