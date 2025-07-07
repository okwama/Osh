import 'store_model.dart';

class StoreQuantityModel {
  final int id;
  final int quantity;
  final int storeId;
  final int productId;
  final String? storeName;
  final String? storeAddress;

  StoreQuantityModel({
    required this.id,
    required this.quantity,
    required this.storeId,
    required this.productId,
    this.storeName,
    this.storeAddress,
  });

  factory StoreQuantityModel.fromMap(Map<String, dynamic> map) {
    return StoreQuantityModel(
      id: map['id'] ?? 0,
      quantity: map['quantity'] ?? 0,
      storeId: map['storeId'] ?? 0,
      productId: map['productId'] ?? 0,
      storeName: map['store_name'],
      storeAddress: map['store_address'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'quantity': quantity,
      'storeId': storeId,
      'productId': productId,
      'store_name': storeName,
      'store_address': storeAddress,
    };
  }

  /// Check if product is in stock
  bool get isInStock => quantity > 0;

  /// Check if product is low stock (less than 10 units)
  bool get isLowStock => quantity < 10 && quantity > 0;

  /// Check if product is out of stock
  bool get isOutOfStock => quantity <= 0;

  /// Get stock status text
  String get stockStatusText {
    if (isOutOfStock) return 'Out of Stock';
    if (isLowStock) return 'Low Stock';
    return 'In Stock';
  }

  /// Create a copy with updated fields
  StoreQuantityModel copyWith({
    int? id,
    int? quantity,
    int? storeId,
    int? productId,
    String? storeName,
    String? storeAddress,
  }) {
    return StoreQuantityModel(
      id: id ?? this.id,
      quantity: quantity ?? this.quantity,
      storeId: storeId ?? this.storeId,
      productId: productId ?? this.productId,
      storeName: storeName ?? this.storeName,
      storeAddress: storeAddress ?? this.storeAddress,
    );
  }

  @override
  String toString() {
    return 'StoreQuantityModel(id: $id, storeId: $storeId, productId: $productId, quantity: $quantity, storeName: $storeName)';
  }
}
