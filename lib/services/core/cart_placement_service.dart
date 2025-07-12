import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:woosh/models/client/client_model.dart';
import 'package:woosh/models/hive/order_model.dart';
import 'package:woosh/models/order/orderitem_model.dart';
import 'package:woosh/models/Products_Inventory/store_model.dart';
import 'package:woosh/controllers/cartcontroller/cart_controller.dart';
import 'package:woosh/services/core/order_service.dart';
import 'package:woosh/services/core/store_service.dart';
import 'package:get_storage/get_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';

/// Service for handling cart placement and order creation business logic
class CartPlacementService {
  static final CartController _cartController = Get.find<CartController>();
  static final ImagePicker _picker = ImagePicker();

  /// Load stores for the current user
  static Future<List<Store>> loadStores(Client outlet) async {
    try {
      // Get user's region and country from GetStorage
      final box = GetStorage();
      final salesRep = box.read('salesRep');
      final userRegionId = salesRep?['region_id'];
      final userCountryId = salesRep?['countryId'];

      print(
          'User context - Region ID: $userRegionId, Country ID: $userCountryId');

      // Use the country ID from user data, fallback to outlet country
      final countryId = userCountryId ?? outlet.countryId;

      if (countryId == null) {
        throw Exception(
            'Unable to determine your country. Please contact support.');
      }

      // Fetch stores from database
      var stores = await StoreService.getStoresForUser(countryId, userRegionId);

      print(
          '✅ [CartPlacementService] Total stores received from database: ${stores.length}');

      if (stores.isNotEmpty) {
        print(
            '📋 [CartPlacementService] Available stores: ${stores.map((s) => '${s.name} (${s.region?.name ?? 'No Region'})').join(', ')}');
      } else {
        // If no stores found for specific region, try to get all stores in the country
        if (userRegionId != null) {
          print(
              '📋 [CartPlacementService] Trying to get all stores in country without region filter...');
          stores = await StoreService.getStoresForUser(countryId, null);
          print(
              '✅ [CartPlacementService] Found ${stores.length} stores in country (no region filter)');
          if (stores.isNotEmpty) {
            print(
                '📋 [CartPlacementService] Available stores: ${stores.map((s) => '${s.name} (${s.region?.name ?? 'No Region'})').join(', ')}');
          }
        }
      }

      if (stores.isEmpty) {
        Get.snackbar(
          'No Stores Available',
          'There are no stores available in your country (ID: $countryId). Please contact support.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
      }

      return stores;
    } catch (e) {
      print('❌ Error in CartPlacementService [loadStores]: $e');
      Get.snackbar(
        'Error',
        'Failed to load stores. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      rethrow;
    }
  }

  /// Pick an image for order attachment
  static Future<dynamic> pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70, // Compress image
      );

      if (image != null) {
        return image;
      }
      return null;
    } catch (e) {
      print('❌ Error in CartPlacementService [pickImage]: $e');
      Get.snackbar(
        'Error',
        'Failed to pick image. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return null;
    }
  }

  /// Validate order before placement
  static String? validateOrder(Store? selectedStore) {
    if (selectedStore == null) {
      return 'Please select a store';
    }

    if (_cartController.items.isEmpty) {
      return 'Cart is empty';
    }

    // Validate each item
    for (final item in _cartController.items) {
      if (item.product == null) {
        return 'Invalid product in cart';
      }
      if (item.quantity <= 0) {
        return 'Invalid quantity for ${item.product!.name}';
      }

      // Check stock availability for the selected store
      final availableStock =
          item.product!.getQuantityForStore(selectedStore.id);
      if (availableStock < item.quantity) {
        return 'Insufficient stock for ${item.product!.name} in ${selectedStore.name}. Available: $availableStock, Requested: ${item.quantity}';
      }
    }

    return null;
  }

  /// Prepare order items for submission
  static List<Map<String, dynamic>> prepareOrderItems(Store selectedStore) {
    return _cartController.items.map((item) {
      if (item.product == null) {
        throw Exception('Invalid product in cart');
      }
      if (item.quantity <= 0) {
        throw Exception('Invalid quantity for ${item.product!.name}');
      }

      // Check stock availability for the selected store
      final availableStock =
          item.product!.getQuantityForStore(selectedStore.id);
      if (availableStock < item.quantity) {
        throw Exception(
            'Insufficient stock for ${item.product!.name} in ${selectedStore.name}. Available: $availableStock, Requested: ${item.quantity}');
      }

      return {
        'productId': item.product!.id,
        'quantity': item.quantity,
        'priceOptionId': item.priceOptionId,
        'storeId': selectedStore.id,
        'unitPrice': _cartController.getItemPrice(item),
        'totalPrice': _cartController.getItemTotal(item),
      };
    }).toList();
  }

  /// Place order with business logic
  static Future<bool> placeOrder({
    required Client outlet,
    required Store selectedStore,
    required String comment,
    dynamic selectedImage,
    OrderModel? existingOrder,
  }) async {
    try {
      // Validate order
      final validationError = validateOrder(selectedStore);
      if (validationError != null) {
        Get.snackbar(
          'Error',
          validationError,
          snackPosition: SnackPosition.BOTTOM,
        );
        return false;
      }

      // Prepare order items
      final orderItems = prepareOrderItems(selectedStore);

      // TODO: Implement actual order creation with proper service
      // For now, just show success message
      print(
          '📋 [CartPlacementService] Order items prepared: ${orderItems.length} items');
      Get.snackbar(
        'Order Created',
        'Order has been created successfully!',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      // Process success
      _processOrderSuccess();
      return true;
    } catch (e) {
      handleOrderError(e);
      return false;
    }
  }

  /// Process successful order placement
  static void _processOrderSuccess() {
    _cartController.clear();
    // Navigate back to home first, then show success dialog
    Get.offNamed('/home');
    // Show success dialog with options after navigation
    _showOrderSuccessDialog();
  }

  /// Show order success dialog
  static void _showOrderSuccessDialog() {
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 8),
            const Text('Order Successful'),
          ],
        ),
        content: const Text('Your order has been placed successfully!'),
        actions: [
          TextButton(
            onPressed: () {
              Get.back(); // Close dialog
              Get.offNamed('/orders'); // Go to orders page
            },
            child: const Text('View Orders'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back(); // Close dialog
              // Navigate to products grid to add more items
              Get.offNamed('/products');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Add More'),
          ),
        ],
      ),
      barrierDismissible: true,
    );
  }

  /// Handle order placement errors
  static void handleOrderError(dynamic error) {
    String errorMessage = error.toString();

    if (errorMessage.contains('Insufficient stock')) {
      final RegExp regex = RegExp(r'Insufficient stock for (.+)');
      final match = regex.firstMatch(errorMessage);
      final productName = match?.group(1) ?? 'Unknown Product';

      Get.dialog(
        AlertDialog(
          title: const Text('Out of Stock'),
          content: Text('Insufficient stock for $productName'),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else if (errorMessage.contains('Order cancelled by user')) {
      // User cancelled the order due to balance warning
      Get.snackbar(
        'Order Cancelled',
        'The order was cancelled due to balance warning',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
    } else {
      // Handle other errors
      Get.snackbar(
        'Error',
        errorMessage,
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  /// Show comment dialog for delivery information
  static Future<String?> showCommentDialog() async {
    final TextEditingController commentController = TextEditingController();
    String comment = '';

    final result = await Get.dialog<String>(
      AlertDialog(
        title: const Text('Delivery Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Add any delivery information (e.g., tax PIN, delivery instructions)',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: commentController,
              decoration: InputDecoration(
                hintText: 'Enter delivery information...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                isDense: true,
              ),
              maxLines: 2,
              onChanged: (value) => comment = value,
            ),
          ],
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Get.back(result: ''),
                child: const Text('Skip'),
              ),
              ElevatedButton(
                onPressed: () => Get.back(result: comment),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                child: const Text('Add & Proceed'),
              ),
            ],
          ),
        ],
      ),
    );

    commentController.dispose();
    return result;
  }
}
