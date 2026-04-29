import 'package:app_restaurant/core/config/api_config.dart';
import 'package:flutter/foundation.dart';
import 'package:signalr_netcore/signalr_client.dart';

/// Servicio SignalR del cantador.
///
/// Se encarga de:
///  - Conectarse al hub `/hubs/orders` del backend
///  - Unirse al grupo "Cantadores" (configurado en OrderHub.cs)
///  - Escuchar eventos en tiempo real y notificar a través de un callback
///
/// Eventos que escucha:
///  - `ActualizacionPedido`: mozo creó/modificó/canceló algún item de una orden
///  - `ItemServed`: alguien descontó un plato (otro cantador o este mismo)
///  - `OrderSung`: una orden fue marcada como cantada al chef
///  - `OrderStatusChanged`: el chef cambió status desde la web (Listo/Cancelado)
///
/// Uso:
/// ```dart
/// final signalR = CantadorSignalRService(
///   onUpdate: () => bloc.add(const RefreshCantadorData()),
/// );
/// await signalR.connect();
/// // ...
/// await signalR.disconnect();
/// ```
class CantadorSignalRService {
  /// URL del hub. Se ajusta al cambiar entre local y producción.
  // static const String hubUrl = 'http://localhost:5245/hubs/orders';
  // static const String hubUrl = 'https://app-restaurant-api.onrender.com/hubs/orders';
  static String get hubUrl => ApiConfig.hubUrl;

  /// Callback que se dispara cuando llega cualquier evento del backend.
  /// La pantalla lo usa para refrescar los datos.
  final VoidCallback onUpdate;

  /// Callback opcional para notificar pedidos nuevos (sonido + vibración).
  final void Function(Map<String, dynamic>? data)? onNewOrder;

  HubConnection? _connection;
  bool _isConnected = false;

  bool get isConnected => _isConnected;

  CantadorSignalRService({required this.onUpdate, this.onNewOrder});

  /// Conecta al hub y se une al grupo Cantadores.
  Future<void> connect() async {
    try {
      _connection = HubConnectionBuilder()
          .withUrl(hubUrl)
          .withAutomaticReconnect()
          .build();

      // ─── Listeners de eventos del backend ───

      // Evento principal: cualquier cambio en órdenes (crear, modificar, cancelar)
      _connection!.on('ActualizacionPedido', (args) {
        debugPrint('🔔 [Cantador] ActualizacionPedido recibido');
        // Detectar si es una orden nueva (sin items servidos = recién creada)
        try {
          if (args != null && args.isNotEmpty && args[0] is Map) {
            final data = args[0] as Map<String, dynamic>;
            final items = data['items'] as List<dynamic>?;
            final wasSung = (data['wasSung'] as bool?) ?? false;

            // Considera "nueva" si no se ha cantado todavía y nada ha sido servido
            if (!wasSung && items != null && items.isNotEmpty) {
              final allUnserved = items.every((i) {
                final served = (i['servedQuantity'] as int?) ?? 0;
                return served == 0;
              });
              if (allUnserved) {
                onNewOrder?.call(data);
              }
            }
          }
        } catch (e) {
          debugPrint('⚠ Error parseando ActualizacionPedido: $e');
        }

        onUpdate();
      });

      // Plato servido (descontado)
      _connection!.on('ItemServed', (args) {
        debugPrint('🔔 [Cantador] ItemServed recibido');
        onUpdate();
      });

      // Orden marcada como cantada
      _connection!.on('OrderSung', (args) {
        debugPrint('🔔 [Cantador] OrderSung recibido');
        onUpdate();
      });

      // Status cambiado desde la web del chef
      _connection!.on('OrderStatusChanged', (args) {
        debugPrint('🔔 [Cantador] OrderStatusChanged recibido');
        onUpdate();
      });

      // ─── Conectar y unirse al grupo ───
      await _connection!.start();
      await _connection!.invoke('JoinCantadorGroup');

      _isConnected = true;
      debugPrint('✅ [Cantador] SignalR conectado y unido a grupo Cantadores');
    } catch (e) {
      _isConnected = false;
      debugPrint('❌ [Cantador] No se pudo conectar a SignalR: $e');
      // No relanzamos: la app sigue funcionando con polling/refresh manual
    }
  }

  /// Desconecta del hub.
  Future<void> disconnect() async {
    try {
      await _connection?.stop();
      _isConnected = false;
      debugPrint('🔌 [Cantador] SignalR desconectado');
    } catch (e) {
      debugPrint('⚠ Error desconectando SignalR: $e');
    }
  }
}
