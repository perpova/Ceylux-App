import 'dart:convert';

class OrderItem {
  final String name;
  final int qty;
  final int price;
  final String size;
  final int discount; // Discount percentage (0-100)

  OrderItem({required this.name, required this.qty, required this.price, required this.size, this.discount = 0});

  factory OrderItem.fromMap(Map<String, dynamic> m) => OrderItem(
    name: m['name'] ?? '', qty: m['qty'] ?? 1,
    price: m['price'] ?? 0, size: m['size'] ?? '', discount: m['discount'] ?? 0);

  Map<String, dynamic> toMap() => {'name': name, 'qty': qty, 'price': price, 'size': size, 'discount': discount};
  int get subtotal => qty * price;
  int get discountAmount => (subtotal * discount) ~/ 100;
  int get total => subtotal - discountAmount;
}

class AppOrder {
  final String dbId;
  final String id;
  final String customerId;
  final String customerName;
  final String? customerAddress;
  final String? customerPhone;
  final List<OrderItem> items;
  final int total;
  final String status;
  final String date;
  final int discountPercentage; // Bill discount percentage
  final int loyaltyDiscount; // Loyalty discount percentage (from customer tier)
  final String? deliveryMethodId;
  final String? deliveryMethodName;
  final String? paymentProofUrl;
  final String? deliveryNotes;
  final String? paymentMethodId;
  final String? paymentMethodName;

  AppOrder({required this.dbId, required this.id, required this.customerId, required this.customerName,
    this.customerAddress, this.customerPhone, required this.items, required this.total, required this.status, required this.date, this.discountPercentage = 0, this.loyaltyDiscount = 0,
    this.deliveryMethodId, this.deliveryMethodName, this.paymentProofUrl, this.deliveryNotes, this.paymentMethodId, this.paymentMethodName});

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.round();
    return int.tryParse(v.toString().split('.').first) ?? 0;
  }

  factory AppOrder.fromMap(Map<String, dynamic> m) {
    // items can be a double-encoded JSON string from MySQL or already a List
    List<OrderItem> parsedItems = [];
    try {
      final raw = m['items'];
      if (raw != null) {
        final decoded = raw is String ? jsonDecode(raw) : raw;
        parsedItems = (decoded as List)
            .map((e) => OrderItem.fromMap(Map<String, dynamic>.from(e)))
            .toList();
      }
    } catch (_) {}

    final dbId = m['id']?.toString() ?? '';
    // Use order_ref if available (the human-readable ID), fallback to DB id
    final displayId = (m['order_ref'] != null && m['order_ref'].toString().isNotEmpty)
        ? m['order_ref'].toString()
        : dbId;

    return AppOrder(
      dbId: dbId,
      id: displayId,
      customerId: m['customer_id']?.toString() ?? '',
      customerName: m['customer_name'] ?? '',
      customerAddress: m['customer_address']?.toString(),
      customerPhone: m['customer_phone']?.toString(),
      items: parsedItems,
      total: _toInt(m['total']),
      status: m['status'] ?? 'Pending',
      date: m['date']?.toString().length != null && m['date'].toString().length >= 10
          ? m['date'].toString().substring(0, 10)
          : m['date']?.toString() ?? '',
      discountPercentage: _toInt(m['discount_percentage']),
      loyaltyDiscount: _toInt(m['loyalty_discount']),
      deliveryMethodId: m['delivery_method_id']?.toString(),
      deliveryMethodName: m['delivery_method_name']?.toString(),
      paymentProofUrl: m['payment_proof_url']?.toString(),
      deliveryNotes: m['delivery_notes']?.toString(),
      paymentMethodId: m['payment_method_id']?.toString(),
      paymentMethodName: m['payment_method_name']?.toString(),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': dbId, 'order_ref': id, 'customer_id': customerId,
    'customer_name': customerName,
    'customer_address': customerAddress,
    'customer_phone': customerPhone,
    'items': items.map((e) => e.toMap()).toList(),
    'total': total, 'status': status, 'date': date, 'discount_percentage': discountPercentage, 'loyalty_discount': loyaltyDiscount,
    'delivery_method_id': deliveryMethodId,
    'delivery_method_name': deliveryMethodName,
    'payment_proof_url': paymentProofUrl,
    'delivery_notes': deliveryNotes,
    'payment_method_id': paymentMethodId,
    'payment_method_name': paymentMethodName,
  };

  AppOrder copyWith({String? status, String? deliveryMethodId, String? deliveryMethodName, String? paymentProofUrl, String? deliveryNotes, String? paymentMethodId, String? paymentMethodName}) => AppOrder(
    dbId: dbId,
    id: id, customerId: customerId, customerName: customerName,
    items: items, total: total, status: status ?? this.status, date: date, discountPercentage: discountPercentage, loyaltyDiscount: loyaltyDiscount,
    deliveryMethodId: deliveryMethodId ?? this.deliveryMethodId,
    deliveryMethodName: deliveryMethodName ?? this.deliveryMethodName,
    paymentProofUrl: paymentProofUrl ?? this.paymentProofUrl,
    deliveryNotes: deliveryNotes ?? this.deliveryNotes,
    paymentMethodId: paymentMethodId ?? this.paymentMethodId,
    paymentMethodName: paymentMethodName ?? this.paymentMethodName);
}
