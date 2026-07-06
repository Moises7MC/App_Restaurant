/// Configuración centralizada de URLs del backend.
///
/// 📌 3 modos de operación:
///   - 'local'        → 127.0.0.1 (solo desarrollo en el mismo PC)
///   - 'localNetwork' → IP del router (red WiFi del restaurante) ⭐
///   - 'production'   → Render.com (servidor en internet)
class ApiConfig {
  // ═══════════════════════════════════════════════════════════
  // 🔧 CAMBIA SOLO ESTA LÍNEA
  // ═══════════════════════════════════════════════════════════

  /// Modo actual de operación.
  /// - 'localNetwork' → para usar dentro del restaurante (recomendado)
  /// - 'local'        → para desarrollo en el mismo PC
  /// - 'production'   → para servidor en la nube (Render)
  static const String mode = 'localNetwork';

  // ═══════════════════════════════════════════════════════════
  // 🌐 IP DE LA LAPTOP-SERVIDOR EN EL RESTAURANTE
  // ═══════════════════════════════════════════════════════════
  // Cambiar esta IP por la de la laptop del restaurante.
  // Para verla, abrir CMD y escribir: ipconfig
  // Buscar "Dirección IPv4" del adaptador WiFi (ej: 192.168.1.9)
  // static const String localNetworkIp = '192.168.1.2'; //casa
  static const String localNetworkIp = '192.168.0.128';
  //Como en casa

  // static const String localNetworkIp = '192.168.18.82'; //--cuarto chiclayo
  // static const String localNetworkIp = '192.168.1.10'; //mi soli

  // Puerto del backend. NO cambiar a menos que sepas qué haces.
  static const String backendPort = '5245';

  // ═══════════════════════════════════════════════════════════
  // URLs (NO TOCAR - se calculan automáticamente)
  // ═══════════════════════════════════════════════════════════

  /// URL base del backend para peticiones REST
  static String get baseUrl {
    switch (mode) {
      case 'production':
        return 'https://app-restaurant-api.onrender.com/api';
      case 'localNetwork':
        return 'http://$localNetworkIp:$backendPort/api';
      case 'local':
      default:
        return 'http://localhost:$backendPort/api';
    }
  }

  /// URL del hub de SignalR (tiempo real)
  static String get hubUrl {
    switch (mode) {
      case 'production':
        return 'https://app-restaurant-api.onrender.com/hubs/orders';
      case 'localNetwork':
        return 'http://$localNetworkIp:$backendPort/hubs/orders';
      case 'local':
      default:
        return 'http://localhost:$backendPort/hubs/orders';
    }
  }

  /// Nombre del entorno actual
  static String get environmentName {
    switch (mode) {
      case 'production':
        return 'PRODUCCIÓN (nube)';
      case 'localNetwork':
        return 'RED LOCAL ($localNetworkIp)';
      case 'local':
      default:
        return 'LOCAL (mismo PC)';
    }
  }
}
