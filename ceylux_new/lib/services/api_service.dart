import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../models/stock_item.dart';
import '../models/customer.dart';
import '../models/order.dart';
import '../models/tier.dart';
import '../models/delivery_method.dart';
import '../models/payment_method.dart';

class ApiService {
  static final ApiService _instance = ApiService._();
  factory ApiService() => _instance;
  ApiService._();

  static const String baseUrl = 'https://ceylux23.perpova.cloud';

  final _uuid = const Uuid();
  final _client = http.Client();

  Stream<List<StockItem>> stockStream() async* {
    while (true) {
      try {
        final r = await _client.get(Uri.parse('$baseUrl/stock'));
        final list = jsonDecode(r.body) as List;
        yield list.map((m) => StockItem.fromMap(Map<String, dynamic>.from(m))).toList();
      } catch (_) { yield []; }
      await Future.delayed(const Duration(milliseconds: 1500));
    }
  }

  Future<void> addStockItem(StockItem item) async {
    final response = await _client.post(Uri.parse('$baseUrl/stock'),
        headers: {'Content-Type': 'application/json'}, body: jsonEncode(item.toMap()));
    if (response.statusCode != 200) {
      throw Exception('Failed to add stock: ${response.statusCode} - ${response.body}');
    }
  }

  Future<void> updateStockItem(StockItem item) async {
    final response = await _client.put(Uri.parse('$baseUrl/stock/${item.id}'),
        headers: {'Content-Type': 'application/json'}, body: jsonEncode(item.toMap()));
    if (response.statusCode != 200) {
      throw Exception('Failed to update stock: ${response.statusCode} - ${response.body}');
    }
  }

  Future<void> deleteStockItem(String id) async {
    final response = await _client.delete(Uri.parse('$baseUrl/stock/$id'));
    if (response.statusCode != 200) {
      throw Exception('Failed to delete stock: ${response.statusCode} - ${response.body}');
    }
  }

  Stream<List<Customer>> customersStream() async* {
    while (true) {
      try {
        final r = await _client.get(Uri.parse('$baseUrl/customers'));
        final list = jsonDecode(r.body) as List;
        yield list.map((m) => Customer.fromMap(Map<String, dynamic>.from(m))).toList();
      } catch (_) { yield []; }
      await Future.delayed(const Duration(milliseconds: 1500));
    }
  }

  Future<List<Customer>> getCustomers() async {
    try {
      final r = await _client.get(Uri.parse('$baseUrl/customers'));
      final list = jsonDecode(r.body) as List;
      return list.map((m) => Customer.fromMap(Map<String, dynamic>.from(m))).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> addCustomer(Customer c) async {
    final customerData = {
      'name': c.name,
      'phone': c.phone,
      'email': c.email,
      'address': c.address,
      'photo_url': c.photoUrl,
    };
    
    final response = await _client.post(Uri.parse('$baseUrl/customers'),
        headers: {'Content-Type': 'application/json'}, body: jsonEncode(customerData));
    
    if (response.statusCode != 200) {
      throw Exception('Failed to add customer: ${response.statusCode} - ${response.body}');
    }
  }

  Future<void> updateCustomer(Customer c) async {
    final customerData = {
      'name': c.name,
      'phone': c.phone,
      'email': c.email,
      'address': c.address,
      'photo_url': c.photoUrl,
      'owner_rating': c.ownerRating,
      'owner_note': c.ownerNote,
    };
    
    final response = await _client.put(Uri.parse('$baseUrl/customers/${c.id}'),
        headers: {'Content-Type': 'application/json'}, body: jsonEncode(customerData));
    if (response.statusCode != 200) {
      throw Exception('Failed to update customer: ${response.statusCode} - ${response.body}');
    }
  }

  Future<void> deleteCustomer(String id) async {
    final response = await _client.delete(Uri.parse('$baseUrl/customers/$id'));
    if (response.statusCode != 200) {
      throw Exception('Failed to delete customer: ${response.statusCode} - ${response.body}');
    }
  }

  Stream<List<AppOrder>> ordersStream() async* {
    while (true) {
      try {
        final r = await _client.get(Uri.parse('$baseUrl/orders'));
        final list = jsonDecode(r.body) as List;
        yield list.map((m) => AppOrder.fromMap(Map<String, dynamic>.from(m))).toList();
      } catch (_) { yield []; }
      await Future.delayed(const Duration(milliseconds: 1500));
    }
  }

  Future<void> addOrder(AppOrder o) async {
    final response = await _client.post(Uri.parse('$baseUrl/orders'),
        headers: {'Content-Type': 'application/json'}, body: jsonEncode(o.toMap()));
    if (response.statusCode != 200) {
      throw Exception('Failed to add order: ${response.statusCode} - ${response.body}');
    }
  }

  Future<void> updateOrderStatus(String id, String status) async {
    final response = await _client.put(Uri.parse('$baseUrl/orders/$id/status'),
        headers: {'Content-Type': 'application/json'}, body: jsonEncode({'status': status}));
    if (response.statusCode != 200) {
      throw Exception('Failed to update order status: ${response.statusCode} - ${response.body}');
    }
  }

  Future<void> updateOrder(String id, AppOrder order) async {
    final response = await _client.put(Uri.parse('$baseUrl/orders/$id'),
        headers: {'Content-Type': 'application/json'}, body: jsonEncode(order.toMap()));
    if (response.statusCode != 200) {
      throw Exception('Failed to update order: ${response.statusCode} - ${response.body}');
    }
  }

  Future<void> deleteOrder(String id) async {
    final response = await _client.delete(Uri.parse('$baseUrl/orders/$id'));
    if (response.statusCode != 200) {
      throw Exception('Failed to delete order: ${response.statusCode} - ${response.body}');
    }
  }

  Future<String> uploadPhoto(File file, String folder) async {
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/upload/$folder'));
    request.files.add(await http.MultipartFile.fromPath('photo', file.path));
    final response = await request.send();
    final body = await response.stream.bytesToString();
    return jsonDecode(body)['url'];
  }

  // User Profile Methods
  Future<Map<String, dynamic>> getUserProfile(String userId) async {
    try {
      final r = await _client.get(Uri.parse('$baseUrl/user/$userId'));
      if (r.statusCode == 200) {
        return jsonDecode(r.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return {};
  }

  Future<void> updateUserProfile(String userId, Map<String, dynamic> profileData) async {
    try {
      final response = await _client.put(
        Uri.parse('$baseUrl/user/$userId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(profileData),
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to update user profile: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to update user profile: $e');
    }
  }

  Future<void> uploadProfileImage(File file, String userId) async {
    try {
      final url = await uploadPhoto(file, 'profiles');
      await updateUserProfile(userId, {
        'profileImageUrl': url,
      });
    } catch (_) {}
  }

  Future<void> seedInitialData() async {
    try { await _client.post(Uri.parse('$baseUrl/seed')); } catch (_) {}
  }

  // Tier Management
  Stream<List<Tier>> tiersStream() async* {
    while (true) {
      try {
        final r = await _client.get(Uri.parse('$baseUrl/tiers'));
        final list = jsonDecode(r.body) as List;
        final tiers = list.map((m) => Tier.fromMap(Map<String, dynamic>.from(m))).toList();
        // Sort by priority descending (highest tier first)
        tiers.sort((a, b) => b.priority.compareTo(a.priority));
        yield tiers;
      } catch (_) { yield []; }
      await Future.delayed(const Duration(seconds: 3));
    }
  }

  Future<List<Tier>> getTiers() async {
    try {
      final r = await _client.get(Uri.parse('$baseUrl/tiers'));
      final list = jsonDecode(r.body) as List;
      final tiers = list.map((m) => Tier.fromMap(Map<String, dynamic>.from(m))).toList();
      tiers.sort((a, b) => b.priority.compareTo(a.priority));
      return tiers;
    } catch (_) { return []; }
  }

  Future<void> addTier(Tier tier) async {
    try {
      final response = await _client.post(Uri.parse('$baseUrl/tiers'),
        headers: {'Content-Type': 'application/json'}, body: jsonEncode(tier.toMap()));
      if (response.statusCode != 200) {
        throw Exception('Failed to add tier: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to add tier: $e');
    }
  }

  Future<void> updateTier(String tierId, Tier tier) async {
    try {
      final response = await _client.put(Uri.parse('$baseUrl/tiers/$tierId'),
        headers: {'Content-Type': 'application/json'}, body: jsonEncode(tier.toMap()));
      if (response.statusCode != 200) {
        throw Exception('Failed to update tier: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to update tier: $e');
    }
  }

  Future<void> deleteTier(String tierId) async {
    try {
      final response = await _client.delete(Uri.parse('$baseUrl/tiers/$tierId'));
      if (response.statusCode != 200) {
        throw Exception('Failed to delete tier: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to delete tier: $e');
    }
  }

  // Delivery Methods
  Stream<List<DeliveryMethod>> deliveryMethodsStream() async* {
    while (true) {
      try {
        final r = await _client.get(Uri.parse('$baseUrl/delivery-methods'));
        final list = jsonDecode(r.body) as List;
        yield list.map((m) => DeliveryMethod.fromMap(Map<String, dynamic>.from(m))).toList();
      } catch (_) { yield []; }
      await Future.delayed(const Duration(milliseconds: 1500));
    }
  }

  Future<List<DeliveryMethod>> getDeliveryMethods() async {
    try {
      final r = await _client.get(Uri.parse('$baseUrl/delivery-methods'));
      final list = jsonDecode(r.body) as List;
      return list.map((m) => DeliveryMethod.fromMap(Map<String, dynamic>.from(m))).toList();
    } catch (_) { return []; }
  }

  Future<void> addDeliveryMethod(DeliveryMethod method) async {
    final response = await _client.post(Uri.parse('$baseUrl/delivery-methods'),
        headers: {'Content-Type': 'application/json'}, body: jsonEncode(method.toMap()));
    if (response.statusCode != 200) {
      throw Exception('Failed to add delivery method: ${response.statusCode} - ${response.body}');
    }
  }

  Future<void> updateDeliveryMethod(String id, DeliveryMethod method) async {
    final response = await _client.put(Uri.parse('$baseUrl/delivery-methods/$id'),
        headers: {'Content-Type': 'application/json'}, body: jsonEncode(method.toMap()));
    if (response.statusCode != 200) {
      throw Exception('Failed to update delivery method: ${response.statusCode} - ${response.body}');
    }
  }

  Future<void> deleteDeliveryMethod(String id) async {
    final response = await _client.delete(Uri.parse('$baseUrl/delivery-methods/$id'));
    if (response.statusCode != 200) {
      throw Exception('Failed to delete delivery method: ${response.statusCode} - ${response.body}');
    }
  }

  Future<String> uploadPaymentProof(File file) async {
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/upload/payment-proofs'));
    request.files.add(await http.MultipartFile.fromPath('proof', file.path));
    final response = await request.send();
    final body = await response.stream.bytesToString();
    return jsonDecode(body)['url'];
  }

  // Payment Methods
  Stream<List<PaymentMethod>> paymentMethodsStream() async* {
    while (true) {
      try {
        final r = await _client.get(Uri.parse('$baseUrl/payment-methods'));
        final list = jsonDecode(r.body) as List;
        yield list.map((m) => PaymentMethod.fromJson(Map<String, dynamic>.from(m))).toList();
      } catch (_) { yield []; }
      await Future.delayed(const Duration(milliseconds: 1500));
    }
  }

  Future<List<PaymentMethod>> getPaymentMethods() async {
    try {
      final r = await _client.get(Uri.parse('$baseUrl/payment-methods'));
      final list = jsonDecode(r.body) as List;
      return list.map((m) => PaymentMethod.fromJson(Map<String, dynamic>.from(m))).toList();
    } catch (_) { return []; }
  }

  Future<void> addPaymentMethod(PaymentMethod method) async {
    final response = await _client.post(Uri.parse('$baseUrl/payment-methods'),
        headers: {'Content-Type': 'application/json'}, body: jsonEncode(method.toJson()));
    if (response.statusCode != 200) {
      throw Exception('Failed to add payment method: ${response.statusCode} - ${response.body}');
    }
  }

  Future<void> updatePaymentMethod(String id, PaymentMethod method) async {
    final response = await _client.put(Uri.parse('$baseUrl/payment-methods/$id'),
        headers: {'Content-Type': 'application/json'}, body: jsonEncode(method.toJson()));
    if (response.statusCode != 200) {
      throw Exception('Failed to update payment method: ${response.statusCode} - ${response.body}');
    }
  }

  Future<void> deletePaymentMethod(String id) async {
    final response = await _client.delete(Uri.parse('$baseUrl/payment-methods/$id'));
    if (response.statusCode != 200) {
      throw Exception('Failed to delete payment method: ${response.statusCode} - ${response.body}');
    }
  }

  Future<void> sendInvoiceEmail({
    required File pdfFile,
    required String senderEmail,
    required String senderPassword,
    required String recipientEmail,
    required String orderId,
  }) async {
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/orders/send-invoice-email'));
    request.files.add(await http.MultipartFile.fromPath('pdf', pdfFile.path));
    request.fields['senderEmail'] = senderEmail;
    request.fields['senderPassword'] = senderPassword;
    request.fields['recipientEmail'] = recipientEmail;
    request.fields['orderId'] = orderId;

    final response = await request.send();
    if (response.statusCode != 200) {
      final body = await response.stream.bytesToString();
      throw Exception('Failed to send email: ${response.statusCode} - $body');
    }
  }
}

