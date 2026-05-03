import 'package:equatable/equatable.dart';

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

  int get pendingQuantity => quantity - servedQuantity;
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

class CantadorOrder extends Equatable {
  final int id;
  final int tableNumber;
  final String mealType;
  final String status;
  final String? waiterName;
  final int customerCount;
  final String? entradas;
  final List<String> entradasServidas; // ✅ nuevo
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
    this.entradasServidas = const [], // ✅ nuevo
    required this.isParaLlevar,
    required this.wasSung,
    required this.createdAt,
    required this.updatedAt,
    required this.items,
  });

  int get minutesInKitchen {
    final now = DateTime.now();
    return now.difference(createdAt.toLocal()).inMinutes;
  }

  int get pendingDishes => items.fold(0, (sum, i) => sum + i.pendingQuantity);
  bool get isCompletelyServed => items.every((i) => i.isFullyServed);

  factory CantadorOrder.fromJson(Map<String, dynamic> json) {
    // EntradasServidas puede venir como JSON string "["sopa","ensalada"]"
    // o como lista directa
    List<String> entradasServidas = [];
    final raw = json['entradasServidas'];
    if (raw != null) {
      if (raw is List) {
        entradasServidas = raw.map((e) => e.toString()).toList();
      } else if (raw is String && raw.isNotEmpty) {
        try {
          // Parsear el JSON string del backend
          final decoded = raw
              .replaceAll('[', '')
              .replaceAll(']', '')
              .split(',')
              .map((e) => e.trim().replaceAll('"', ''))
              .where((e) => e.isNotEmpty)
              .toList();
          entradasServidas = decoded;
        } catch (_) {}
      }
    }

    return CantadorOrder(
      id: json['id'] as int,
      tableNumber: json['tableNumber'] as int,
      mealType: (json['mealType'] as String?) ?? 'Almuerzo',
      status: (json['status'] as String?) ?? 'Pendiente',
      waiterName: json['waiterName'] as String?,
      customerCount: (json['customerCount'] as int?) ?? 1,
      entradas: json['entradas'] as String?,
      entradasServidas: entradasServidas, // ✅ nuevo
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
    entradasServidas,
  ];
}
