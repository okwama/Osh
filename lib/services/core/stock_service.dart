import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:woosh/models/Products_Inventory/store_quantity_model.dart';
import 'package:woosh/models/Products_Inventory/product_model.dart';
import 'package:woosh/services/hive/product_hive_service.dart';

/// Fast stock checking service using pre-loaded cached data
class StockService {
  static StockService? _instance;
  static StockService get instance => _instance ??= StockService._();

  StockService._();

  final Map<int, ProductModel> _productCache = {};
  final Map<int, int> _userRegionCache = {};
  bool _isInitialized = false;

  /// Initialize the stock service with cached data
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {

      // Get user's region ID
      final userData = GetStorage().read('salesRep');
      final regionId = userData?['region_id'];

      if (regionId != null) {
        _userRegionCache[0] = regionId; // Store for current user
      }

      // Load products from cache
      if (Get.isRegistered<ProductHiveService>()) {
        final productHiveService = Get.find<ProductHiveService>();
        final cachedProducts = await productHiveService.getAllProductModels();

        // Build fast lookup cache
        for (final product in cachedProducts) {
          _productCache[product.id] = product;
        }

        print(
            '✅ StockService initialized with ${_productCache.length} products');
        _isInitialized = true;
      } else {
      }
    } catch (e) {
    }
  }

  /// Get stock for a specific product and region
  int getStock(int productId, [int? regionId]) {
    try {
      final product = _productCache[productId];
      if (product == null) return 0;

      // Use provided regionId or current user's region
      final targetRegionId = regionId ?? _userRegionCache[0];
      if (targetRegionId == null) return 0;

      // Find stock for this region
      final storeQuantity = product.storeQuantities.firstWhere(
        (sq) => sq.storeId == targetRegionId,
        orElse: () => StoreQuantityModel(
          id: 0,
          quantity: 0,
          storeId: targetRegionId,
          productId: productId,
        ),
      );

      return storeQuantity.quantity;
    } catch (e) {
      return 0;
    }
  }

  /// Check if product is in stock
  bool isInStock(int productId, [int? regionId]) {
    return getStock(productId, regionId) > 0;
  }

  /// Check if product is out of stock
  bool isOutOfStock(int productId, [int? regionId]) {
    return getStock(productId, regionId) <= 0;
  }

  /// Check if product is low stock (less than 10 units)
  bool isLowStock(int productId, [int? regionId]) {
    final stock = getStock(productId, regionId);
    return stock > 0 && stock < 10;
  }

  /// Get stock status text
  String getStockStatusText(int productId, [int? regionId]) {
    final stock = getStock(productId, regionId);
    if (stock <= 0) return 'Out of Stock';
    if (stock < 10) return 'Low Stock';
    return 'In Stock';
  }

  /// Get stock status color
  int getStockStatusColor(int productId, [int? regionId]) {
    final stock = getStock(productId, regionId);
    if (stock <= 0) return 0xFFFF0000; // Red
    if (stock < 10) return 0xFFFFA500; // Orange
    return 0xFF00FF00; // Green
  }

  /// Get product by ID from cache
  ProductModel? getProduct(int productId) {
    return _productCache[productId];
  }

  /// Update product in cache
  void updateProduct(ProductModel product) {
    _productCache[product.id] = product;
  }

  /// Clear cache
  void clearCache() {
    _productCache.clear();
    _isInitialized = false;
  }

  /// Refresh cache from Hive
  Future<void> refreshCache() async {
    try {
      _productCache.clear();

      if (Get.isRegistered<ProductHiveService>()) {
        final productHiveService = Get.find<ProductHiveService>();
        final cachedProducts = await productHiveService.getAllProductModels();

        for (final product in cachedProducts) {
          _productCache[product.id] = product;
        }

        print(
            '🔄 StockService cache refreshed with ${_productCache.length} products');
      }
    } catch (e) {
    }
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    int totalStock = 0;
    int productsInStock = 0;
    int productsOutOfStock = 0;
    int productsLowStock = 0;

    for (final product in _productCache.values) {
      final stock = getStock(product.id);
      totalStock += stock;

      if (stock > 0) {
        productsInStock++;
        if (stock < 10) productsLowStock++;
      } else {
        productsOutOfStock++;
      }
    }

    return {
      'total_products': _productCache.length,
      'products_in_stock': productsInStock,
      'products_out_of_stock': productsOutOfStock,
      'products_low_stock': productsLowStock,
      'total_stock_units': totalStock,
      'user_region_id': _userRegionCache[0],
      'is_initialized': _isInitialized,
    };
  }

  /// Get all products in stock for current region
  List<ProductModel> getProductsInStock() {
    return _productCache.values
        .where((product) => isInStock(product.id))
        .toList();
  }

  /// Get all products out of stock for current region
  List<ProductModel> getProductsOutOfStock() {
    return _productCache.values
        .where((product) => isOutOfStock(product.id))
        .toList();
  }

  /// Get all products with low stock for current region
  List<ProductModel> getProductsLowStock() {
    return _productCache.values
        .where((product) => isLowStock(product.id))
        .toList();
  }
}
 