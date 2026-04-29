/// Configuración centralizada de URLs del backend.
///
/// 📌 Para cambiar entre LOCAL y PRODUCCIÓN solo cambia [isProduction]:
///   - false → usa localhost (desarrollo en tu PC)
///   - true  → usa Render (producción, para el celular del mozo)
///
/// Equivalente a los archivos environment.ts / environment.prod.ts de Angular.
class ApiConfig {
  // ═══════════════════════════════════════════════════════════
  // 🔧 CAMBIA SOLO ESTA LÍNEA
  // ═══════════════════════════════════════════════════════════

  /// Si es true, la app apunta a Render (producción).
  /// Si es false, la app apunta a tu PC local (desarrollo).
  static const bool isProduction = true;

  // ═══════════════════════════════════════════════════════════
  // URLs (no toques nada de aquí abajo)
  // ═══════════════════════════════════════════════════════════

  /// URL base del backend para peticiones REST (api/auth, api/order, etc.)
  static String get baseUrl => isProduction
      ? 'https://app-restaurant-api.onrender.com/api'
      : 'http://localhost:5245/api';

  /// URL del hub de SignalR (tiempo real)
  static String get hubUrl => isProduction
      ? 'https://app-restaurant-api.onrender.com/hubs/orders'
      : 'http://localhost:5245/hubs/orders';

  /// Nombre del entorno actual (útil para mostrar en debug)
  static String get environmentName => isProduction ? 'PRODUCCIÓN' : 'LOCAL';
}
