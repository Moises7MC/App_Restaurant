import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';

/// Implementación concreta del repositorio de autenticación
/// 
/// Este es el "puente" entre la capa de Domain y la capa de Data.
/// 
/// Responsabilidades:
/// - Implementar el contrato AuthRepository de Domain
/// - Coordinar entre diferentes fuentes de datos (local, remoto, cache)
/// - Convertir Models (Data) a Entities (Domain)
/// - Manejar errores y excepciones
/// 
/// ¿Por qué esta capa?
/// - Domain no sabe de dónde vienen los datos (API, DB, cache)
/// - Data no sabe qué hacer con los datos (lógica de negocio)
/// - Repository coordina ambos
class AuthRepositoryImpl implements AuthRepository {
  /// DataSource local para autenticación
  /// 
  /// En una app real, aquí también tendrías:
  /// - remoteDataSource (para API)
  /// - cacheDataSource (para cache rápido)
  final AuthLocalDataSource localDataSource;

  /// Constructor
  /// 
  /// Recibe las dependencias necesarias.
  AuthRepositoryImpl({
    required this.localDataSource,
  });

  /// Implementa el método login del contrato
  /// 
  /// Flujo:
  /// 1. Llama al dataSource para obtener datos
  /// 2. Convierte UserModel (Data) a User (Domain)
  /// 3. Maneja errores si ocurren
  @override
  Future<User> login({
    required String email,
    required String password,
  }) async {
    try {
      // 1. Obtener datos del datasource
      final userModel = await localDataSource.login(email, password);
      
      // 2. Convertir Model a Entity
      // (UserModel ya es un User porque extiende de User,
      // pero hacemos la conversión explícita con toEntity())
      return userModel.toEntity();
      
    } catch (e) {
      // 3. Manejar errores
      // Aquí podrías:
      // - Transformar errores técnicos en errores de negocio
      // - Agregar logging
      // - Reintentar la operación
      
      // Por ahora, solo relanzamos el error
      rethrow;
    }
  }

  /// Implementa el método logout del contrato
  @override
  Future<void> logout() async {
    try {
      await localDataSource.logout();
    } catch (e) {
      // Manejar errores de logout
      rethrow;
    }
  }

  /// Implementa el método getCurrentUser del contrato
  /// 
  /// Obtiene el usuario guardado en caché.
  @override
  Future<User?> getCurrentUser() async {
    try {
      final userModel = await localDataSource.getCachedUser();
      
      // Si no hay usuario en caché, retornar null
      if (userModel == null) {
        return null;
      }
      
      // Convertir Model a Entity
      return userModel.toEntity();
      
    } catch (e) {
      // Si hay error, consideramos que no hay usuario
      return null;
    }
  }

  /// Implementa el método isLoggedIn del contrato
  /// 
  /// Verifica si hay un usuario autenticado.
  @override
  Future<bool> isLoggedIn() async {
    final user = await getCurrentUser();
    return user != null;
  }
}