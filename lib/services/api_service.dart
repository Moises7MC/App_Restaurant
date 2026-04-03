import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

class ApiService {
  static const String baseUrl = 'https://localhost:7235/api';

  // Permitir certificados SSL auto-firmados (solo para desarrollo)
  static final HttpClient httpClient = HttpClient()
    ..badCertificateCallback = (X509Certificate cert, String host, int port) =>
        true;

  // GET: Obtener todos los productos
  static Future<List<dynamic>> getProducts() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/product'));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error al cargar productos');
      }
    } catch (e) {
      print('Error: $e');
      rethrow;
    }
  }

  // POST: Crear una nueva orden
  static Future<dynamic> createOrder(Map<String, dynamic> orderData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/order'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(orderData),
      );

      print('Status: ${response.statusCode}');
      print('Response: ${response.body}');

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error al crear orden: ${response.body}');
      }
    } catch (e) {
      print('Error: $e');
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
}
