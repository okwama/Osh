import 'package:hive/hive.dart';
import 'package:woosh/models/Products_Inventory/product_model.dart';
import 'package:woosh/models/Products_Inventory/price_option_model.dart';
import 'package:woosh/models/order/orderitem_model.dart';
import 'package:get/get.dart'; // For firstWhereOrNull

part 'cart_item_model.g.dart';

@HiveType(typeId: 20) // Updated to use the Order-related models range
class CartItemModel extends HiveObject {
  @HiveField(0)
  final int productId;

  @HiveField(1)
  final String productName;

  @HiveField(2)
  final int quantity;

  @HiveField(3)
  final int? priceOptionId;

  @HiveField(4)
  final double unitPrice;

  @HiveField(5)
  final String? imageUrl;

  @HiveField(6)
  final int? packSize;

  CartItemModel({
    required this.productId,
    required this.productName,
    required this.quantity,
    this.priceOptionId,
    required this.unitPrice,
    this.imageUrl,
    this.packSize,
  });

  factory CartItemModel.fromOrderItem(OrderItem item) {
    // Handle null price option ID for fallback pricing
    int? priceOptionId = item.priceOptionId;
    double unitPrice = 0.0;

    // If no price option ID is set, use the product's unit cost
    if (priceOptionId == null) {
      unitPrice = item.product?.unitCost ?? 0.0;
    } else {
      // For now, use the product's unit cost as fallback
      unitPrice = item.product?.unitCost ?? 0.0;
    }

    // For fallback pricing, keep priceOptionId as null and set unitPrice to 0
    // The API will handle the actual pricing calculation

    return CartItemModel(
      productId: item.productId,
      productName: item.product?.name ?? 'Unknown Product',
      quantity: item.quantity,
      priceOptionId: priceOptionId, // Can be null for fallback pricing
      unitPrice: unitPrice,
      imageUrl: item.product?.image,
      packSize: null, // ProductModel doesn't have packSize
    );
  }

  OrderItem toOrderItem() {
    return OrderItem(
      productId: productId,
      quantity: quantity,
      priceOptionId: priceOptionId,
      product: ProductModel(
        id: productId,
        name: productName,
        categoryId: 0, // Default value
        category: '', // Empty string instead of null
        unitCost: unitPrice, // Use unitPrice as unitCost
        image: imageUrl, // Use image instead of imageUrl
        createdAt: DateTime.now(), // Default value
        updatedAt: DateTime.now(), // Default value
      ),
    );
  }
}
