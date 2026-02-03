import 'package:equatable/equatable.dart';

/// Entidad que representa un usuario en el dominio de la aplicación
/// 
/// Esta es una clase PURA de Dart, sin dependencias de Flutter.
/// Representa el concepto de "Usuario" en nuestra lógica de negocio.
/// 
/// ¿Por qué Equatable?
/// Permite comparar objetos por sus propiedades, no por referencia.
/// Ejemplo: user1 == user2 será true si tienen el mismo id, email, etc.
class User extends Equatable {
  /// Identificador único del usuario
  final String id;
  
  /// Correo electrónico del usuario
  final String email;
  
  /// Nombre completo del usuario
  final String name;
  
  /// URL de la foto de perfil (opcional)
  final String? photoUrl;

  /// Constructor
  /// 
  /// Los parámetros con 'required' son obligatorios.
  /// photoUrl es opcional (puede ser null por el ?)
  const User({
    required this.id,
    required this.email,
    required this.name,
    this.photoUrl,
  });

  /// Lista de propiedades que se usan para comparar objetos
  /// 
  /// Dos usuarios son iguales si todas estas propiedades son iguales.
  @override
  List<Object?> get props => [id, email, name, photoUrl];
  
  /// Método toString para debugging
  /// 
  /// Útil cuando haces print(user)
  @override
  String toString() {
    return 'User(id: $id, email: $email, name: $name, photoUrl: $photoUrl)';
  }
}