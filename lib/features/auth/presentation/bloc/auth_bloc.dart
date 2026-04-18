import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

/// BLoC de autenticación
///
/// Maneja todo el estado relacionado con la autenticación.
///
/// Flujo:
/// 1. UI envía un EVENTO (ej: LoginButtonPressed)
/// 2. BLoC procesa el evento
/// 3. BLoC ejecuta use cases
/// 4. BLoC emite un nuevo ESTADO (ej: AuthAuthenticated)
/// 5. UI reacciona al nuevo estado
///
/// ¿Por qué BLoC?
/// - Separa la lógica de la UI
/// - Estado predecible
/// - Fácil de testear
/// - Reactivo
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  /// Use case para login
  final LoginUseCase loginUseCase;

  /// Use case para logout
  final LogoutUseCase logoutUseCase;

  /// Repository para obtener usuario actual
  final AuthRepository authRepository;

  /// Constructor
  ///
  /// Recibe las dependencias por inyección.
  /// Estado inicial: AuthInitial
  AuthBloc({
    required this.loginUseCase,
    required this.logoutUseCase,
    required this.authRepository,
  }) : super(AuthInitial()) {
    // Registrar manejadores de eventos
    // Cada evento tiene su propio manejador
    on<LoginButtonPressed>(_onLoginButtonPressed);
    on<LogoutButtonPressed>(_onLogoutButtonPressed);
    on<CheckAuthStatus>(_onCheckAuthStatus);
  }

  /// Maneja el evento de login
  ///
  /// Flujo:
  /// 1. Emitir estado de carga (AuthLoading)
  /// 2. Ejecutar el use case de login
  /// 3. Si es exitoso → AuthAuthenticated
  /// 4. Si falla → AuthError
  Future<void> _onLoginButtonPressed(
    LoginButtonPressed event,
    Emitter<AuthState> emit,
  ) async {
    print('🔐 LoginButtonPressed: email=${event.email}');

    emit(AuthLoading());

    try {
      print('🔄 Ejecutando LoginUseCase...');

      final user = await loginUseCase(
        LoginParams(username: event.email, password: event.password),
      );

      print('✅ Login exitoso: user=${user.email}');
      emit(AuthAuthenticated(user));
    } catch (e) {
      print('❌ Login error: $e');
      print('❌ Stack trace: ${StackTrace.current}');

      String errorMessage = 'Error al iniciar sesión';

      if (e.toString().contains('Credenciales inválidas')) {
        errorMessage = 'Email o contraseña incorrectos';
      } else if (e.toString().contains('Email inválido')) {
        errorMessage = 'El formato del email no es válido';
      } else if (e.toString().contains('contraseña')) {
        errorMessage = e.toString().replaceAll('Exception: ', '');
      }

      print('🔴 ErrorMessage: $errorMessage');
      emit(AuthError(errorMessage));
    }
  }

  /// Maneja el evento de logout
  ///
  /// Flujo:
  /// 1. Emitir estado de carga
  /// 2. Ejecutar el use case de logout
  /// 3. Emitir estado no autenticado
  Future<void> _onLogoutButtonPressed(
    LogoutButtonPressed event,
    Emitter<AuthState> emit,
  ) async {
    // 1. Mostrar loading
    emit(AuthLoading());

    try {
      // 2. Ejecutar logout
      await logoutUseCase();

      // 3. Emitir estado no autenticado
      emit(AuthUnauthenticated());
    } catch (e) {
      // Si falla el logout, aún así marcamos como no autenticado
      // El logout local siempre debería funcionar
      emit(AuthUnauthenticated());
    }
  }

  /// Verifica si hay un usuario autenticado al iniciar
  ///
  /// Se ejecuta cuando la app inicia.
  ///
  /// Flujo:
  /// 1. Emitir estado de carga
  /// 2. Verificar si hay usuario en caché
  /// 3. Si hay usuario → AuthAuthenticated
  /// 4. Si no hay usuario → AuthUnauthenticated
  Future<void> _onCheckAuthStatus(
    CheckAuthStatus event,
    Emitter<AuthState> emit,
  ) async {
    // 1. Mostrar loading
    emit(AuthLoading());

    try {
      // 2. Verificar si hay usuario guardado
      final user = await authRepository.getCurrentUser();

      if (user != null) {
        // 3. Hay sesión activa
        emit(AuthAuthenticated(user));
      } else {
        // 4. No hay sesión activa
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      // Si hay error, consideramos que no hay sesión
      emit(AuthUnauthenticated());
    }
  }
}
