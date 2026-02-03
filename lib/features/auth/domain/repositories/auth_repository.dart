import '../entities/user.dart';

/// Contrato (interfaz) del repositorio de autenticación
/// 
/// Define QUÉ operaciones de autenticación existen,
/// pero NO define CÓMO se implementan.
/// 
/// La implementación real estará en la capa de DATA.
/// 
/// ¿Por qué abstract?
/// No se puede instanciar directamente. Solo sirve como contrato.
abstract class AuthRepository {
  /// Inicia sesión con email y contraseña
  /// 
  /// [email] Correo electrónico del usuario
  /// [password] Contraseña del usuario
  /// 
  /// Retorna un [User] si el login es exitoso.
  /// Lanza una excepción si el login falla.
  /// 
  /// Ejemplo de uso:
  /// ```dart
  /// try {
  ///   final user = await repository.login(
  ///     email: 'admin@restaurant.com',
  ///     password: '123456',
  ///   );
  ///   print('Login exitoso: ${user.name}');
  /// } catch (e) {
  ///   print('Error: $e');
  /// }
  /// ```
  Future<User> login({
    required String email,
    required String password,
  });

  /// Cierra la sesión del usuario actual
  /// 
  /// Elimina toda la información de sesión almacenada.
  /// 
  /// Ejemplo de uso:
  /// ```dart
  /// await repository.logout();
  /// print('Sesión cerrada');
  /// ```
  Future<void> logout();

  /// Obtiene el usuario actualmente autenticado
  /// 
  /// Retorna el [User] si hay sesión activa.
  /// Retorna null si no hay usuario autenticado.
  /// 
  /// Ejemplo de uso:
  /// ```dart
  /// final user = await repository.getCurrentUser();
  /// if (user != null) {
  ///   print('Usuario: ${user.name}');
  /// } else {
  ///   print('No hay sesión activa');
  /// }
  /// ```
  Future<User?> getCurrentUser();

  /// Verifica si hay un usuario autenticado
  /// 
  /// Retorna true si hay sesión activa.
  /// Retorna false si no hay sesión.
  /// 
  /// Ejemplo de uso:
  /// ```dart
  /// if (await repository.isLoggedIn()) {
  ///   // Navegar a Home
  /// } else {
  ///   // Navegar a Login
  /// }
  /// ```
  Future<bool> isLoggedIn();
}