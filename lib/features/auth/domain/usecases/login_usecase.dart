import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository repository;

  LoginUseCase(this.repository);

  Future<User> call(LoginParams params) async {
    if (params.username.trim().isEmpty) {
      throw Exception('El usuario es requerido');
    }
    if (params.password.length < 4) {
      throw Exception('La contraseña debe tener al menos 4 caracteres');
    }

    return await repository.login(
      email: params.username, // reutilizamos el campo email para username
      password: params.password,
    );
  }
}

class LoginParams {
  final String username;
  final String password;

  LoginParams({required this.username, required this.password});

  // Mantener compatibilidad con el campo email del repositorio
  String get email => username;

  @override
  String toString() => 'LoginParams(username: $username, password: ***)';
}
