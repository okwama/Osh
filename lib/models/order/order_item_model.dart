class OrderItemModel {
  final int id;
  final int orderId;
  final int productId;
  final int quantity;
  final int? priceOptionId;

  OrderItemModel({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.quantity,
    this.priceOptionId,
  });

  factory OrderItemModel.fromMap(Map<String, dynamic> map) {
    return OrderItemModel(
      id: map['id'] ?? 0,
      orderId: map['orderId'] ?? 0,
      productId: map['productId'] ?? 0,
      quantity: map['quantity'] ?? 0,
      priceOptionId: map['priceOptionId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'orderId': orderId,
      'productId': productId,
      'quantity': quantity,
      'priceOptionId': priceOptionId,
    };
  }

  /// Create a copy with updated fields
  OrderItemModel copyWith({
    int? id,
    int? orderId,
    int? productId,
    int? quantity,
    int? priceOptionId,
  }) {
    return OrderItemModel(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
      priceOptionId: priceOptionId ?? this.priceOptionId,
    );
  }

  @override
  String toString() {
    return 'OrderItemModel(id: $id, orderId: $orderId, productId: $productId, quantity: $quantity)';
  }
}
