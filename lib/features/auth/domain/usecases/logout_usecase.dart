import '../repositories/auth_repository.dart';

/// Caso de uso para cerrar sesión
///
/// Encapsula la lógica de negocio del logout.
///
/// ¿Por qué un Use Case separado?
/// - Sigue Single Responsibility Principle
/// - Podría tener lógica adicional (limpiar cache, analytics, etc.)
/// - Fácil de testear independientemente
class LogoutUseCase {
  /// Repositorio de autenticación
  final AuthRepository repository;

  /// Constructor
  ///
  /// Recibe el repository por inyección de dependencias.
  LogoutUseCase(this.repository);

  /// Ejecuta el caso de uso de logout
  ///
  /// Cierra la sesión del usuario actual.
  /// Elimina todos los datos de sesión almacenados.
  ///
  /// Ejemplo de uso:
  /// ```dart
  /// final logoutUseCase = LogoutUseCase(authRepository);
  /// await logoutUseCase();
  /// print('Sesión cerrada exitosamente');
  /// ```
  Future<void> call() async {
    // Aquí podrías agregar lógica adicional antes del logout
    // Por ejemplo:
    // - Limpiar cache local
    // - Registrar evento de analytics
    // - Cancelar suscripciones activas
    // - Limpiar notificaciones

    // Ejecutar el logout
    await repository.logout();

    // Aquí podrías agregar lógica adicional después del logout
    // Por ejemplo:
    // - Limpiar datos sensibles de memoria
    // - Resetear estados globales
  }
}
