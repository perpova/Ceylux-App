class DeliveryMethod {
  final String id;
  final String name;
  final String description;
  final String? accountDetails; // Bank account, address, etc.
  final bool isActive;
  final String emoji;

  DeliveryMethod({
    required this.id,
    required this.name,
    required this.description,
    this.accountDetails,
    this.isActive = true,
    required this.emoji,
  });

  factory DeliveryMethod.fromMap(Map<String, dynamic> m) => DeliveryMethod(
    id: m['id']?.toString() ?? '',
    name: m['name'] ?? '',
    description: m['description'] ?? '',
    accountDetails: m['account_details']?.toString(),
    isActive: m['is_active'] != false,
    emoji: m['emoji'] ?? '🚚',
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'description': description,
    'account_details': accountDetails,
    'is_active': isActive,
    'emoji': emoji,
  };
}

class OrderDeliveryInfo {
  final String? deliveryMethodId;
  final String? deliveryMethodName;
  final String? paymentProofUrl;
  final String? notes;

  OrderDeliveryInfo({
    this.deliveryMethodId,
    this.deliveryMethodName,
    this.paymentProofUrl,
    this.notes,
  });

  factory OrderDeliveryInfo.fromMap(Map<String, dynamic> m) => OrderDeliveryInfo(
    deliveryMethodId: m['delivery_method_id']?.toString(),
    deliveryMethodName: m['delivery_method_name']?.toString(),
    paymentProofUrl: m['payment_proof_url']?.toString(),
    notes: m['notes']?.toString(),
  );

  Map<String, dynamic> toMap() => {
    'delivery_method_id': deliveryMethodId,
    'delivery_method_name': deliveryMethodName,
    'payment_proof_url': paymentProofUrl,
    'notes': notes,
  };
}
