import 'package:equatable/equatable.dart';

/// Item de una orden tal como lo ve el cantador.
class CantadorOrderItem extends Equatable {
  final int id;
  final int productId;
  final String productName;
  final int quantity;
  final int servedQuantity;

  const CantadorOrderItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.servedQuantity,
  });

  /// Cuántas unidades faltan por servir
  int get pendingQuantity => quantity - servedQuantity;

  /// Si todas las unidades de este item ya fueron servidas
  bool get isFullyServed => servedQuantity >= quantity;

  factory CantadorOrderItem.fromJson(Map<String, dynamic> json) {
    return CantadorOrderItem(
      id: json['id'] as int,
      productId: json['productId'] as int,
      productName:
          (json['product']?['name'] as String?) ??
          'Producto #${json['productId']}',
      quantity: json['quantity'] as int,
      servedQuantity: (json['servedQuantity'] as int?) ?? 0,
    );
  }

  @override
  List<Object?> get props => [
    id,
    productId,
    productName,
    quantity,
    servedQuantity,
  ];
}

/// Orden tal como la ve el cantador.
class CantadorOrder extends Equatable {
  final int id;
  final int tableNumber;
  final String mealType;
  final String status;
  final String? waiterName;
  final int customerCount;
  final String? entradas;
  final bool isParaLlevar;
  final bool wasSung;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<CantadorOrderItem> items;

  const CantadorOrder({
    required this.id,
    required this.tableNumber,
    required this.mealType,
    required this.status,
    this.waiterName,
    required this.customerCount,
    this.entradas,
    required this.isParaLlevar,
    required this.wasSung,
    required this.createdAt,
    required this.updatedAt,
    required this.items,
  });

  /// Cuántos minutos lleva esta orden en cocina
  int get minutesInKitchen {
    final now = DateTime.now();
    return now.difference(createdAt.toLocal()).inMinutes;
  }

  /// Cuántos platos faltan por servir
  int get pendingDishes => items.fold(0, (sum, i) => sum + i.pendingQuantity);

  /// Si todos los platos ya fueron servidos
  bool get isCompletelyServed => items.every((i) => i.isFullyServed);

  factory CantadorOrder.fromJson(Map<String, dynamic> json) {
    return CantadorOrder(
      id: json['id'] as int,
      tableNumber: json['tableNumber'] as int,
      mealType: (json['mealType'] as String?) ?? 'Almuerzo',
      status: (json['status'] as String?) ?? 'Pendiente',
      waiterName: json['waiterName'] as String?,
      customerCount: (json['customerCount'] as int?) ?? 1,
      entradas: json['entradas'] as String?,
      isParaLlevar: (json['isParaLlevar'] as bool?) ?? false,
      wasSung: (json['wasSung'] as bool?) ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      items: (json['items'] as List<dynamic>? ?? [])
          .map((i) => CantadorOrderItem.fromJson(i as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [
    id,
    tableNumber,
    status,
    wasSung,
    items,
    updatedAt,
  ];
}
