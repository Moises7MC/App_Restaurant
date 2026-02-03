import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'dart:convert';

/// DataSource local para autenticación
/// 
/// Por ahora SIMULA un backend (usuarios hardcodeados).
/// En una app real, aquí harías llamadas HTTP a tu API.
/// 
/// ¿Por qué un contrato (abstract class)?
/// - Facilita testing (puedes crear un mock)
/// - Permite múltiples implementaciones (local, remoto, mock)
abstract class AuthLocalDataSource {
  /// Intenta autenticar al usuario
  Future<UserModel> login(String email, String password);
  
  /// Cierra la sesión
  Future<void> logout();
  
  /// Obtiene el usuario guardado en caché
  Future<UserModel?> getCachedUser();
  
  /// Guarda el usuario en caché
  Future<void> cacheUser(UserModel user);
}

/// Implementación del DataSource local
/// 
/// Usa SharedPreferences para guardar datos localmente.
class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  /// SharedPreferences para almacenamiento persistente local
  final SharedPreferences sharedPreferences;
  
  /// Clave para guardar el usuario en SharedPreferences
  static const String cachedUserKey = 'CACHED_USER';

  /// Constructor
  /// 
  /// Recibe SharedPreferences por inyección de dependencias.
  AuthLocalDataSourceImpl({required this.sharedPreferences});

  /// Intenta autenticar al usuario
  /// 
  /// IMPORTANTE: Esto es una SIMULACIÓN.
  /// En una app real, harías algo como:
  /// 
  /// ```dart
  /// final response = await http.post(
  ///   Uri.parse('https://api.restaurant.com/auth/login'),
  ///   body: {'email': email, 'password': password},
  /// );
  /// 
  /// if (response.statusCode == 200) {
  ///   final json = jsonDecode(response.body);
  ///   return UserModel.fromJson(json['user']);
  /// } else {
  ///   throw Exception('Login failed');
  /// }
  /// ```
  @override
  Future<UserModel> login(String email, String password) async {
    // Simular latencia de red (1 segundo)
    await Future.delayed(const Duration(seconds: 1));
    
    // ═══════════════════════════════════════
    // USUARIOS DE PRUEBA
    // ═══════════════════════════════════════
    
    // Usuario 1: Admin
    if (email == 'admin@restaurant.com' && password == '123456') {
      final user = UserModel(
        id: '1',
        email: email,
        name: 'Admin Restaurant',
        photoUrl: null,
      );
      
      // Guardar usuario en caché
      await cacheUser(user);
      return user;
    }
    
    // Usuario 2: Usuario Demo
    else if (email == 'user@test.com' && password == '123456') {
      final user = UserModel(
        id: '2',
        email: email,
        name: 'Usuario Demo',
        photoUrl: null,
      );
      
      await cacheUser(user);
      return user;
    }
    
    // Credenciales inválidas
    else {
      throw Exception('Credenciales inválidas. Verifica tu email y contraseña.');
    }
  }

  /// Cierra la sesión
  /// 
  /// Elimina el usuario guardado en SharedPreferences.
  @override
  Future<void> logout() async {
    await sharedPreferences.remove(cachedUserKey);
  }

  /// Obtiene el usuario guardado en caché
  /// 
  /// Retorna el UserModel si existe.
  /// Retorna null si no hay usuario guardado.
  /// 
  /// Se usa para verificar si hay sesión activa al abrir la app.
  @override
  Future<UserModel?> getCachedUser() async {
    // Obtener el JSON guardado
    final jsonString = sharedPreferences.getString(cachedUserKey);
    
    if (jsonString != null) {
      // Convertir de JSON string a Map
      final jsonMap = json.decode(jsonString) as Map<String, dynamic>;
      
      // Convertir de Map a UserModel
      return UserModel.fromJson(jsonMap);
    }
    
    return null;
  }

  /// Guarda el usuario en caché
  /// 
  /// Convierte el UserModel a JSON y lo guarda en SharedPreferences.
  @override
  Future<void> cacheUser(UserModel user) async {
    // Convertir UserModel a Map
    final jsonMap = user.toJson();
    
    // Convertir Map a JSON string
    final jsonString = json.encode(jsonMap);
    
    // Guardar en SharedPreferences
    await sharedPreferences.setString(cachedUserKey, jsonString);
  }
}