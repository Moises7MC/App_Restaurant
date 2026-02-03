import 'package:shared_preferences/shared_preferences.dart';
import '../../features/auth/data/datasources/auth_local_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/logout_usecase.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';

/// Contenedor de dependencias
/// 
/// Centraliza la creación de todas las instancias necesarias
/// de la aplicación.
/// 
/// ¿Por qué Dependency Injection?
/// - Facilita las pruebas (puedes inyectar mocks)
/// - Reduce el acoplamiento
/// - Centraliza la configuración
/// - Hace el código más mantenible
/// 
/// Patrón: Singleton
/// Solo existe una instancia de DependencyInjection en toda la app.
class DependencyInjection {
  // ═══════════════════════════════════════
  // SINGLETON PATTERN
  // ═══════════════════════════════════════
  
  /// Instancia única (singleton)
  static final DependencyInjection _instance = DependencyInjection._internal();
  
  /// Factory constructor - siempre retorna la misma instancia
  factory DependencyInjection() => _instance;
  
  /// Constructor privado - solo se llama una vez
  DependencyInjection._internal();

  // ═══════════════════════════════════════
  // DEPENDENCIAS
  // ═══════════════════════════════════════
  
  /// SharedPreferences (se inicializa una vez)
  late SharedPreferences _sharedPreferences;

  /// Repositorio de autenticación
  late AuthRepository _authRepository;

  /// Use Cases
  late LoginUseCase _loginUseCase;
  late LogoutUseCase _logoutUseCase;

  // ═══════════════════════════════════════
  // INICIALIZACIÓN
  // ═══════════════════════════════════════
  
  /// Inicializa todas las dependencias
  /// 
  /// IMPORTANTE: Debe llamarse ANTES de runApp()
  /// 
  /// Flujo de inicialización:
  /// 1. SharedPreferences (almacenamiento local)
  /// 2. DataSources (usan SharedPreferences)
  /// 3. Repositories (usan DataSources)
  /// 4. Use Cases (usan Repositories)
  /// 
  /// Uso:
  /// ```dart
  /// void main() async {
  ///   WidgetsFlutterBinding.ensureInitialized();
  ///   
  ///   final di = DependencyInjection();
  ///   await di.init();
  ///   
  ///   runApp(MyApp(di: di));
  /// }
  /// ```
  Future<void> init() async {
    debugPrint('🔧 Inicializando dependencias...');
    
    // ════════════════════════════════════════
    // 1. INICIALIZAR SHARED PREFERENCES
    // ════════════════════════════════════════
    debugPrint('📦 Inicializando SharedPreferences...');
    _sharedPreferences = await SharedPreferences.getInstance();
    debugPrint('✅ SharedPreferences inicializado');

    // ════════════════════════════════════════
    // 2. DATA SOURCES
    // ════════════════════════════════════════
    debugPrint('🔌 Creando DataSources...');
    final authLocalDataSource = AuthLocalDataSourceImpl(
      sharedPreferences: _sharedPreferences,
    );
    debugPrint('✅ AuthLocalDataSource creado');

    // ════════════════════════════════════════
    // 3. REPOSITORIES
    // ════════════════════════════════════════
    debugPrint('🏪 Creando Repositories...');
    _authRepository = AuthRepositoryImpl(
      localDataSource: authLocalDataSource,
    );
    debugPrint('✅ AuthRepository creado');

    // ════════════════════════════════════════
    // 4. USE CASES
    // ════════════════════════════════════════
    debugPrint('🎯 Creando Use Cases...');
    _loginUseCase = LoginUseCase(_authRepository);
    _logoutUseCase = LogoutUseCase(_authRepository);
    debugPrint('✅ Use Cases creados');
    
    debugPrint('🎉 Todas las dependencias inicializadas correctamente\n');
  }

  // ═══════════════════════════════════════
  // FACTORIES (Creadores de instancias)
  // ═══════════════════════════════════════
  
  /// Crea una nueva instancia del AuthBloc
  /// 
  /// Se crea cada vez que se necesita (NO es singleton).
  /// Cada página que necesite el BLoC tendrá su propia instancia.
  /// 
  /// Uso:
  /// ```dart
  /// BlocProvider(
  ///   create: (context) => di.createAuthBloc(),
  ///   child: LoginPage(),
  /// )
  /// ```
  AuthBloc createAuthBloc() {
    return AuthBloc(
      loginUseCase: _loginUseCase,
      logoutUseCase: _logoutUseCase,
      authRepository: _authRepository,
    );
  }

  // ═══════════════════════════════════════
  // GETTERS (Acceso a dependencias)
  // ═══════════════════════════════════════
  
  /// Obtiene el repositorio de autenticación
  /// 
  /// Útil si necesitas acceder al repository directamente
  /// (aunque generalmente usarás los Use Cases)
  AuthRepository get authRepository => _authRepository;
  
  /// Obtiene SharedPreferences
  /// 
  /// Por si necesitas acceder a almacenamiento local
  SharedPreferences get sharedPreferences => _sharedPreferences;
}