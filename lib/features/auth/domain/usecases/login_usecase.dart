import '../entities/user.dart';
import '../repositories/auth_repository.dart';

/// Caso de uso para iniciar sesión
/// 
/// Encapsula la lógica de negocio del login.
/// Sigue el principio de Single Responsibility: hace UNA cosa.
/// 
/// ¿Por qué un Use Case?
/// - Centraliza la lógica de negocio
/// - Reutilizable en diferentes partes de la app
/// - Fácil de testear
/// - Independiente de la UI
class LoginUseCase {
  /// Repositorio de autenticación
  /// 
  /// No es la implementación concreta, sino el contrato.
  /// Esto permite cambiar la implementación sin modificar el use case.
  final AuthRepository repository;

  /// Constructor
  /// 
  /// Recibe el repository por inyección de dependencias.
  LoginUseCase(this.repository);

  /// Ejecuta el caso de uso de login
  /// 
  /// [params] Contiene el email y password del usuario
  /// 
  /// Retorna el [User] autenticado si el login es exitoso.
  /// Lanza una excepción si el login falla.
  /// 
  /// Ejemplo de uso:
  /// ```dart
  /// final loginUseCase = LoginUseCase(authRepository);
  /// try {
  ///   final user = await loginUseCase(
  ///     LoginParams(
  ///       email: 'admin@restaurant.com',
  ///       password: '123456',
  ///     ),
  ///   );
  ///   print('Login exitoso: ${user.name}');
  /// } catch (e) {
  ///   print('Error en login: $e');
  /// }
  /// ```
  Future<User> call(LoginParams params) async {
    // Aquí podrías agregar validaciones de negocio adicionales
    // Por ejemplo:
    // - Verificar formato de email
    // - Verificar longitud mínima de contraseña
    // - Aplicar reglas de negocio específicas
    
    // Validación básica de email
    if (!_isValidEmail(params.email)) {
      throw Exception('Email inválido');
    }
    
    // Validación básica de contraseña
    if (params.password.length < 6) {
      throw Exception('La contraseña debe tener al menos 6 caracteres');
    }
    
    // Delegar al repository para la autenticación real
    return await repository.login(
      email: params.email,
      password: params.password,
    );
  }
  
  /// Valida el formato de un email
  bool _isValidEmail(String email) {
    // Expresión regular simple para validar emails
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }
}

/// Parámetros necesarios para ejecutar el login
/// 
/// Encapsula todos los datos de entrada del use case.
/// 
/// ¿Por qué una clase separada?
/// - Agrupa parámetros relacionados
/// - Fácil de extender (agregar más parámetros sin cambiar firma del método)
/// - Más claro y mantenible
class LoginParams {
  /// Email del usuario
  final String email;
  
  /// Contraseña del usuario
  final String password;

  /// Constructor
  LoginParams({
    required this.email,
    required this.password,
  });
  
  /// Método toString para debugging
  @override
  String toString() {
    return 'LoginParams(email: $email, password: ***)'; // No mostramos la password
  }
}