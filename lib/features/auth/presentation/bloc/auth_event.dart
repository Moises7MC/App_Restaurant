import 'package:equatable/equatable.dart';

/// Eventos que puede recibir el AuthBloc
/// 
/// Un evento representa una ACCIÓN que ocurre en la app.
/// Por ejemplo: "el usuario presionó el botón de login"
/// 
/// ¿Por qué Equatable?
/// Permite comparar eventos fácilmente.
/// Útil para evitar procesar el mismo evento múltiples veces.
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Evento: El usuario presionó el botón de login
/// 
/// Contiene los datos necesarios para intentar el login:
/// - Email
/// - Password
/// 
/// Uso:
/// ```dart
/// context.read<AuthBloc>().add(
///   LoginButtonPressed(
///     email: 'admin@restaurant.com',
///     password: '123456',
///   ),
/// );
/// ```
class LoginButtonPressed extends AuthEvent {
  /// Email ingresado por el usuario
  final String email;
  
  /// Password ingresada por el usuario
  final String password;

  const LoginButtonPressed({
    required this.email,
    required this.password,
  });

  /// Props para comparar eventos
  /// 
  /// Dos eventos LoginButtonPressed son iguales si tienen
  /// el mismo email y password.
  @override
  List<Object?> get props => [email, password];
  
  @override
  String toString() {
    return 'LoginButtonPressed(email: $email, password: ***)';
  }
}

/// Evento: El usuario presionó el botón de logout
/// 
/// No necesita datos adicionales, solo indica que
/// el usuario quiere cerrar sesión.
/// 
/// Uso:
/// ```dart
/// context.read<AuthBloc>().add(LogoutButtonPressed());
/// ```
class LogoutButtonPressed extends AuthEvent {
  @override
  String toString() => 'LogoutButtonPressed()';
}

/// Evento: Verificar si hay sesión activa
/// 
/// Se dispara cuando la app inicia para verificar
/// si hay un usuario ya autenticado.
/// 
/// Uso:
/// ```dart
/// // Al iniciar la app
/// context.read<AuthBloc>().add(CheckAuthStatus());
/// ```
class CheckAuthStatus extends AuthEvent {
  @override
  String toString() => 'CheckAuthStatus()';
}