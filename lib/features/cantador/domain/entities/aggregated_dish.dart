import 'package:equatable/equatable.dart';

/// Plato agregado en la vista "POR CANTIDADES".
///
/// Suma las unidades pendientes (Quantity - ServedQuantity) de todas
/// las mesas activas para un mismo producto.
///
/// Ej: M10 pidió 2 lomos + M12 pidió 3 lomos → AggregatedDish con
///   productId=5, productName="Lomo saltado", pendingQuantity=5,
///   pendingTables=["M10×2","M12×3"].
class AggregatedDish extends Equatable {
  final int productId;
  final String productName;
  final int pendingQuantity;
  final List<String> pendingTables;

  const AggregatedDish({
    required this.productId,
    required this.productName,
    required this.pendingQuantity,
    required this.pendingTables,
  });

  factory AggregatedDish.fromJson(Map<String, dynamic> json) {
    return AggregatedDish(
      productId: json['productId'] as int,
      productName: json['productName'] as String,
      pendingQuantity: json['pendingQuantity'] as int,
      pendingTables: List<String>.from(json['pendingTables'] ?? []),
    );
  }

  @override
  List<Object?> get props => [
    productId,
    productName,
    pendingQuantity,
    pendingTables,
  ];

  @override
  String toString() =>
      'AggregatedDish($productName x$pendingQuantity, mesas: $pendingTables)';
}
