import 'package:equatable/equatable.dart';
import '../../domain/entities/user.dart';

/// Estados posibles del AuthBloc
/// 
/// Un estado representa CÓMO está la app en un momento dado.
/// Por ejemplo: "está cargando", "usuario autenticado", "error"
/// 
/// La UI reacciona a estos estados y se reconstruye automáticamente.
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial - No sabemos nada aún
/// 
/// Este es el estado cuando se crea el BLoC por primera vez.
/// No sabemos si hay usuario autenticado o no.
/// 
/// La UI puede mostrar un splash screen o loading.
class AuthInitial extends AuthState {
  @override
  String toString() => 'AuthInitial()';
}

/// Estado: Procesando autenticación
/// 
/// Se emite cuando estamos:
/// - Verificando credenciales
/// - Cerrando sesión
/// - Verificando si hay sesión activa
/// 
/// La UI debe mostrar un indicador de carga.
/// 
/// Uso en UI:
/// ```dart
/// if (state is AuthLoading) {
///   return CircularProgressIndicator();
/// }
/// ```
class AuthLoading extends AuthState {
  @override
  String toString() => 'AuthLoading()';
}

/// Estado: Usuario autenticado exitosamente
/// 
/// Se emite cuando el login fue exitoso o cuando
/// encontramos una sesión activa.
/// 
/// Contiene los datos del usuario autenticado.
/// 
/// La UI debe navegar al Home y mostrar los datos del usuario.
/// 
/// Uso en UI:
/// ```dart
/// if (state is AuthAuthenticated) {
///   final userName = state.user.name;
///   return Text('Bienvenido $userName');
/// }
/// ```
class AuthAuthenticated extends AuthState {
  /// Usuario autenticado
  final User user;

  const AuthAuthenticated(this.user);

  /// Props para comparar estados
  /// 
  /// Dos estados AuthAuthenticated son iguales si tienen
  /// el mismo usuario.
  @override
  List<Object?> get props => [user];
  
  @override
  String toString() => 'AuthAuthenticated(user: ${user.name})';
}

/// Estado: Usuario no autenticado
/// 
/// Se emite cuando:
/// - No hay sesión activa al abrir la app
/// - El usuario cerró sesión exitosamente
/// 
/// La UI debe mostrar la pantalla de login.
/// 
/// Uso en UI:
/// ```dart
/// if (state is AuthUnauthenticated) {
///   return LoginPage();
/// }
/// ```
class AuthUnauthenticated extends AuthState {
  @override
  String toString() => 'AuthUnauthenticated()';
}

/// Estado: Error en la autenticación
/// 
/// Se emite cuando ocurre un error:
/// - Credenciales incorrectas
/// - Error de red
/// - Error del servidor
/// 
/// Contiene el mensaje de error para mostrarlo al usuario.
/// 
/// La UI debe mostrar un mensaje de error (SnackBar, Dialog, etc.)
/// 
/// Uso en UI:
/// ```dart
/// if (state is AuthError) {
///   ScaffoldMessenger.of(context).showSnackBar(
///     SnackBar(content: Text(state.message)),
///   );
/// }
/// ```
class AuthError extends AuthState {
  /// Mensaje de error para mostrar al usuario
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
  
  @override
  String toString() => 'AuthError(message: $message)';
}