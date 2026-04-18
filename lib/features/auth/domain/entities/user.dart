import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String email;
  final String name;
  final String? photoUrl;

  // Campos específicos del mozo
  final String? username;
  final String? firstName;
  final String? lastName;
  final String? gender; // "M" o "F"

  const User({
    required this.id,
    required this.email,
    required this.name,
    this.photoUrl,
    this.username,
    this.firstName,
    this.lastName,
    this.gender,
  });

  /// Retorna el saludo según el género
  String get greeting {
    if (gender == 'F') return 'Bienvenida';
    return 'Bienvenido';
  }

  /// Retorna el título según el género
  String get title {
    if (gender == 'F') return 'Mozа';
    return 'Mozo';
  }

  @override
  List<Object?> get props => [id, email, name, photoUrl, username, gender];

  @override
  String toString() => 'User(id: $id, name: $name, username: $username)';
}
