import 'package:get/get.dart';
import 'package:woosh/models/order/orderitem_model.dart';
import 'package:woosh/models/Products_Inventory/product_model.dart';
import 'package:woosh/models/Products_Inventory/price_option_model.dart';
import 'package:woosh/services/hive/cart_hive_service.dart';

class CartController extends GetxController {
  final RxList<OrderItem> items = <OrderItem>[].obs;
  final CartHiveService _cartHiveService = CartHiveService();
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadCartItems();
  }

  Future<void> _loadCartItems() async {
    try {
      isLoading.value = true;
      await _cartHiveService.init();
      items.value = _cartHiveService.getCartItems();
            } catch (e) {
          print('Error loading cart items: $e');
        } finally {
      isLoading.value = false;
    }
  }

  Future<void> addItem(OrderItem item) async {
    try {
      // Check if item with same product and price option exists
      final existingItemIndex = items.indexWhere((i) =>
          i.productId == item.productId &&
          i.priceOptionId == item.priceOptionId);

      if (existingItemIndex != -1) {
        // Update quantity if item exists
        final existingItem = items[existingItemIndex];
        final updatedItem = existingItem.copyWith(
            quantity: existingItem.quantity + item.quantity);
        items[existingItemIndex] = updatedItem;
        await _cartHiveService.updateItem(existingItemIndex, updatedItem);
      } else {
        // Add new item
        items.add(item);
        await _cartHiveService.addItem(item);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> removeItem(OrderItem item) async {
    try {
      final index = items.indexWhere((i) =>
          i.productId == item.productId &&
          i.priceOptionId == item.priceOptionId);
      if (index != -1) {
        items.removeAt(index);
        await _cartHiveService.removeItem(index);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateItemQuantity(OrderItem item, int quantity) async {
    try {
      final index = items.indexWhere((i) =>
          i.productId == item.productId &&
          i.priceOptionId == item.priceOptionId);
      if (index != -1) {
        final updatedItem = item.copyWith(quantity: quantity);
        items[index] = updatedItem;
        await _cartHiveService.updateItem(index, updatedItem);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> clear() async {
    try {
      items.clear();
      await _cartHiveService.clearCart();
    } catch (e) {
      rethrow;
    }
  }

  int get totalItems => items.length;

  double get totalAmount {
    return items.fold(0.0, (sum, item) {
      double price = 0.0;

      // Try to get price from selected price option
      if (item.priceOptionId != null &&
          item.product?.priceOptions.isNotEmpty == true) {
        try {
          final priceOption = item.product!.priceOptions
              .firstWhere((po) => po.id == item.priceOptionId);
          price = priceOption.value.toDouble();
        } catch (e) {
          // Price option not found, fallback to unit cost
          price = item.product?.unitCost ?? 0.0;
        }
      } else {
        // No price option selected, use unit cost
        price = item.product?.unitCost ?? 0.0;
      }

      return sum + (price * item.quantity);
    });
  }

  /// Get total amount for a specific item
  double getItemTotal(OrderItem item) {
    double price = 0.0;

    // Try to get price from selected price option
    if (item.priceOptionId != null &&
        item.product?.priceOptions.isNotEmpty == true) {
      try {
        final priceOption = item.product!.priceOptions
            .firstWhere((po) => po.id == item.priceOptionId);
        price = priceOption.value.toDouble();
      } catch (e) {
        // Price option not found, fallback to unit cost
        price = item.product?.unitCost ?? 0.0;
      }
    } else {
      // No price option selected, use unit cost
      price = item.product?.unitCost ?? 0.0;
    }

    return price * item.quantity;
  }

  /// Get price for a specific item (per unit)
  double getItemPrice(OrderItem item) {
    if (item.priceOptionId != null &&
        item.product?.priceOptions.isNotEmpty == true) {
      try {
        final priceOption = item.product!.priceOptions
            .firstWhere((po) => po.id == item.priceOptionId);
        return priceOption.value.toDouble();
      } catch (e) {
        // Price option not found, fallback to unit cost
        return item.product?.unitCost ?? 0.0;
      }
    } else {
      // No price option selected, use unit cost
      return item.product?.unitCost ?? 0.0;
    }
  }
}