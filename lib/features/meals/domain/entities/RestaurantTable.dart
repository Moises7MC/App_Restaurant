import 'package:equatable/equatable.dart';

/// Entidad que representa una mesa en el restaurante
///
/// Cada mesa tiene:
/// - Un ID único
/// - Un número visible (1, 2, 3... 10)
/// - Una capacidad de personas
class RestaurantTable extends Equatable {
  /// Identificador único de la mesa
  final String id;

  /// Número de mesa visible (1, 2, 3... 10)
  final int number;

  /// Capacidad de personas que puede acomodar
  final int capacity;

  /// Constructor
  const RestaurantTable({
    required this.id,
    required this.number,
    required this.capacity,
  });

  /// Lista de propiedades para comparación (Equatable)
  @override
  List<Object?> get props => [id, number, capacity];

  /// Método toString para debugging
  @override
  String toString() =>
      'RestaurantTable(id: $id, number: $number, capacity: $capacity)';
}
