import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:woosh/services/core/cart_placement_service.dart';
import 'package:woosh/models/client/client_model.dart';
import 'package:woosh/models/hive/order_model.dart';
import 'package:woosh/models/Products_Inventory/store_model.dart';
import 'package:woosh/utils/error_handler.dart';

class CartPlacementController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxList<Store> stores = <Store>[].obs;

  /// Load stores for the current user
  Future<List<Store>> loadStores(Client outlet) async {
    try {
      isLoading.value = true;
      final result = await CartPlacementService.loadStores(outlet);
      stores.value = result;
      return result;
    } catch (e) {
      ErrorHandler.handleGeneralError(e,
          context: 'CartPlacementController.loadStores');
      return [];
    } finally {
      isLoading.value = false;
    }
  }

  /// Pick an image for order attachment
  Future<dynamic> pickImage() async {
    try {
      isLoading.value = true;
      final result = await CartPlacementService.pickImage();
      return result;
    } catch (e) {
      ErrorHandler.handleGeneralError(e,
          context: 'CartPlacementController.pickImage');
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  /// Validate order before placement
  String? validateOrder(Store? selectedStore) {
    try {
      return CartPlacementService.validateOrder(selectedStore);
    } catch (e) {
      ErrorHandler.handleSilentError(e,
          context: 'CartPlacementController.validateOrder');
      return 'Validation error occurred';
    }
  }

  /// Prepare order items for submission
  List<Map<String, dynamic>> prepareOrderItems(Store selectedStore) {
    try {
      return CartPlacementService.prepareOrderItems(selectedStore);
    } catch (e) {
      ErrorHandler.handleGeneralError(e,
          context: 'CartPlacementController.prepareOrderItems');
      return [];
    }
  }

  /// Place order with business logic
  Future<bool> placeOrder({
    required Client outlet,
    required Store selectedStore,
    required String comment,
    dynamic selectedImage,
    OrderModel? existingOrder,
  }) async {
    try {
      isLoading.value = true;
      final result = await CartPlacementService.placeOrder(
        outlet: outlet,
        selectedStore: selectedStore,
        comment: comment,
        selectedImage: selectedImage,
        existingOrder: existingOrder,
      );
      return result;
    } catch (e) {
      ErrorHandler.handleGeneralError(e,
          context: 'CartPlacementController.placeOrder');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Show comment dialog
  Future<String?> showCommentDialog() async {
    try {
      isLoading.value = true;
      final result = await CartPlacementService.showCommentDialog();
      return result;
    } catch (e) {
      ErrorHandler.handleSilentError(e,
          context: 'CartPlacementController.showCommentDialog');
      return null;
    } finally {
      isLoading.value = false;
    }
  }
}
