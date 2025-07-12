import 'package:get/get.dart';
import 'package:woosh/services/core/stock_service.dart';
import 'package:woosh/models/Products_Inventory/product_model.dart';
import 'package:woosh/utils/error_handler.dart';

class StockController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxBool isInitialized = false.obs;
  final RxMap<String, dynamic> cacheStats = <String, dynamic>{}.obs;

  /// Initialize the stock service with cached data
  Future<void> initialize() async {
    try {
      isLoading.value = true;
      await StockService.instance.initialize();
      isInitialized.value = true;
      await refreshCacheStats();
    } catch (e) {
      ErrorHandler.handleSilentError(e, context: 'StockController.initialize');
    } finally {
      isLoading.value = false;
    }
  }

  /// Get stock for a specific product and region
  int getStock(int productId, [int? regionId]) {
    try {
      return StockService.instance.getStock(productId, regionId);
    } catch (e) {
      ErrorHandler.handleSilentError(e, context: 'StockController.getStock');
      return 0;
    }
  }

  /// Check if product is in stock
  bool isInStock(int productId, [int? regionId]) {
    try {
      return StockService.instance.isInStock(productId, regionId);
    } catch (e) {
      ErrorHandler.handleSilentError(e, context: 'StockController.isInStock');
      return false;
    }
  }

  /// Check if product is out of stock
  bool isOutOfStock(int productId, [int? regionId]) {
    try {
      return StockService.instance.isOutOfStock(productId, regionId);
    } catch (e) {
      ErrorHandler.handleSilentError(e,
          context: 'StockController.isOutOfStock');
      return true;
    }
  }

  /// Check if product is low stock (less than 10 units)
  bool isLowStock(int productId, [int? regionId]) {
    try {
      return StockService.instance.isLowStock(productId, regionId);
    } catch (e) {
      ErrorHandler.handleSilentError(e, context: 'StockController.isLowStock');
      return false;
    }
  }

  /// Get stock status text
  String getStockStatusText(int productId, [int? regionId]) {
    try {
      return StockService.instance.getStockStatusText(productId, regionId);
    } catch (e) {
      ErrorHandler.handleSilentError(e,
          context: 'StockController.getStockStatusText');
      return 'Unknown';
    }
  }

  /// Get stock status color
  int getStockStatusColor(int productId, [int? regionId]) {
    try {
      return StockService.instance.getStockStatusColor(productId, regionId);
    } catch (e) {
      ErrorHandler.handleSilentError(e,
          context: 'StockController.getStockStatusColor');
      return 0xFF808080; // Gray
    }
  }

  /// Get product by ID from cache
  ProductModel? getProduct(int productId) {
    try {
      return StockService.instance.getProduct(productId);
    } catch (e) {
      ErrorHandler.handleSilentError(e, context: 'StockController.getProduct');
      return null;
    }
  }

  /// Update product in cache
  void updateProduct(ProductModel product) {
    try {
      StockService.instance.updateProduct(product);
    } catch (e) {
      ErrorHandler.handleSilentError(e,
          context: 'StockController.updateProduct');
    }
  }

  /// Clear cache
  void clearCache() {
    try {
      StockService.instance.clearCache();
      isInitialized.value = false;
      cacheStats.clear();
    } catch (e) {
      ErrorHandler.handleSilentError(e, context: 'StockController.clearCache');
    }
  }

  /// Refresh cache from Hive
  Future<void> refreshCache() async {
    try {
      isLoading.value = true;
      await StockService.instance.refreshCache();
      await refreshCacheStats();
    } catch (e) {
      ErrorHandler.handleSilentError(e,
          context: 'StockController.refreshCache');
    } finally {
      isLoading.value = false;
    }
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> refreshCacheStats() async {
    try {
      final stats = StockService.instance.getCacheStats();
      cacheStats.value = stats;
      return stats;
    } catch (e) {
      ErrorHandler.handleSilentError(e,
          context: 'StockController.refreshCacheStats');
      return {
        'total_products': 0,
        'products_in_stock': 0,
        'products_out_of_stock': 0,
        'products_low_stock': 0,
        'total_stock_units': 0,
        'user_region_id': null,
        'is_initialized': false,
      };
    }
  }

  /// Get all products in stock for current region
  List<ProductModel> getProductsInStock() {
    try {
      return StockService.instance.getProductsInStock();
    } catch (e) {
      ErrorHandler.handleSilentError(e,
          context: 'StockController.getProductsInStock');
      return [];
    }
  }

  /// Get all products out of stock for current region
  List<ProductModel> getProductsOutOfStock() {
    try {
      return StockService.instance.getProductsOutOfStock();
    } catch (e) {
      ErrorHandler.handleSilentError(e,
          context: 'StockController.getProductsOutOfStock');
      return [];
    }
  }

  /// Get all products with low stock for current region
  List<ProductModel> getProductsLowStock() {
    try {
      return StockService.instance.getProductsLowStock();
    } catch (e) {
      ErrorHandler.handleSilentError(e,
          context: 'StockController.getProductsLowStock');
      return [];
    }
  }
}
