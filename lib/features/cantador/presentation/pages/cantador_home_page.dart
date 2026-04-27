import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../data/services/cantador_signalr_service.dart';
import '../bloc/cantador_bloc.dart';
import '../bloc/cantador_event.dart';
import '../bloc/cantador_state.dart';
import '../widgets/cantador_colors.dart';
import 'by_quantity_tab.dart';
import 'by_table_tab.dart';
import 'history_tab.dart';

/// Pantalla principal del cantador con 3 tabs y SignalR en tiempo real.
class CantadorHomePage extends StatelessWidget {
  const CantadorHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CantadorBloc()..add(const LoadCantadorData()),
      child: const _CantadorHomeView(),
    );
  }
}

class _CantadorHomeView extends StatefulWidget {
  const _CantadorHomeView();

  @override
  State<_CantadorHomeView> createState() => _CantadorHomeViewState();
}

class _CantadorHomeViewState extends State<_CantadorHomeView>
    with WidgetsBindingObserver {
  CantadorSignalRService? _signalR;
  bool _signalRConnected = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Conectar después del primer frame para tener acceso al CantadorBloc
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initSignalR();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _signalR?.disconnect();
    super.dispose();
  }

  /// Reconectar SignalR cuando la app vuelve del background
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_signalR != null && !_signalR!.isConnected) {
        _signalR!.connect().then((_) {
          if (mounted) {
            setState(() => _signalRConnected = _signalR!.isConnected);
            // Refrescar datos al volver del background
            context.read<CantadorBloc>().add(const RefreshCantadorData());
          }
        });
      } else {
        // Aunque esté conectado, refrescar por si nos perdimos algo
        if (mounted) {
          context.read<CantadorBloc>().add(const RefreshCantadorData());
        }
      }
    }
  }

  Future<void> _initSignalR() async {
    final bloc = context.read<CantadorBloc>();

    _signalR = CantadorSignalRService(
      onUpdate: () {
        if (mounted) {
          bloc.add(const RefreshCantadorData());
        }
      },
      onNewOrder: (data) {
        if (mounted) {
          _onNewOrderArrived(data);
        }
      },
    );

    await _signalR!.connect();
    if (mounted) {
      setState(() => _signalRConnected = _signalR!.isConnected);
    }
  }

  /// Cuando llega un pedido nuevo: vibrar + sonido + snackbar
  void _onNewOrderArrived(Map<String, dynamic>? data) {
    // Vibración corta
    HapticFeedback.heavyImpact();

    // Snackbar destacado
    final tableNumber = data?['tableNumber'];
    final isParaLlevar = (data?['isParaLlevar'] as bool?) ?? false;
    final messenger = ScaffoldMessenger.of(context);

    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.notifications_active, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                tableNumber != null
                    ? '🆕 Pedido nuevo · Mesa $tableNumber${isParaLlevar ? ' 🛍' : ''}'
                    : '🆕 Pedido nuevo',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: CantadorColors.entradaCircle,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      initialIndex: 0,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: CantadorColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          toolbarHeight: 52,
          title: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              final name = (state is AuthAuthenticated)
                  ? (state.user.firstName ?? state.user.name)
                  : 'Cantador';
              return Row(
                children: [
                  const Icon(Icons.mic, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 10),
                  // ✅ NUEVO: Indicador de conexión SignalR
                  _buildConnectionDot(),
                  const SizedBox(width: 6),
                  // Indicador de "refrescando"
                  BlocBuilder<CantadorBloc, CantadorState>(
                    builder: (context, state) {
                      if (state is CantadorLoaded && state.isRefreshing) {
                        return const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white70,
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              );
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refrescar',
              onPressed: () {
                context.read<CantadorBloc>().add(const RefreshCantadorData());
              },
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Cerrar sesión',
              onPressed: () => _confirmLogout(context),
            ),
          ],
          bottom: const TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            tabs: [
              Tab(
                icon: Icon(Icons.format_list_numbered, size: 20),
                text: 'POR CANTIDADES',
              ),
              Tab(
                icon: Icon(Icons.table_restaurant, size: 20),
                text: 'POR MESA',
              ),
              Tab(icon: Icon(Icons.history, size: 20), text: 'HISTORIAL'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [ByQuantityTab(), ByTableTab(), HistoryTab()],
        ),
      ),
    );
  }

  /// Punto verde (conectado) o gris (desconectado)
  Widget _buildConnectionDot() {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: _signalRConnected
            ? const Color(0xFF4ade80) // verde brillante
            : Colors.white24,
        shape: BoxShape.circle,
        boxShadow: _signalRConnected
            ? [
                BoxShadow(
                  color: const Color(0xFF4ade80).withValues(alpha: 0.6),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro que deseas cerrar sesión?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<AuthBloc>().add(LogoutButtonPressed());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
  }
}
