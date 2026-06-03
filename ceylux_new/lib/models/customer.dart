class Customer {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String address;
  final int totalOrders;
  final int totalSpent;
  final String? photoUrl;
  final double ownerRating;  // 0-5 — owner only sees this
  final String ownerNote;    // private note — owner only
  final double outstandingBalance;
  final double totalPaid;
  final double remainingDue;

  Customer({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.address,
    required this.totalOrders,
    required this.totalSpent,
    this.photoUrl,
    this.ownerRating = 0,
    this.ownerNote = '',
    this.outstandingBalance = 0.0,
    this.totalPaid = 0.0,
    this.remainingDue = 0.0,
  });

  @override
  bool operator ==(Object other) => other is Customer && other.id == id;
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

  factory Customer.fromMap(Map<String, dynamic> m) {
    final outstanding = _toDouble(m['total_outstanding']);
    final paid = _toDouble(m['total_paid']);
    return Customer(
      id: m['id']?.toString() ?? '',
      name: m['name'] ?? '',
      phone: m['phone'] ?? '',
      email: m['email'] ?? '',
      address: m['address'] ?? '',
      totalOrders: _toInt(m['total_orders']),
      totalSpent: _toInt(m['total_spent']),
      photoUrl: m['photo_url'],
      ownerRating: _toDouble(m['owner_rating']),
      ownerNote: m['owner_note'] ?? '',
      outstandingBalance: outstanding,
      totalPaid: paid,
      remainingDue: outstanding - paid,
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'phone': phone,
    'email': email,
    'address': address,
    'photo_url': photoUrl,
    'owner_rating': ownerRating,
    'owner_note': ownerNote,
    'total_outstanding': outstandingBalance,
    'total_paid': totalPaid,
  };

  Customer copyWith({
    String? name, String? phone, String? email, String? address,
    int? totalOrders, int? totalSpent, String? photoUrl,
    double? ownerRating, String? ownerNote,
    double? outstandingBalance, double? totalPaid, double? remainingDue,
  }) => Customer(
    id: id,
    name: name ?? this.name,
    phone: phone ?? this.phone,
    email: email ?? this.email,
    address: address ?? this.address,
    totalOrders: totalOrders ?? this.totalOrders,
    totalSpent: totalSpent ?? this.totalSpent,
    photoUrl: photoUrl ?? this.photoUrl,
    ownerRating: ownerRating ?? this.ownerRating,
    ownerNote: ownerNote ?? this.ownerNote,
    outstandingBalance: outstandingBalance ?? this.outstandingBalance,
    totalPaid: totalPaid ?? this.totalPaid,
    remainingDue: remainingDue ?? this.remainingDue,
  );
}