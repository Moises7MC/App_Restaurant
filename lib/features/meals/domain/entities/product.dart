import 'package:equatable/equatable.dart';

class Product extends Equatable {
  final int id;
  final String name;
  final double price;
  final String description;
  final String imageUrl;
  final String category;
  final bool isEntrada; // ✅ NUEVO

  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.description,
    required this.imageUrl,
    required this.category,
    this.isEntrada = false, // opcional, default false
  });

  @override
  List<Object?> get props => [
    id,
    name,
    price,
    description,
    imageUrl,
    category,
    isEntrada,
  ];

  @override
  String toString() {
    return 'Product(id: $id, name: $name, price: $price, category: $category, isEntrada: $isEntrada)';
  }
}
