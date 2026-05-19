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
  });

  @override
  bool operator ==(Object other) => other is Customer && other.id == id;
  @override
  int get hashCode => id.hashCode;

  factory Customer.fromMap(Map<String, dynamic> m) => Customer(
    id: m['id']?.toString() ?? '',
    name: m['name'] ?? '',
    phone: m['phone'] ?? '',
    email: m['email'] ?? '',
    address: m['address'] ?? '',
    totalOrders: m['total_orders'] ?? 0,
    totalSpent: m['total_spent'] ?? 0,
    photoUrl: m['photo_url'],
    ownerRating: (m['owner_rating'] ?? 0).toDouble(),
    ownerNote: m['owner_note'] ?? '',
  );

  Map<String, dynamic> toMap() => {
    'name': name,
    'phone': phone,
    'email': email,
    'address': address,
    'photo_url': photoUrl,
    'owner_rating': ownerRating,
    'owner_note': ownerNote,
  };

  Customer copyWith({
    String? name, String? phone, String? email, String? address,
    int? totalOrders, int? totalSpent, String? photoUrl,
    double? ownerRating, String? ownerNote,
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
  );
}