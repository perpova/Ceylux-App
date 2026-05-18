class StockItem {
  final String id;
  final String name;
  final String category;
  final String sku;
  final int minQty;
  final int price;
  final int cost;
  final String emoji;
  final String? photoUrl;
  final Map<String, int> sizes;

  StockItem({required this.id, required this.name, required this.category,
    required this.sku, required this.minQty, required this.price,
    required this.cost, required this.emoji, this.photoUrl, required this.sizes});

  int get totalQty => sizes.values.fold(0, (a, b) => a + b);
  bool get isLowStock => totalQty > 0 && totalQty < minQty;
  bool get isOutOfStock => totalQty == 0;

  factory StockItem.fromMap(Map<String, dynamic> m) => StockItem(
    id: m['id']?.toString() ?? '',
    name: m['name'] ?? '',
    category: m['category'] ?? 'Men',
    sku: m['sku'] ?? '',
    minQty: m['min_qty'] ?? 15,
    price: m['price'] ?? 0,
    cost: m['cost'] ?? 0,
    emoji: m['emoji'] ?? '👕',
    photoUrl: m['photo_url'],
    sizes: m['sizes'] != null
        ? Map<String, int>.from((m['sizes'] as Map).map((k, v) => MapEntry(k.toString(), (v as num).toInt())))
        : {},
  );

  Map<String, dynamic> toMap() => {
    'name': name, 'category': category, 'sku': sku,
    'min_qty': minQty, 'price': price, 'cost': cost,
    'emoji': emoji, 'photo_url': photoUrl, 'sizes': sizes,
  };

  StockItem copyWith({String? name, String? category, String? sku, int? minQty,
    int? price, int? cost, String? emoji, String? photoUrl, Map<String, int>? sizes}) =>
      StockItem(id: id, name: name ?? this.name, category: category ?? this.category,
        sku: sku ?? this.sku, minQty: minQty ?? this.minQty, price: price ?? this.price,
        cost: cost ?? this.cost, emoji: emoji ?? this.emoji,
        photoUrl: photoUrl ?? this.photoUrl, sizes: sizes ?? this.sizes);
}
