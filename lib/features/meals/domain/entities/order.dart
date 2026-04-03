class Order {
  final int? id;
  final int tableNumber;
  final String mealType;
  final List<OrderItem> items;
  final double total;
  final String status;
  final DateTime createdAt;

  Order({
    this.id,
    required this.tableNumber,
    required this.mealType,
    required this.items,
    required this.total,
    this.status = 'Pendiente',
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'tableNumber': tableNumber,
      'mealType': mealType,
      'items': items.map((i) => i.toJson()).toList(),
      'total': total,
      'status': status,
    };
  }
}

class OrderItem {
  final int? id;
  final int productId;
  final String productName;
  final int quantity;
  final double unitPrice;

  OrderItem({
    this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
  });

  double get total => quantity * unitPrice;

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'quantity': quantity,
      'unitPrice': unitPrice,
    };
  }
}
