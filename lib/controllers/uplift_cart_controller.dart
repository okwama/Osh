import 'package:get/get.dart';
import 'package:woosh/models/Products_Inventory/product_model.dart';
import 'package:woosh/models/client/client_model.dart';

class UpliftCartItem {
  final ProductModel product;
  final int quantity;
  final double unitPrice;

  UpliftCartItem({
    required this.product,
    required this.quantity,
    required this.unitPrice,
  });

  double get total => unitPrice * quantity;
}

class UpliftCartController extends GetxController {
  final RxList<UpliftCartItem> items = <UpliftCartItem>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  Client? currentOutlet;

  void setOutlet(Client outlet) {
    currentOutlet = outlet;
  }

  void addItem(ProductModel product, int quantity, double unitPrice) {
    final existingItemIndex = items.indexWhere(
      (item) => item.product.id == product.id && item.unitPrice == unitPrice,
    );

    if (existingItemIndex >= 0) {
      // Update existing item
      final existingItem = items[existingItemIndex];
      items[existingItemIndex] = UpliftCartItem(
        product: product,
        quantity: existingItem.quantity + quantity,
        unitPrice: unitPrice,
      );
    } else {
      // Add new item
      items.add(
        UpliftCartItem(
          product: product,
          quantity: quantity,
          unitPrice: unitPrice,
        ),
      );
    }
  }

  void updateItemQuantity(UpliftCartItem item, int newQuantity) {
    final index = items.indexOf(item);
    if (index >= 0) {
      items[index] = UpliftCartItem(
        product: item.product,
        quantity: newQuantity,
        unitPrice: item.unitPrice,
      );
    }
  }

  void removeItem(UpliftCartItem item) {
    items.remove(item);
  }

  void clear() {
    items.clear();
    errorMessage.value = '';
  }

  double get totalAmount {
    return items.fold(0.0, (sum, item) => sum + item.total);
  }

  /// Calculate total amount with proper price calculation
  Future<double> calculateTotalWithPriceOptions(int countryId) async {
    try {
      // For uplift sales, we use the simple calculation since prices are manually entered
      return totalAmount;
    } catch (e) {
      return totalAmount; // Fallback to simple calculation
    }
  }

  int get totalItems {
    return items.fold(0, (sum, item) => sum + item.quantity);
  }

  int get totalPieces {
    return items.fold(0, (sum, item) => sum + item.quantity);
  }

  bool get isEmpty => items.isEmpty;

  bool get isNotEmpty => items.isNotEmpty;

  void clearCart() {}
}
