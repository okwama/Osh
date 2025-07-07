import 'package:woosh/models/Products_Inventory/product_model.dart';
import 'package:woosh/models/Products_Inventory/price_option_model.dart';
import 'package:woosh/models/Products_Inventory/store_quantity_model.dart';
import 'package:woosh/services/database_service.dart';
import 'package:woosh/services/core/currency_config_service.dart';

/// Product service using direct database connections with dynamic country-aware currency filtering
class ProductService {
  static final DatabaseService _db = DatabaseService.instance;

  /// Get currency value based on country configuration
  static double _getCurrencyValue(
      Map<String, dynamic> item, CurrencyConfig config, String type) {
    return CurrencyConfigService.getCurrencyValue(item, config, type);
  }

  /// Get products with pagination, filtering, and dynamic country-aware currency conversion (OPTIMIZED - No N+1 queries)
  static Future<List<ProductModel>> getProducts({
    int page = 1,
    int limit = 20,
    String? search,
    int? categoryId,
    int? clientId,
    bool? inStock,
    int? countryId,
  }) async {
    try {

      // Get current user's country configuration if not provided
      CurrencyConfig? userCurrencyConfig;
      if (countryId != null) {
        userCurrencyConfig =
            await CurrencyConfigService.getCurrencyConfig(countryId);
      } else {
        userCurrencyConfig =
            await CurrencyConfigService.getCurrentUserCurrencyConfig();
      }

      if (userCurrencyConfig == null) {
        userCurrencyConfig = await CurrencyConfigService.getCurrencyConfig(
            1); // Default to Kenya
      }

      // Ensure we have a valid config
      if (userCurrencyConfig == null) {
        throw Exception('Unable to determine currency configuration');
      }

      // Make userCurrencyConfig non-nullable for the rest of the method
      final currencyConfig = userCurrencyConfig;

      print(
          '🔍 [ProductService] Fetching products for country: ${currencyConfig.countryName} (${currencyConfig.currencyCode})');

      // OPTIMIZED: Single query with JOINs to get all related data at once
      String sql = '''
        SELECT 
          p.id as product_id,
          p.name as product_name,
          p.category_id,
          p.category,
          p.unit_cost,
          p.unit_cost_tzs,
          p.unit_cost_ngn,
          p.description,
          p.createdAt,
          p.updatedAt,
          p.clientId,
          p.image,
          cl.name as client_name,
          
          po.id as price_option_id,
          po.option as price_option_name,
          po.value as price_option_value,
          po.categoryId as price_option_category_id,
          po.value_tzs as price_option_value_tzs,
          po.value_ngn as price_option_value_ngn,
          
          sq.id as store_quantity_id,
          sq.productId as sq_product_id,
          sq.storeId as sq_store_id,
          sq.quantity as sq_quantity,
          s.name as store_name,
          s.countryId as store_country_id
        FROM Product p
        LEFT JOIN Clients cl ON p.clientId = cl.id
        LEFT JOIN PriceOption po ON po.categoryId = p.category_id
        LEFT JOIN StoreQuantity sq ON sq.productId = p.id
        LEFT JOIN Stores s ON sq.storeId = s.id AND s.countryId = ? AND s.status = 0 AND sq.quantity > 0
        WHERE 1=1
      ''';

      List<dynamic> params = [
        currencyConfig.countryId
      ]; // Country filter for stores

      // Add search filter
      if (search != null && search.isNotEmpty) {
        sql += ' AND (p.name LIKE ? OR p.description LIKE ?)';
        params.addAll(['%$search%', '%$search%']);
      }

      // Add category filter
      if (categoryId != null) {
        sql += ' AND p.category_id = ?';
        params.add(categoryId);
      }

      // Add client filter
      if (clientId != null) {
        // If clientId is provided, show products for that client OR products with NULL clientId (general products)
        sql += ' AND (p.clientId = ? OR p.clientId IS NULL)';
        params.add(clientId);
      }

      // Ensure products have stock in user's country
      sql += '''
        AND EXISTS (
          SELECT 1 FROM StoreQuantity sq2
          JOIN Stores s2 ON sq2.storeId = s2.id
          WHERE sq2.productId = p.id
          AND sq2.quantity > 0
          AND s2.countryId = ?
          AND s2.status = 0
        )
      ''';
      params.add(currencyConfig.countryId);

      sql += ' ORDER BY p.name ASC, po.option ASC, sq.quantity DESC';

      final startTime = DateTime.now();
      final results = await _db.query(sql, params);
      final queryTime = DateTime.now().difference(startTime).inMilliseconds;

      print(
          '⚡ [ProductService] Single optimized query completed in ${queryTime}ms with ${results.length} rows');

      // Process joined results to group by product
      final productMap = <int, Map<String, dynamic>>{};
      final priceOptionsMap = <int, Set<Map<String, dynamic>>>{};
      final storeQuantitiesMap = <int, Set<Map<String, dynamic>>>{};

      for (final row in results) {
        final data = row.fields;
        final productId = data['product_id'] as int;

        // Store product data (only once per product)
        if (!productMap.containsKey(productId)) {
          productMap[productId] = {
            'id': productId,
            'name': data['product_name'],
            'category_id': data['category_id'],
            'category': data['category'],
            'unit_cost': data['unit_cost'],
            'unit_cost_tzs': data['unit_cost_tzs'],
            'unit_cost_ngn': data['unit_cost_ngn'],
            'description': data['description'],
            'createdAt': data['createdAt'],
            'updatedAt': data['updatedAt'],
            'clientId': data['clientId'],
            'image': data['image'],
            'client_name': data['client_name'],
          };
          priceOptionsMap[productId] = <Map<String, dynamic>>{};
          storeQuantitiesMap[productId] = <Map<String, dynamic>>{};
        }

        // Collect price options (avoid duplicates)
        if (data['price_option_id'] != null) {
          priceOptionsMap[productId]!.add({
            'id': data['price_option_id'],
            'option': data['price_option_name'],
            'value': data['price_option_value'],
            'categoryId': data['price_option_category_id'],
            'value_tzs': data['price_option_value_tzs'],
            'value_ngn': data['price_option_value_ngn'],
          });
        }

        // Collect store quantities (avoid duplicates)
        if (data['store_quantity_id'] != null) {
          storeQuantitiesMap[productId]!.add({
            'id': data['store_quantity_id'],
            'productId': data['sq_product_id'],
            'storeId': data['sq_store_id'],
            'quantity': data['sq_quantity'],
            'store_name': data['store_name'],
          });
        }
      }

      // Apply pagination to unique products
      final productIds = productMap.keys.toList();
      final offset = (page - 1) * limit;
      final paginatedProductIds = productIds.skip(offset).take(limit).toList();

      print(
          '🔍 [ProductService] Processing ${paginatedProductIds.length} unique products after pagination');

      // Build final product list
      final products = <ProductModel>[];
      for (final productId in paginatedProductIds) {
        final productData = productMap[productId]!;

        // Apply dynamic currency conversion
        final convertedUnitCost =
            _getCurrencyValue(productData, currencyConfig, 'product');

        // Process price options with currency conversion
        final priceOptions = priceOptionsMap[productId]!.map((optionData) {
          final convertedValue =
              _getCurrencyValue(optionData, currencyConfig, 'priceOption');

          return PriceOptionModel(
            id: optionData['id'],
            option: optionData['option'],
            value: convertedValue.toInt(),
            categoryId: optionData['categoryId'],
            valueNgn: optionData['value_ngn']?.toDouble(),
            valueTzs: optionData['value_tzs']?.toDouble(),
          );
        }).toList();

        // Process store quantities
        final storeQuantities = storeQuantitiesMap[productId]!.map((sqData) {
          return StoreQuantityModel(
            id: sqData['id'],
            productId: sqData['productId'],
            storeId: sqData['storeId'],
            quantity: sqData['quantity'],
            storeName: sqData['store_name'],
            storeAddress: null, // Stores table doesn't have address column
          );
        }).toList();

        final product = ProductModel(
          id: productData['id'],
          name: productData['name'],
          categoryId: productData['category_id'],
          category: productData['category'] ?? '',
          unitCost: convertedUnitCost,
          description: productData['description'],
          packSize: null, // packSize column doesn't exist in database
          createdAt: _parseDateTime(productData['createdAt']),
          updatedAt: _parseDateTime(productData['updatedAt']),
          clientId: productData['clientId'],
          image: productData['image'],
          unitCostNgn: productData['unit_cost_ngn']?.toDouble(),
          unitCostTzs: productData['unit_cost_tzs']?.toDouble(),
          priceOptions: priceOptions,
          storeQuantities: storeQuantities,
        );

        products.add(product);
      }

      final totalTime = DateTime.now().difference(startTime).inMilliseconds;
      print(
          '🚀 [ProductService] OPTIMIZED fetch completed in ${totalTime}ms - Fetched ${products.length} products with ${currencyConfig.currencyCode} pricing');
      print(
          '⚡ [ProductService] Performance: Single query vs ${productMap.length * 2} individual queries (N+1 eliminated)');

      return products;
    } catch (e) {
      rethrow;
    }
  }

  /// Get a specific product by ID with dynamic country-aware currency conversion
  static Future<ProductModel?> getProductById(int productId,
      {int? countryId}) async {
    try {
      // Get currency configuration
      CurrencyConfig? userCurrencyConfig;
      if (countryId != null) {
        userCurrencyConfig =
            await CurrencyConfigService.getCurrencyConfig(countryId);
      } else {
        userCurrencyConfig =
            await CurrencyConfigService.getCurrentUserCurrencyConfig();
      }

      if (userCurrencyConfig == null) {
        userCurrencyConfig = await CurrencyConfigService.getCurrencyConfig(
            1); // Default to Kenya
      }

      // Ensure we have a valid config
      if (userCurrencyConfig == null) {
        throw Exception('Unable to determine currency configuration');
      }

      const sql = '''
        SELECT 
          p.id,
          p.name,
          p.category_id,
          p.category,
          p.unit_cost,
          p.unit_cost_tzs,
          p.unit_cost_ngn,
          p.description,
          p.createdAt,
          p.updatedAt,
          p.clientId,
          p.image,
          cl.name as client_name
        FROM Product p
        LEFT JOIN Clients cl ON p.clientId = cl.id
        WHERE p.id = ?
      ''';

      final results = await _db.query(sql, [productId]);

      if (results.isEmpty) return null;

      final productData = results.first.fields;

      // Apply dynamic currency conversion
      final convertedUnitCost =
          _getCurrencyValue(productData, userCurrencyConfig, 'product');

      // Fetch price options with dynamic currency conversion
      final priceOptions =
          await _getPriceOptionsForProduct(productId, userCurrencyConfig);

      // Fetch store quantities
      final storeQuantities = await _getStoreQuantitiesForProduct(
          productId, userCurrencyConfig.countryId);

      return ProductModel(
        id: productData['id'],
        name: productData['name'],
        categoryId: productData['category_id'],
        category: productData['category'] ?? '',
        unitCost: convertedUnitCost,
        description: productData['description'],
        packSize: null, // packSize column doesn't exist in database
        createdAt: _parseDateTime(productData['createdAt']),
        updatedAt: _parseDateTime(productData['updatedAt']),
        clientId: productData['clientId'],
        image: productData['image'],
        unitCostNgn: productData['unit_cost_ngn']?.toDouble(),
        unitCostTzs: productData['unit_cost_tzs']?.toDouble(),
        priceOptions: priceOptions,
        storeQuantities: storeQuantities,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Get price options for a product with dynamic country-aware currency conversion
  static Future<List<PriceOptionModel>> _getPriceOptionsForProduct(
      int productId, CurrencyConfig currencyConfig) async {
    try {
      const sql = '''
        SELECT 
          po.id,
          po.option,
          po.value,
          po.categoryId,
          po.value_tzs,
          po.value_ngn
        FROM PriceOption po
        JOIN Product p ON po.categoryId = p.category_id
        WHERE p.id = ?
        ORDER BY po.option ASC
      ''';

      final results = await _db.query(sql, [productId]);

      return results.map((row) {
        final data = row.fields;
        final convertedValue =
            _getCurrencyValue(data, currencyConfig, 'priceOption');

        return PriceOptionModel(
          id: data['id'],
          option: data['option'],
          value: convertedValue.toInt(),
          categoryId: data['categoryId'],
          valueNgn: data['value_ngn']?.toDouble(),
          valueTzs: data['value_tzs']?.toDouble(),
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get store quantities for a product in user's country
  static Future<List<StoreQuantityModel>> _getStoreQuantitiesForProduct(
      int productId, int countryId) async {
    try {
      const sql = '''
        SELECT 
          sq.id,
          sq.productId,
          sq.storeId,
          sq.quantity,
          s.name as store_name,
          s.countryId as store_country_id
        FROM StoreQuantity sq
        JOIN Stores s ON sq.storeId = s.id
        WHERE sq.productId = ? 
        AND s.countryId = ?
        AND s.status = 0
        AND sq.quantity > 0
        ORDER BY sq.quantity DESC
      ''';

      final results = await _db.query(sql, [productId, countryId]);

      return results.map((row) {
        final data = row.fields;
        return StoreQuantityModel(
          id: data['id'],
          productId: data['productId'],
          storeId: data['storeId'],
          quantity: data['quantity'],
          storeName: data['store_name'],
          storeAddress: null, // Stores table doesn't have address column
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get products by category with dynamic country-aware currency conversion
  static Future<List<ProductModel>> getProductsByCategory(
    int categoryId, {
    int page = 1,
    int limit = 20,
    int? countryId,
  }) async {
    return getProducts(
      page: page,
      limit: limit,
      categoryId: categoryId,
      countryId: countryId,
    );
  }

  /// Search products with dynamic country-aware currency conversion
  static Future<List<ProductModel>> searchProducts(
    String query, {
    int page = 1,
    int limit = 20,
    int? countryId,
  }) async {
    return getProducts(
      page: page,
      limit: limit,
      search: query,
      countryId: countryId,
    );
  }

  /// Get products in stock for user's country
  static Future<List<ProductModel>> getInStockProducts({
    int page = 1,
    int limit = 20,
    int? countryId,
  }) async {
    return getProducts(
      page: page,
      limit: limit,
      inStock: true,
      countryId: countryId,
    );
  }

  /// Get total count of products (for pagination)
  static Future<int> getProductsCount({
    String? search,
    int? categoryId,
    int? clientId,
    bool? inStock,
    int? countryId,
  }) async {
    try {
      // Get currency configuration for country filtering
      CurrencyConfig? userCurrencyConfig;
      if (countryId != null) {
        userCurrencyConfig =
            await CurrencyConfigService.getCurrencyConfig(countryId);
      } else {
        userCurrencyConfig =
            await CurrencyConfigService.getCurrentUserCurrencyConfig();
      }

      if (userCurrencyConfig == null) {
        userCurrencyConfig = await CurrencyConfigService.getCurrencyConfig(
            1); // Default to Kenya
      }

      // Ensure we have a valid config
      if (userCurrencyConfig == null) {
        throw Exception('Unable to determine currency configuration');
      }

      String sql = '''
        SELECT COUNT(DISTINCT p.id) as count
        FROM Product p
        WHERE 1=1
      ''';

      List<dynamic> params = [];

      // Add search filter
      if (search != null && search.isNotEmpty) {
        sql += ' AND (p.name LIKE ? OR p.description LIKE ?)';
        params.addAll(['%$search%', '%$search%']);
      }

      // Add category filter
      if (categoryId != null) {
        sql += ' AND p.category_id = ?';
        params.add(categoryId);
      }

      // Add client filter
      if (clientId != null) {
        sql += ' AND p.clientId = ?';
        params.add(clientId);
      }

      // Add stock filtering for user's country
      sql += '''
        AND EXISTS (
          SELECT 1 FROM StoreQuantity sq
          JOIN Stores s ON sq.storeId = s.id
          WHERE sq.productId = p.id
          AND sq.quantity > 0
          AND s.countryId = ?
          AND s.status = 0
        )
      ''';
      params.add(userCurrencyConfig.countryId);

      final results = await _db.query(sql, params);
      return results.first.fields['count'] ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Parse datetime from various formats
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) {
      try {
        if (value.contains('T')) {
          return DateTime.parse(value);
        } else {
          return DateTime.parse(value.replaceAll(' ', 'T'));
        }
      } catch (e) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }
}