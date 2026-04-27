import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String email;
  final String name;
  final String? photoUrl;

  // Campos específicos del mozo / cantador
  final String? username;
  final String? firstName;
  final String? lastName;
  final String? gender; // "M" o "F"

  /// ✅ NUEVO — rol del usuario: "mozo" o "cantador"
  final String role;

  const User({
    required this.id,
    required this.email,
    required this.name,
    this.photoUrl,
    this.username,
    this.firstName,
    this.lastName,
    this.gender,
    this.role = 'mozo',
  });

  /// Retorna el saludo según el género
  String get greeting {
    if (gender == 'F') return 'Bienvenida';
    return 'Bienvenido';
  }

  /// Retorna el título según el género y rol
  String get title {
    if (role == 'cantador') {
      return gender == 'F' ? 'Cantadora' : 'Cantador';
    }
    return gender == 'F' ? 'Mozа' : 'Mozo';
  }

  /// ✅ Helpers para verificar el rol
  bool get isCantador => role == 'cantador';
  bool get isMozo => role == 'mozo';

  @override
  List<Object?> get props => [
    id,
    email,
    name,
    photoUrl,
    username,
    gender,
    role,
  ];

  @override
  String toString() =>
      'User(id: $id, name: $name, username: $username, role: $role)';
}
