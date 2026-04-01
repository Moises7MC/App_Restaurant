import 'package:equatable/equatable.dart';

/// Entidad que representa un producto (plato) en el restaurante
///
/// Cada producto tiene:
/// - Un ID único
/// - Nombre del plato
/// - Precio
/// - Descripción
/// - Imagen
/// - Categoría (Almuerzo, Desayuno, Cena)
class Product extends Equatable {
  /// Identificador único del producto
  final String id;

  /// Nombre del plato
  final String name;

  /// Precio del plato
  final double price;

  /// Descripción del plato
  final String description;

  /// URL o ruta de la imagen del plato
  final String imageUrl;

  /// Categoría: "Almuerzo", "Desayuno", "Cena"
  final String category;

  /// Constructor
  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.description,
    required this.imageUrl,
    required this.category,
  });

  /// Lista de propiedades para comparación (Equatable)
  @override
  List<Object?> get props => [id, name, price, description, imageUrl, category];

  /// Método toString para debugging
  @override
  String toString() {
    return 'Product(id: $id, name: $name, price: $price, category: $category)';
  }
}
