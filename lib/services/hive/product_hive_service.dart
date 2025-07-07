import 'package:hive_flutter/hive_flutter.dart';
import 'package:woosh/models/hive/product_model.dart';
import 'package:woosh/models/Products_Inventory/product_model.dart';

/// Simple product caching service using Hive
class ProductHiveService {
  static const String _boxName = 'products';
  static const String _timestampKey = 'last_update';

  late Box<ProductHiveModel> _productBox;
  late Box _timestampBox;

  /// Initialize the service
  Future<void> init() async {
    _productBox = await Hive.openBox<ProductHiveModel>(_boxName);
    _timestampBox = await Hive.openBox('timestamps');
  }

  /// Save products to cache
  Future<void> saveProducts(List<dynamic> products) async {
    try {
      final hiveProducts = products.map((product) {
        // Convert ProductModel to ProductHiveModel using the static method
        if (product is ProductModel) {
          return ProductHiveModel.fromProduct(product);
        }
        // Handle other product types if needed
        return ProductHiveModel.fromProduct(product as ProductModel);
      }).toList();

      await _productBox.clear();
      await _productBox.addAll(hiveProducts);
    } catch (e) {
    }
  }

  /// Get all cached products
  Future<List<ProductHiveModel>> getAllProducts() async {
    try {
      return _productBox.values.toList();
    } catch (e) {
      return [];
    }
  }

  /// Get all cached products converted to ProductModel
  Future<List<ProductModel>> getAllProductModels() async {
    try {
      return _productBox.values
          .map((hiveProduct) => hiveProduct.toProduct())
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Set last update timestamp
  Future<void> setLastUpdateTime(DateTime time) async {
    try {
      await _timestampBox.put(_timestampKey, time.millisecondsSinceEpoch);
    } catch (e) {
    }
  }

  /// Get last update timestamp
  Future<DateTime?> getLastUpdateTime() async {
    try {
      final timestamp = _timestampBox.get(_timestampKey);
      if (timestamp != null) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Clear all cached products
  Future<void> clearAllProducts() async {
    try {
      await _productBox.clear();
      await _timestampBox.delete(_timestampKey);
    } catch (e) {
    }
  }

  /// Close the boxes
  Future<void> close() async {
    try {
      await _productBox.close();
    } catch (e) {
    }
  }
}