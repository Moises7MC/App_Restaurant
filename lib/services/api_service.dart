import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

class ApiService {
  // static const String baseUrl = 'https://app-restaurant-api.onrender.com/api';
  static const String baseUrl = 'http://localhost:5245/api';

  // HttpClient que ignora certificados SSL (para desarrollo)
  static HttpClient _getHttpClient() {
    final httpClient = HttpClient();
    httpClient.badCertificateCallback = (cert, host, port) => true;
    return httpClient;
  }

  // GET: Obtener todos los productos
  static Future<List<dynamic>> getProducts() async {
    try {
      print('📡 Conectando a: $baseUrl/product');
      final response = await http.get(Uri.parse('$baseUrl/product'));
      print('✓ Respuesta: ${response.statusCode}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error: ${response.statusCode}');
      }
    } catch (e) {
      print('✗ Error getProducts: $e');
      rethrow;
    }
  }

  // POST: Crear una nueva orden
  static Future<dynamic> createOrder(Map<String, dynamic> orderData) async {
    try {
      print('📡 Enviando orden a: $baseUrl/order');

      final response = await http
          .post(
            Uri.parse('$baseUrl/order'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(orderData),
          )
          .timeout(const Duration(seconds: 60)); // ← aumentar timeout

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error: ${response.body}');
      }
    } catch (e) {
      print('✗ Error createOrder: $e');
      rethrow;
    }
  }

  // POST: Agregar item a una orden
  static Future<dynamic> addItemToOrder(
    int orderId,
    Map<String, dynamic> itemData,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/order/$orderId/item'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(itemData),
      );
      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error al agregar item');
      }
    } catch (e) {
      print('Error: $e');
      rethrow;
    }
  }

  // PUT: Actualizar estado de orden
  static Future<void> updateOrderStatus(int orderId, String status) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/order/$orderId/status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(status),
      );
      if (response.statusCode != 204) {
        throw Exception('Error al actualizar orden');
      }
    } catch (e) {
      print('Error: $e');
      rethrow;
    }
  }

  // GET: Obtener órdenes por mesa
  static Future<List<dynamic>> getOrdersByTable(int tableNumber) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/order/table/$tableNumber'),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error al cargar órdenes');
      }
    } catch (e) {
      print('Error: $e');
      rethrow;
    }
  }

  // GET: Obtener resumen de transacciones
  static Future<dynamic> getTransactionSummary() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/transaction/summary'),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error al cargar resumen');
      }
    } catch (e) {
      print('Error: $e');
      rethrow;
    }
  }

  // POST: Crear transacción
  static Future<dynamic> createTransaction(
    Map<String, dynamic> transactionData,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/transaction'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(transactionData),
      );
      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error al crear transacción');
      }
    } catch (e) {
      print('Error: $e');
      rethrow;
    }
  }

  // GET: Obtener última orden pendiente de una mesa hoy
  static Future<dynamic> getLastPendingOrder(int tableNumber) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/order/table/$tableNumber'),
      );

      if (response.statusCode == 200) {
        List<dynamic> orders = jsonDecode(response.body);

        // Filtrar por hoy y estado pendiente
        DateTime today = DateTime.now();
        var todayOrders = orders.where((o) {
          DateTime createdAt = DateTime.parse(o['createdAt']).toLocal();
          return createdAt.day == today.day &&
              createdAt.month == today.month &&
              createdAt.year == today.year &&
              (o['status'] == 'Enviado a cocina' || o['status'] == 'Pendiente');
        }).toList();

        return todayOrders.isNotEmpty ? todayOrders.last : null;
      }
      return null;
    } catch (e) {
      print('Error: $e');
      return null;
    }
  }

  // POST: Agregar items a una orden existente
  static Future<dynamic> addItemToExistingOrder(
    int orderId,
    List<Map<String, dynamic>> items,
  ) async {
    try {
      // Un solo request con todos los items juntos
      final response = await http.post(
        Uri.parse('$baseUrl/order/$orderId/items-batch'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(items),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error agregando items: ${response.body}');
      }
    } catch (e) {
      print('Error: $e');
      rethrow;
    }
  }

  // PUT: Actualizar total de orden
  static Future<void> updateOrderTotal(int orderId, double total) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/order/$orderId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'total': total}),
      );
      if (response.statusCode != 204) {
        throw Exception('Error al actualizar total');
      }
    } catch (e) {
      print('Error: $e');
      rethrow;
    }
  }

  // GET: Obtener todas las órdenes activas de hoy
  static Future<List<int>> getOccupiedTableNumbers() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/order'));
      if (response.statusCode == 200) {
        List<dynamic> orders = jsonDecode(response.body);
        DateTime today = DateTime.now();

        // Filtrar órdenes de hoy que estén activas
        var activeOrders = orders.where((o) {
          DateTime createdAt = DateTime.parse(o['createdAt']).toLocal();
          return createdAt.day == today.day &&
              createdAt.month == today.month &&
              createdAt.year == today.year &&
              (o['status'] == 'Enviado a cocina' || o['status'] == 'Pendiente');
        }).toList();

        // Retornar solo los números de mesa
        return activeOrders
            .map<int>((o) => o['tableNumber'] as int)
            .toSet()
            .toList();
      }
      return [];
    } catch (e) {
      print('Error getOccupiedTableNumbers: $e');
      return [];
    }
  }
}
