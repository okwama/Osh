import '../Products_Inventory/product_model.dart';

/// Represents an item within an order, linking a product to its ordered quantity.
/// Handles cases where the product might be deleted after order creation.
class OrderItem {
  final int? id;
  final int productId;
  final int quantity;
  final ProductModel? product;
  final int? priceOptionId;

  OrderItem({
    this.id,
    required this.productId,
    required this.quantity,
    this.product,
    this.priceOptionId,
  })  : assert(quantity > 0, 'Quantity must be positive'),
        assert(product == null || product.id == productId,
            'Product ID mismatch between item and product object');

  /// Parses JSON into an OrderItem with proper null checks
  factory OrderItem.fromJson(Map<String, dynamic> json) {
    try {
      return OrderItem(
        id: json['id'] as int?,
        productId: json['productId'] as int,
        quantity: json['quantity'] as int,
        product: json['product'] != null
            ? ProductModel.fromMap(json['product'] as Map<String, dynamic>)
            : null,
        priceOptionId: json['priceOptionId'] as int?,
      );
    } catch (e) {
      throw FormatException('Failed to parse OrderItem: $e');
    }
  }

  /// Converts to JSON, automatically excluding null fields
  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'productId': productId,
        'quantity': quantity,
        if (product != null) 'product': product!.toMap(),
        if (priceOptionId != null) 'priceOptionId': priceOptionId,
      };

  /// Creates a copy with modified fields
  OrderItem copyWith({
    int? id,
    int? productId,
    int? quantity,
    ProductModel? product,
    int? priceOptionId,
  }) =>
      OrderItem(
        id: id ?? this.id,
        productId: productId ?? this.productId,
        quantity: quantity ?? this.quantity,
        product: product ?? this.product,
        priceOptionId: priceOptionId ?? this.priceOptionId,
      );

  /// Gets the effective product name (handles null product)
  String get productName => product?.name ?? 'Unknown Product';

  /// Calculates item total price (returns 0 if product is null)
  //double get totalPrice => (product?.price ?? 0) * quantity;

  @override
  String toString() => 'OrderItem('
      'id: $id, '
      'productId: $productId, '
      'quantity: $quantity, '
      'priceOptionId: $priceOptionId, '
      'product: ${product?.id ?? "null"})';
}
