import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../bloc/cantador_bloc.dart';
import '../bloc/cantador_event.dart';
import '../bloc/cantador_state.dart';
import '../../domain/entities/cantador_order.dart';
import '../widgets/cantador_colors.dart';

/// Tab "POR MESA" — vista detallada del cantador.
///
/// Dos secciones:
///   1. NUEVOS · cantar al chef (cards amber)
///   2. EN COCINA · descontando (cards blancas con cronómetro)
class ByTableTab extends StatelessWidget {
  const ByTableTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CantadorBloc, CantadorState>(
      builder: (context, state) {
        if (state is CantadorLoading || state is CantadorInitial) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is! CantadorLoaded) {
          return const SizedBox.shrink();
        }

        // ✅ FIX: Solo mostrar órdenes que tengan AL MENOS un plato pendiente.
        //    Si el cantador descontó todos antes de "cantar al chef", la orden
        //    ya tiene status "Listo" en BD y no aparecerá aquí (porque solo
        //    cargamos órdenes Pendiente/Enviado a cocina).
        //    Pero por seguridad, también filtramos en cliente.
        final activeWithPending = state.activeOrders
            .where((o) => o.pendingDishes > 0)
            .toList();

        final nuevos = activeWithPending.where((o) => !o.wasSung).toList();
        final enCocina = activeWithPending.where((o) => o.wasSung).toList();

        if (nuevos.isEmpty && enCocina.isEmpty) {
          return _buildEmpty();
        }

        return RefreshIndicator(
          onRefresh: () async {
            context.read<CantadorBloc>().add(const RefreshCantadorData());
            await Future.delayed(const Duration(milliseconds: 600));
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(12),
            children: [
              // ════════════════════════════════════════════
              // SECCIÓN 1: NUEVOS · cantar al chef
              // ════════════════════════════════════════════
              if (nuevos.isNotEmpty) ...[
                _buildSectionHeader(
                  icon: '🆕',
                  title: 'NUEVOS · cantar al chef',
                  count: nuevos.length,
                  countColor: CantadorColors.entradaCircle,
                  countBg: CantadorColors.entradaBg,
                ),
                const SizedBox(height: 10),
                _buildNuevosGrid(context, nuevos),
                const SizedBox(height: 18),
              ],

              // ════════════════════════════════════════════
              // SECCIÓN 2: EN COCINA · descontando
              // ════════════════════════════════════════════
              if (enCocina.isNotEmpty) ...[
                _buildSectionHeader(
                  icon: '🍳',
                  title: 'EN COCINA · descontando',
                  count: enCocina.length,
                  countColor: CantadorColors.primary,
                  countBg: const Color(0xFFEEEDFE),
                ),
                const SizedBox(height: 10),
                _buildEnCocinaGrid(context, enCocina),
              ],
            ],
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════
  // SECCIÓN NUEVOS
  // ═══════════════════════════════════════════════════

  Widget _buildNuevosGrid(BuildContext context, List<CantadorOrder> nuevos) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 360,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.95,
      ),
      itemCount: nuevos.length,
      itemBuilder: (context, i) => _buildNuevoCard(context, nuevos[i]),
    );
  }

  Widget _buildNuevoCard(BuildContext context, CantadorOrder order) {
    // ✅ FIX: separar items en pendientes y servidos para mostrarlos diferente
    final pendingItems = order.items.where((i) => !i.isFullyServed).toList();
    final servedItems = order.items.where((i) => i.isFullyServed).toList();

    return Container(
      decoration: BoxDecoration(
        color: CantadorColors.entradaBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CantadorColors.entradaBorder, width: 1.5),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Mesa + badge "Para llevar" + hora + mozo
          Row(
            children: [
              Text(
                'Mesa ${order.tableNumber.toString().padLeft(2, '0')}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: CantadorColors.entradaTextDark,
                ),
              ),
              if (order.isParaLlevar) ...[
                const SizedBox(width: 6),
                _paraLlevarBadge(),
              ],
              const Spacer(),
              Text(
                _fmtTime(order.createdAt),
                style: const TextStyle(
                  fontSize: 11,
                  color: CantadorColors.entradaTextMid,
                ),
              ),
              if (order.waiterName != null) ...[
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    '· ${order.waiterName}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: CantadorColors.entradaTextMid,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),

          // ENTRADAS (cortesías del campo Order.Entradas)
          if (order.entradas != null && order.entradas!.trim().isNotEmpty) ...[
            const Text(
              'ENTRADAS',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.4,
                color: CantadorColors.entradaTextMid,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              order.entradas!,
              style: const TextStyle(
                fontSize: 13,
                color: CantadorColors.entradaTextDark,
              ),
            ),
            const SizedBox(height: 8),
          ],

          // SEGUNDOS — pendientes en negrita, servidos tachados
          if (order.items.isNotEmpty) ...[
            const Text(
              'SEGUNDOS',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.4,
                color: CantadorColors.entradaTextMid,
              ),
            ),
            const SizedBox(height: 3),
            // ✅ FIX: usar pendingQuantity en lugar de quantity
            //    y separar servidos como tachados
            ..._buildItemsList(pendingItems, servedItems),
            const SizedBox(height: 10),
          ],

          const Spacer(),

          // Botón "Cantado al chef"
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.check, size: 16),
              label: const Text('cantado al chef'),
              onPressed: () => _onCantadoTap(context, order),
              style: ElevatedButton.styleFrom(
                backgroundColor: CantadorColors.entradaCircle,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Construye la lista de items: pendientes con [-], servidos tachados.
  /// Se usa SOLO en la card de NUEVOS para que el cantador vea estado claro.
  List<Widget> _buildItemsList(
    List<CantadorOrderItem> pending,
    List<CantadorOrderItem> served,
  ) {
    final widgets = <Widget>[];

    // Items pendientes con [-] al lado
    for (final item in pending) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${item.pendingQuantity}x',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: CantadorColors.entradaTextDark,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  item.productName,
                  style: const TextStyle(
                    fontSize: 13,
                    color: CantadorColors.entradaTextDark,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Items ya servidos (tachados)
    for (final item in served) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: CantadorColors.segundoBg,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '✓',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: CantadorColors.segundoCircle,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${item.quantity}x ${item.productName}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return widgets;
  }

  Future<void> _onCantadoTap(BuildContext context, CantadorOrder order) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      context.read<CantadorBloc>().add(MarkAsSungEvent(order.id));
      messenger.showSnackBar(
        SnackBar(
          content: Text('✓ Mesa ${order.tableNumber} pasó a cocina'),
          backgroundColor: CantadorColors.primary,
          duration: const Duration(milliseconds: 1200),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(12),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  // ═══════════════════════════════════════════════════
  // SECCIÓN EN COCINA
  // ═══════════════════════════════════════════════════

  Widget _buildEnCocinaGrid(
    BuildContext context,
    List<CantadorOrder> enCocina,
  ) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 280,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.95,
      ),
      itemCount: enCocina.length,
      itemBuilder: (context, i) => _buildEnCocinaCard(context, enCocina[i]),
    );
  }

  Widget _buildEnCocinaCard(BuildContext context, CantadorOrder order) {
    final pendingItems = order.items.where((i) => !i.isFullyServed).toList();
    final servedItems = order.items.where((i) => i.isFullyServed).toList();

    final tiempoColor = _getTiempoColor(order.minutesInKitchen);
    final tiempoBg = _getTiempoBg(order.minutesInKitchen);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.5),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Mesa + cronómetro
          Row(
            children: [
              Text(
                'Mesa ${order.tableNumber.toString().padLeft(2, '0')}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (order.isParaLlevar) ...[
                const SizedBox(width: 4),
                _paraLlevarBadge(small: true),
              ],
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: tiempoBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.access_time, size: 11, color: tiempoColor),
                    const SizedBox(width: 3),
                    Text(
                      '${order.minutesInKitchen}min',
                      style: TextStyle(
                        fontSize: 10,
                        color: tiempoColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (order.waiterName != null) ...[
            const SizedBox(height: 2),
            Text(
              order.waiterName!,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
            ),
          ],

          const SizedBox(height: 8),
          Container(height: 0.5, color: AppColors.border),
          const SizedBox(height: 6),

          // ENTRADAS (cortesías) si las hay
          if (order.entradas != null && order.entradas!.trim().isNotEmpty) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('🥣', style: TextStyle(fontSize: 11)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    order.entradas!,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
          ],

          // Lista de items pendientes (con [-]) + servidos (tachados)
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ...pendingItems.map(
                  (item) => _buildItemRowEnCocina(context, item, false),
                ),
                ...servedItems.map(
                  (item) => _buildItemRowEnCocina(context, item, true),
                ),
              ],
            ),
          ),

          if (pendingItems.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Faltan: ${order.pendingDishes} platos',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: CantadorColors.segundoCircle,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildItemRowEnCocina(
    BuildContext context,
    CantadorOrderItem item,
    bool isServed,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          // Badge cantidad / check
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isServed ? CantadorColors.segundoBg : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(4),
            ),
            child: isServed
                ? const Text(
                    '✓',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: CantadorColors.segundoCircle,
                    ),
                  )
                : Text(
                    '${item.pendingQuantity}x',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              item.productName,
              style: TextStyle(
                fontSize: 12,
                color: isServed ? Colors.grey.shade400 : null,
                decoration: isServed
                    ? TextDecoration.lineThrough
                    : TextDecoration.none,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (!isServed)
            GestureDetector(
              onTap: () => _onServeItemTap(context, item),
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.remove,
                  size: 14,
                  color: Colors.black54,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _onServeItemTap(
    BuildContext context,
    CantadorOrderItem item,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      context.read<CantadorBloc>().add(ServeOrderItemEvent(item.id));
      messenger.showSnackBar(
        SnackBar(
          content: Text('✓ ${item.productName} servido'),
          backgroundColor: CantadorColors.segundoCircle,
          duration: const Duration(milliseconds: 800),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(12),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  // ═══════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════

  Widget _buildSectionHeader({
    required String icon,
    required String title,
    required int count,
    required Color countColor,
    required Color countBg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.4,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: countBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                color: countColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _paraLlevarBadge({bool small = false}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 5 : 7,
        vertical: small ? 1 : 2,
      ),
      decoration: BoxDecoration(
        color: CantadorColors.paraLlevarBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        small ? '🛍' : '🛍 llevar',
        style: TextStyle(
          fontSize: small ? 9 : 10,
          color: CantadorColors.paraLlevarText,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getTiempoColor(int minutes) {
    if (minutes < 10) return CantadorColors.tiempoVerde;
    if (minutes < 20) return CantadorColors.tiempoNaranja;
    return CantadorColors.tiempoRojo;
  }

  Color _getTiempoBg(int minutes) {
    if (minutes < 10) return CantadorColors.segundoBg;
    if (minutes < 20) return CantadorColors.entradaBg;
    return CantadorColors.canceladoBg;
  }

  String _fmtTime(DateTime dt) {
    final l = dt.toLocal();
    return '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🍽️', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 12),
          Text(
            'Sin órdenes activas',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Cuando los mozos envíen pedidos, aparecerán aquí',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}
