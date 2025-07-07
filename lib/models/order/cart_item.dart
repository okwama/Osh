import 'package:get/get.dart';
import '../Products_Inventory/product_model.dart';

class CartItem {
  final ProductModel product;
  final RxInt quantity;
  final RxInt? storeId;

  CartItem({
    required this.product,
    required int quantity,
    int? storeId,
  })  : quantity = quantity.obs,
        storeId = storeId?.obs;

  Map<String, dynamic> toJson() {
    return {
      'productId': product.id,
      'quantity': quantity.value,
      if (storeId?.value != null) 'storeId': storeId!.value,
    };
  }

  factory CartItem.fromJson(Map<String, dynamic> json, ProductModel product) {
    return CartItem(
      product: product,
      quantity: json['quantity'] as int,
      storeId: json['storeId'] as int?,
    );
  }
}
