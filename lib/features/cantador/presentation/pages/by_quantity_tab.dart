import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../bloc/cantador_bloc.dart';
import '../bloc/cantador_event.dart';
import '../bloc/cantador_state.dart';
import '../../domain/entities/aggregated_dish.dart';
import '../../domain/entities/aggregated_entrada.dart';
import '../widgets/cantador_colors.dart';

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
                Expanded(flex: 5, child: _buildEntradasColumn(context, state)),
                const SizedBox(width: 12),
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
    final key = entrada.name.toLowerCase().trim();
    final isServida = servidasLocales.contains(key);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isServida
            ? CantadorColors.entradaBg.withOpacity(0.4)
            : CantadorColors.entradaBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Cantidad
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isServida
                  ? CantadorColors.entradaCircle.withOpacity(0.4)
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
                    decoration: isServida ? TextDecoration.lineThrough : null,
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

          // Botón [-] (visual)
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
  } // SEGUNDOS (SIN CAMBIOS)
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
                ),
                const SizedBox(height: 2),
                Text(
                  dish.pendingTables.join(' · '),
                  style: const TextStyle(
                    fontSize: 10,
                    color: CantadorColors.segundoTextMid,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => context.read<CantadorBloc>().add(
              ServeDishEvent(dish.productId),
            ),
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
          Text(icon),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const Spacer(),
          CircleAvatar(
            radius: 14,
            backgroundColor: CantadorColors.primary,
            child: Text(
              '$total',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() => const Center(child: Text('Sin pedidos pendientes'));
  Widget _buildEmptyHint(String t) =>
      Center(child: Text(t, style: const TextStyle(fontSize: 12)));
  Widget _buildError(BuildContext c, String m) =>
      Center(child: Text(m, textAlign: TextAlign.center));
}
