import 'dart:convert';

class StockItem {
  final String id;
  final String name;
  final String category;
  final String sku;
  final int minQty;
  final int price;
  final int cost;
  final int discount; // Discount percentage (0-100)
  final String emoji;
  final String? photoUrl;
  final Map<String, int> sizes;
  final DateTime createdAt;

  StockItem({required this.id, required this.name, required this.category,
    required this.sku, required this.minQty, required this.price,
    required this.cost, this.discount = 0, required this.emoji, this.photoUrl, required this.sizes,
    DateTime? createdAt}) : createdAt = createdAt ?? DateTime.now();

  int get totalQty => sizes.values.fold(0, (a, b) => a + b);
  bool get isLowStock => totalQty > 0 && totalQty < minQty;
  bool get isOutOfStock => totalQty == 0;

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.round();
    // MySQL DECIMAL returns strings like "6800.00" — parse via double
    return double.tryParse(v.toString())?.round() ?? 0;
  }

  factory StockItem.fromMap(Map<String, dynamic> m) {
    // sizes can be a double-encoded JSON string from MySQL or already a Map
    Map<String, int> parsedSizes = {};
    try {
      final raw = m['sizes'];
      if (raw != null) {
        final decoded = raw is String ? jsonDecode(raw) : raw;
        parsedSizes = Map<String, int>.from(
          (decoded as Map).map((k, v) => MapEntry(k.toString(), _toInt(v))),
        );
      }
    } catch (_) {}

    return StockItem(
      id: m['id']?.toString() ?? '',
      name: m['name'] ?? '',
      category: m['category'] ?? 'Men',
      sku: m['sku'] ?? '',
      minQty: _toInt(m['min_qty'] ?? 15),
      price: _toInt(m['price']),
      cost: _toInt(m['cost']),
      discount: _toInt(m['discount'] ?? 0),
      emoji: m['emoji'] ?? '👕',
      photoUrl: m['photo_url'],
      sizes: parsedSizes,
      createdAt: m['created_at'] != null 
        ? DateTime.parse(m['created_at'].toString()) 
        : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name, 'category': category, 'sku': sku,
    'min_qty': minQty, 'price': price, 'cost': cost, 'discount': discount,
    'emoji': emoji, 'photo_url': photoUrl, 'sizes': sizes,
    'created_at': createdAt.toIso8601String(),
  };

  StockItem copyWith({String? name, String? category, String? sku, int? minQty,
    int? price, int? cost, int? discount, String? emoji, String? photoUrl, Map<String, int>? sizes, DateTime? createdAt}) =>
      StockItem(id: id, name: name ?? this.name, category: category ?? this.category,
        sku: sku ?? this.sku, minQty: minQty ?? this.minQty, price: price ?? this.price,
        cost: cost ?? this.cost, discount: discount ?? this.discount, emoji: emoji ?? this.emoji,
        photoUrl: photoUrl ?? this.photoUrl, sizes: sizes ?? this.sizes,
        createdAt: createdAt ?? this.createdAt);
}
