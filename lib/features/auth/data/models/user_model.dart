import '../../domain/entities/user.dart';

/// Modelo de datos para User
/// 
/// Extiende de la entidad User del dominio y agrega métodos
/// para convertir desde/hacia JSON y otros formatos de datos.
/// 
/// ¿Por qué separar Model de Entity?
/// - Entity: lógica de negocio pura (sin JSON, sin Flutter)
/// - Model: detalles de implementación (JSON, serialización)
/// 
/// Esto permite cambiar el formato de datos sin afectar el dominio.
class UserModel extends User {
  /// Constructor
  /// 
  /// Usa super para pasar los parámetros al constructor de User
  const UserModel({
    required super.id,
    required super.email,
    required super.name,
    super.photoUrl,
  });

  /// Crea un UserModel desde un Map (JSON)
  /// 
  /// Este método se usa cuando recibes datos de una API.
  /// 
  /// Ejemplo de JSON:
  /// ```json
  /// {
  ///   "id": "123",
  ///   "email": "admin@restaurant.com",
  ///   "name": "Admin Restaurant",
  ///   "photoUrl": "https://example.com/photo.jpg"
  /// }
  /// ```
  /// 
  /// Uso:
  /// ```dart
  /// final json = {'id': '123', 'email': 'admin@test.com', ...};
  /// final user = UserModel.fromJson(json);
  /// ```
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      photoUrl: json['photoUrl'] as String?,  // Puede ser null
    );
  }

  /// Convierte el UserModel a un Map (JSON)
  /// 
  /// Este método se usa cuando envías datos a una API.
  /// 
  /// Uso:
  /// ```dart
  /// final user = UserModel(id: '123', email: 'admin@test.com', ...);
  /// final json = user.toJson();
  /// // json = {'id': '123', 'email': 'admin@test.com', ...}
  /// ```
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'photoUrl': photoUrl,
    };
  }

  /// Convierte el Model a Entity
  /// 
  /// Se usa cuando pasamos datos de Data Layer a Domain Layer.
  /// 
  /// Aunque UserModel ya es un User (hereda), este método
  /// hace explícita la conversión.
  /// 
  /// Uso:
  /// ```dart
  /// final userModel = UserModel.fromJson(json);
  /// final userEntity = userModel.toEntity();
  /// ```
  User toEntity() {
    return User(
      id: id,
      email: email,
      name: name,
      photoUrl: photoUrl,
    );
  }

  /// Crea una copia del UserModel con algunos campos modificados
  /// 
  /// Útil cuando necesitas actualizar solo algunos campos.
  /// 
  /// Uso:
  /// ```dart
  /// final user = UserModel(id: '1', name: 'Juan', ...);
  /// final updatedUser = user.copyWith(name: 'Juan Pérez');
  /// ```
  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? photoUrl,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }
}