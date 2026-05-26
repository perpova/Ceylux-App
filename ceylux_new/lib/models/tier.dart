class Tier {
  final String id;
  final String name;
  final String emoji;
  final int minOrders;
  final int minSpent;
  final double minRating;
  final int discountPercentage;
  final int priority; // Higher priority = higher tier

  Tier({
    required this.id,
    required this.name,
    required this.emoji,
    required this.minOrders,
    required this.minSpent,
    required this.minRating,
    required this.discountPercentage,
    required this.priority,
  });

  @override
  bool operator ==(Object other) => other is Tier && other.id == id;
  @override
  int get hashCode => id.hashCode;

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.round();
    return int.tryParse(v.toString().split('.').first) ?? 0;
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  factory Tier.fromMap(Map<String, dynamic> m) => Tier(
    id: m['id']?.toString() ?? '',
    name: m['name'] ?? '',
    emoji: m['emoji'] ?? '',
    minOrders: _toInt(m['min_orders']),
    minSpent: _toInt(m['min_spent']),
    minRating: _toDouble(m['min_rating']),
    discountPercentage: _toInt(m['discount_percentage']),
    priority: _toInt(m['priority']),
  );

  Map<String, dynamic> toMap() => {
    'name': name,
    'emoji': emoji,
    'min_orders': minOrders,
    'min_spent': minSpent,
    'min_rating': minRating,
    'discount_percentage': discountPercentage,
    'priority': priority,
  };

  Tier copyWith({
    String? id,
    String? name,
    String? emoji,
    int? minOrders,
    int? minSpent,
    double? minRating,
    int? discountPercentage,
    int? priority,
  }) => Tier(
    id: id ?? this.id,
    name: name ?? this.name,
    emoji: emoji ?? this.emoji,
    minOrders: minOrders ?? this.minOrders,
    minSpent: minSpent ?? this.minSpent,
    minRating: minRating ?? this.minRating,
    discountPercentage: discountPercentage ?? this.discountPercentage,
    priority: priority ?? this.priority,
  );
}
