import 'package:app_restaurant/core/config/api_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  // static const String baseUrl = 'http://localhost:5245/api';
  // static const String baseUrl = 'https://app-restaurant-api.onrender.com/api';
  static String get baseUrl => ApiConfig.baseUrl;

  // ════════════════════════════════════════════════════════════
  // AUTH
  // ════════════════════════════════════════════════════════════
  static Future<Map<String, dynamic>> loginWaiter(
    String username,
    String password,
  ) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/auth/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'username': username, 'password': password}),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else if (response.statusCode == 401) {
      throw Exception('Credenciales incorrectas o usuario inactivo');
    } else {
      throw Exception('Error del servidor: ${response.statusCode}');
    }
  }

  // ════════════════════════════════════════════════════════════
  // PRODUCTOS
  // ════════════════════════════════════════════════════════════
  static Future<List<dynamic>> getProducts() async {
    final response = await http.get(Uri.parse('$baseUrl/product'));
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Error: ${response.statusCode}');
  }

  // ════════════════════════════════════════════════════════════
  // ÓRDENES
  // ════════════════════════════════════════════════════════════

  /// Crea una orden nueva — incluye el nombre del mozo
  static Future<dynamic> createOrder(Map<String, dynamic> orderData) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/order'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(orderData),
        )
        .timeout(const Duration(seconds: 60));

    if (response.statusCode == 201) return jsonDecode(response.body);
    throw Exception('Error: ${response.body}');
  }

  static Future<dynamic> addItemToOrder(
    int orderId,
    Map<String, dynamic> itemData,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/order/$orderId/item'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(itemData),
    );
    if (response.statusCode == 201) return jsonDecode(response.body);
    throw Exception('Error al agregar item');
  }

  static Future<void> updateOrderStatus(int orderId, String status) async {
    final response = await http.put(
      Uri.parse('$baseUrl/order/$orderId/status'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(status),
    );
    if (response.statusCode != 204)
      throw Exception('Error al actualizar orden');
  }

  static Future<List<dynamic>> getOrdersByTable(int tableNumber) async {
    final response = await http.get(
      Uri.parse('$baseUrl/order/table/$tableNumber'),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Error al cargar órdenes');
  }

  static Future<dynamic> getLastPendingOrder(
    int tableNumber, {
    bool isParaLlevar = false,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/order/table/$tableNumber'),
      );
      if (response.statusCode == 200) {
        List<dynamic> orders = jsonDecode(response.body);
        DateTime today = DateTime.now();
        var todayOrders = orders.where((o) {
          DateTime createdAt = DateTime.parse(o['createdAt']).toLocal();
          return createdAt.day == today.day &&
              createdAt.month == today.month &&
              createdAt.year == today.year &&
              (o['status'] == 'Enviado a cocina' ||
                  o['status'] == 'Pendiente') &&
              (o['isParaLlevar'] ?? false) == isParaLlevar;
        }).toList();
        return todayOrders.isNotEmpty ? todayOrders.last : null;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Agrega items a una orden existente — incluye el nombre del mozo
  static Future<dynamic> addItemToExistingOrder(
    int orderId,
    List<Map<String, dynamic>> items,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/order/$orderId/items-batch'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(items),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Error agregando items: ${response.body}');
  }

  static Future<List<int>> getOccupiedTableNumbers() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/order'));
      if (response.statusCode == 200) {
        List<dynamic> orders = jsonDecode(response.body);
        DateTime today = DateTime.now();
        var activeOrders = orders.where((o) {
          DateTime createdAt = DateTime.parse(o['createdAt']).toLocal();
          return createdAt.day == today.day &&
              createdAt.month == today.month &&
              createdAt.year == today.year &&
              (o['status'] == 'Enviado a cocina' || o['status'] == 'Pendiente');
        }).toList();
        return activeOrders
            .map<int>((o) => o['tableNumber'] as int)
            .toSet()
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<dynamic> updateItemQuantity(
    int orderId,
    int itemId,
    int newQuantity,
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl/order/$orderId/item/$itemId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'quantity': newQuantity}),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Error al modificar item: ${response.body}');
  }

  static Future<dynamic> removeItemFromOrder(int orderId, int itemId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/order/$orderId/item/$itemId'),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Error al eliminar item: ${response.body}');
  }

  static Future<List<dynamic>> getProductsByCategory() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/product/by-category'),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error: ${response.statusCode}');
      }
    } catch (e) {
      print('✗ Error getProductsByCategory: $e');
      rethrow;
    }
  }

  static Future<List<dynamic>> getTablesByFloor() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/table/by-floor'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getTablesByFloor: $e');
      rethrow;
    }
  }

  static Future<List<dynamic>> getTodayEntradas() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/entrada/today'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // ════════════════════════════════════════════════════════════
  // ✅ NUEVO — CANTADOR
  // ════════════════════════════════════════════════════════════

  /// Tab "POR CANTIDADES" — entradas + segundos agregados de hoy.
  /// Devuelve: { entradas: [...], segundos: [...] }
  static Future<Map<String, dynamic>> getCantadorAggregated() async {
    final response = await http
        .get(Uri.parse('$baseUrl/cantador/aggregated'))
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Error al cargar vista agregada: ${response.statusCode}');
  }

  /// Tab "POR MESA" — órdenes activas del día (Pendiente/Enviado a cocina).
  static Future<List<dynamic>> getCantadorOrders() async {
    final response = await http
        .get(Uri.parse('$baseUrl/cantador/orders'))
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }
    throw Exception('Error al cargar órdenes activas: ${response.statusCode}');
  }

  /// Tab "HISTORIAL" — órdenes ya servidas/cobradas/canceladas del día.
  static Future<List<dynamic>> getCantadorHistory() async {
    final response = await http
        .get(Uri.parse('$baseUrl/cantador/history'))
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }
    throw Exception('Error al cargar historial: ${response.statusCode}');
  }

  /// Descuenta 1 plato del producto indicado (FIFO: primera mesa pendiente).
  /// Se usa cuando el cantador toca [-] en el tab "POR CANTIDADES".
  /// Devuelve info de la orden afectada (orderId, tableNumber, remaining, completed).
  static Future<Map<String, dynamic>> serveItem(int productId) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/cantador/serve-item'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'productId': productId}),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Error al descontar plato: ${response.body}');
  }

  /// Descuenta 1 unidad de un OrderItem específico.
  /// Se usa cuando el cantador toca [-] en el tab "POR MESA" sobre un plato concreto.
  static Future<Map<String, dynamic>> serveItemById(int orderItemId) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/cantador/serve-item-by-id/$orderItemId'),
          headers: {'Content-Type': 'application/json'},
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Error al descontar item: ${response.body}');
  }

  /// Marca una orden como ya cantada al chef.
  /// Se usa cuando el cantador toca "Cantado al chef" en el tab "POR MESA".
  static Future<Map<String, dynamic>> markOrderAsSung(int orderId) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/cantador/$orderId/cantado'),
          headers: {'Content-Type': 'application/json'},
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Error al marcar como cantado: ${response.body}');
  }
}
