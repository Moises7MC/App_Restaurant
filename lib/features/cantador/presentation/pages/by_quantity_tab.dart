import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../bloc/cantador_bloc.dart';
import '../bloc/cantador_event.dart';
import '../bloc/cantador_state.dart';
import '../../domain/entities/aggregated_dish.dart';
import '../../domain/entities/aggregated_entrada.dart';
import '../widgets/cantador_colors.dart';

/// Tab "POR CANTIDADES" — vista por defecto del cantador.
///
/// Muestra entradas (amber) y segundos (teal) agregados de todas las mesas
/// con un botón [-] grande para descontar al servir.
class ByQuantityTab extends StatelessWidget {
  const ByQuantityTab({super.key});

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

        if (state.aggregated.isEmpty) {
          return _buildEmpty();
        }

        return RefreshIndicator(
          onRefresh: () async {
            context.read<CantadorBloc>().add(const RefreshCantadorData());
            await Future.delayed(const Duration(milliseconds: 600));
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Columna izquierda: ENTRADAS ──
                Expanded(flex: 5, child: _buildEntradasColumn(context, state)),
                const SizedBox(width: 12),
                // ── Columna derecha: SEGUNDOS ──
                Expanded(flex: 7, child: _buildSegundosColumn(context, state)),
              ],
            ),
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════
  // ENTRADAS
  // ═══════════════════════════════════════════════════

  Widget _buildEntradasColumn(BuildContext context, CantadorLoaded state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader(
          icon: '🥣',
          title: 'ENTRADAS',
          total: state.aggregated.totalEntradas,
        ),
        const SizedBox(height: 8),
        if (state.aggregated.entradas.isEmpty)
          _buildEmptyHint('Sin entradas pendientes'),
        ...state.aggregated.entradas.map(
          (e) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildEntradaCard(context, e, state.entradasServidasLocales),
          ),
        ),
      ],
    );
  }

  Widget _buildEntradaCard(
    BuildContext context,
    AggregatedEntrada entrada,
    Set<String> servidasLocales,
  ) {
    final isServida = servidasLocales.contains(
      entrada.name.toLowerCase().trim(),
    );

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isServida
            ? CantadorColors.entradaBg.withValues(alpha: 0.4)
            : CantadorColors.entradaBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Círculo grande con cantidad
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isServida
                  ? CantadorColors.entradaCircle.withValues(alpha: 0.4)
                  : CantadorColors.entradaCircle,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '${entrada.pendingQuantity}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Nombre + mesas
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entrada.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: CantadorColors.entradaTextDark,
                    decoration: isServida
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  entrada.pendingTables.join(' · '),
                  style: TextStyle(
                    fontSize: 11,
                    color: CantadorColors.entradaTextMid,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Botón tachar/destachar (solo visual, no envía al backend)
          GestureDetector(
            onTap: () {
              context.read<CantadorBloc>().add(
                ToggleEntradaServidaEvent(entrada.name),
              );
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: CantadorColors.entradaCircle,
                  width: 1.5,
                ),
              ),
              alignment: Alignment.center,
              child: Icon(
                isServida ? Icons.refresh : Icons.remove,
                color: CantadorColors.entradaCircle,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // SEGUNDOS
  // ═══════════════════════════════════════════════════

  Widget _buildSegundosColumn(BuildContext context, CantadorLoaded state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader(
          icon: '🍽️',
          title: 'SEGUNDOS',
          total: state.aggregated.totalSegundos,
        ),
        const SizedBox(height: 8),
        if (state.aggregated.segundos.isEmpty)
          _buildEmptyHint('Sin segundos pendientes'),
        // Grid de 2 columnas
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: state.aggregated.segundos
              .map(
                (s) => SizedBox(
                  width: (MediaQuery.of(context).size.width * 7 / 12 - 36) / 2,
                  child: _buildSegundoCard(context, s),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildSegundoCard(BuildContext context, AggregatedDish dish) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: CantadorColors.segundoBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: CantadorColors.segundoCircle,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '${dish.pendingQuantity}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dish.productName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: CantadorColors.segundoTextDark,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  dish.pendingTables.join(' · '),
                  style: const TextStyle(
                    fontSize: 10,
                    color: CantadorColors.segundoTextMid,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Botón [-] grande para descontar
          GestureDetector(
            onTap: () => _onServeTap(context, dish),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: CantadorColors.segundoCircle,
                  width: 1.5,
                ),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.remove,
                color: CantadorColors.segundoCircle,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onServeTap(BuildContext context, AggregatedDish dish) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      context.read<CantadorBloc>().add(ServeDishEvent(dish.productId));
      // Pequeño feedback
      messenger.showSnackBar(
        SnackBar(
          content: Text('✓ ${dish.productName} servido'),
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
    required int total,
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
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.4,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: CantadorColors.primary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$total',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🍽️', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 12),
          Text(
            'Sin pedidos pendientes',
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

  Widget _buildEmptyHint(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Center(
        child: Text(
          text,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        ),
      ),
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
              style: ElevatedButton.styleFrom(
                backgroundColor: CantadorColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
