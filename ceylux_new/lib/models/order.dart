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

  factory AppOrder.fromMap(Map<String, dynamic> m) => AppOrder(
    id: m['id']?.toString() ?? '',
    customerId: m['customer_id']?.toString() ?? '',
    customerName: m['customer_name'] ?? '',
    items: (m['items'] as List<dynamic>? ?? [])
        .map((e) => OrderItem.fromMap(Map<String, dynamic>.from(e))).toList(),
    total: m['total'] ?? 0,
    status: m['status'] ?? 'Pending',
    date: m['date']?.toString().substring(0, 10) ?? '',
  );

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
