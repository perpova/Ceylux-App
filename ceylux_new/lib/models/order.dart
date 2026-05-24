import 'dart:convert';

class OrderItem {
  final String name;
  final int qty;
  final int price;
  final String size;

  OrderItem({required this.name, required this.qty, required this.price, required this.size});

  factory OrderItem.fromMap(Map<String, dynamic> m) => OrderItem(
    name: m['name'] ?? '', qty: m['qty'] ?? 1,
    price: m['price'] ?? 0, size: m['size'] ?? '');

  Map<String, dynamic> toMap() => {'name': name, 'qty': qty, 'price': price, 'size': size};
  int get subtotal => qty * price;
}

class AppOrder {
  final String id;
  final String customerId;
  final String customerName;
  final List<OrderItem> items;
  final int total;
  final String status;
  final String date;

  AppOrder({required this.id, required this.customerId, required this.customerName,
    required this.items, required this.total, required this.status, required this.date});

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

    // Use order_ref if available (the human-readable ID), fallback to DB id
    final displayId = (m['order_ref'] != null && m['order_ref'].toString().isNotEmpty)
        ? m['order_ref'].toString()
        : m['id']?.toString() ?? '';

    return AppOrder(
      id: displayId,
      customerId: m['customer_id']?.toString() ?? '',
      customerName: m['customer_name'] ?? '',
      items: parsedItems,
      total: _toInt(m['total']),
      status: m['status'] ?? 'Pending',
      date: m['date']?.toString().length != null && m['date'].toString().length >= 10
          ? m['date'].toString().substring(0, 10)
          : m['date']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'order_ref': id, 'customer_id': customerId,
    'customer_name': customerName,
    'items': items.map((e) => e.toMap()).toList(),
    'total': total, 'status': status, 'date': date,
  };

  AppOrder copyWith({String? status}) => AppOrder(
    id: id, customerId: customerId, customerName: customerName,
    items: items, total: total, status: status ?? this.status, date: date);
}
