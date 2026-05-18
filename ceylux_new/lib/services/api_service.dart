import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../models/stock_item.dart';
import '../models/customer.dart';
import '../models/order.dart';

class ApiService {
  static final ApiService _instance = ApiService._();
  factory ApiService() => _instance;
  ApiService._();

  static const String baseUrl = 'http://10.179.188.120:3000';

  final _uuid = const Uuid();
  final _client = http.Client();

  Stream<List<StockItem>> stockStream() async* {
    while (true) {
      try {
        final r = await _client.get(Uri.parse('$baseUrl/stock'));
        final list = jsonDecode(r.body) as List;
        yield list.map((m) => StockItem.fromMap(Map<String, dynamic>.from(m))).toList();
      } catch (_) { yield []; }
      await Future.delayed(const Duration(seconds: 3));
    }
  }

  Future<void> addStockItem(StockItem item) async {
    await _client.post(Uri.parse('$baseUrl/stock'),
        headers: {'Content-Type': 'application/json'}, body: jsonEncode(item.toMap()));
  }

  Future<void> updateStockItem(StockItem item) async {
    await _client.put(Uri.parse('$baseUrl/stock/${item.id}'),
        headers: {'Content-Type': 'application/json'}, body: jsonEncode(item.toMap()));
  }

  Future<void> deleteStockItem(String id) async {
    await _client.delete(Uri.parse('$baseUrl/stock/$id'));
  }

  Stream<List<Customer>> customersStream() async* {
    while (true) {
      try {
        final r = await _client.get(Uri.parse('$baseUrl/customers'));
        final list = jsonDecode(r.body) as List;
        yield list.map((m) => Customer.fromMap(Map<String, dynamic>.from(m))).toList();
      } catch (_) { yield []; }
      await Future.delayed(const Duration(seconds: 3));
    }
  }

  Future<void> addCustomer(Customer c) async {
    await _client.post(Uri.parse('$baseUrl/customers'),
        headers: {'Content-Type': 'application/json'}, body: jsonEncode(c.toMap()));
  }

  Future<void> updateCustomer(Customer c) async {
    await _client.put(Uri.parse('$baseUrl/customers/${c.id}'),
        headers: {'Content-Type': 'application/json'}, body: jsonEncode(c.toMap()));
  }

  Future<void> deleteCustomer(String id) async {
    await _client.delete(Uri.parse('$baseUrl/customers/$id'));
  }

  Stream<List<AppOrder>> ordersStream() async* {
    while (true) {
      try {
        final r = await _client.get(Uri.parse('$baseUrl/orders'));
        final list = jsonDecode(r.body) as List;
        yield list.map((m) => AppOrder.fromMap(Map<String, dynamic>.from(m))).toList();
      } catch (_) { yield []; }
      await Future.delayed(const Duration(seconds: 3));
    }
  }

  Future<void> addOrder(AppOrder o) async {
    await _client.post(Uri.parse('$baseUrl/orders'),
        headers: {'Content-Type': 'application/json'}, body: jsonEncode(o.toMap()));
  }

  Future<void> updateOrderStatus(String id, String status) async {
    await _client.put(Uri.parse('$baseUrl/orders/$id/status'),
        headers: {'Content-Type': 'application/json'}, body: jsonEncode({'status': status}));
  }

  Future<String> uploadPhoto(File file, String folder) async {
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/upload/$folder'));
    request.files.add(await http.MultipartFile.fromPath('photo', file.path));
    final response = await request.send();
    final body = await response.stream.bytesToString();
    return jsonDecode(body)['url'];
  }

  Future<void> seedInitialData() async {
    try { await _client.post(Uri.parse('$baseUrl/seed')); } catch (_) {}
  }
}
