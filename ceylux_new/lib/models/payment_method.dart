class PaymentMethod {
  final String id;
  final String name;
  final String emoji;
  final String description;
  final bool isActive;

  PaymentMethod({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    this.isActive = true,
  });

  // Convert to JSON for API
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'emoji': emoji,
    'description': description,
    'is_active': isActive,
  };

  // Create from JSON
  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      emoji: json['emoji'] ?? '💳',
      description: json['description'] ?? '',
      isActive: json['is_active'] is bool 
          ? json['is_active'] as bool 
          : (json['is_active'] == 1 || json['is_active'] == null),
    );
  }

  // Copy with modifications
  PaymentMethod copyWith({
    String? id,
    String? name,
    String? emoji,
    String? description,
    bool? isActive,
  }) {
    return PaymentMethod(
      id: id ?? this.id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
    );
  }
}
