import 'package:woosh/services/core/product_service.dart';
import 'package:woosh/services/core/currency_config_service.dart';

/// Example usage of the automated product service with dynamic currency handling
class ProductServiceUsageExample {
  /// Example 1: Get products for current user's country (automatic currency detection)
  static Future<void> getProductsForCurrentUser() async {
    try {

      // The service automatically detects the user's country and applies appropriate currency
      final products = await ProductService.getProducts(
        page: 1,
        limit: 10,
      );


      // Display products with their currency-converted prices
      for (final product in products) {

        // Display price options with converted currency
        for (final priceOption in product.priceOptions) {
        }
      }
    } catch (e) {
    }
  }

  /// Example 2: Get products for a specific country (manual currency selection)
  static Future<void> getProductsForSpecificCountry(int countryId) async {
    try {

      // Get currency configuration for the country
      final currencyConfig =
          await CurrencyConfigService.getCurrencyConfig(countryId);

      if (currencyConfig == null) {
        return;
      }

      print(
          '🌍 [Example] Using currency: ${currencyConfig.currencyCode} (${currencyConfig.countryName})');

      // Get products with specific country currency
      final products = await ProductService.getProducts(
        page: 1,
        limit: 5,
        countryId: countryId,
      );

      print(
          '✅ [Example] Found ${products.length} products in ${currencyConfig.currencyCode}');

      // Display products with formatted currency
      for (final product in products) {
        final formattedPrice = CurrencyConfigService.formatCurrency(
            product.unitCost, currencyConfig);
      }
    } catch (e) {
    }
  }

  /// Example 3: Search products with currency conversion
  static Future<void> searchProductsWithCurrency(String searchQuery) async {
    try {

      final products = await ProductService.searchProducts(
        searchQuery,
        page: 1,
        limit: 5,
      );


      for (final product in products) {
      }
    } catch (e) {
    }
  }

  /// Example 4: Get product by ID with currency conversion
  static Future<void> getProductByIdWithCurrency(int productId) async {
    try {

      final product = await ProductService.getProductById(productId);

      if (product == null) {
        return;
      }


      // Display price options
      for (final priceOption in product.priceOptions) {
      }
    } catch (e) {
    }
  }

  /// Example 5: Demonstrate currency configuration system
  static Future<void> demonstrateCurrencyConfig() async {
    try {

      // Get all supported countries
      final supportedCountries =
          await CurrencyConfigService.getSupportedCountries();

      for (final country in supportedCountries) {
        print(
            '   ${country['countryName']} (ID: ${country['countryId']}) - ${country['currencyCode']}');
      }

      // Get current user's currency config
      final userConfig =
          await CurrencyConfigService.getCurrentUserCurrencyConfig();

      if (userConfig != null) {
        print(
            '👤 [Example] Current user currency: ${userConfig.currencyCode} (${userConfig.countryName})');
      }

      // Test currency formatting
      if (userConfig != null) {
        final testAmount = 1234.56;
        final formatted =
            CurrencyConfigService.formatCurrency(testAmount, userConfig);
        print(
            '💱 [Example] Currency formatting test: $testAmount → $formatted');
      }
    } catch (e) {
    }
  }

  /// Example 6: How to add a new country (demonstration)
  static Future<void> demonstrateAddingNewCountry() async {
    print('''
📋 [Example] How to add a new country to the system:

1. Add the country to the database:
   INSERT INTO Country (name, status) VALUES ('Uganda', 0);

2. Add currency fields to Product table:
   ALTER TABLE Product ADD COLUMN unit_cost_ugx DECIMAL(11,2);
   ALTER TABLE Product ADD COLUMN unit_cost_ugx_updated_at TIMESTAMP;

3. Add currency fields to PriceOption table:
   ALTER TABLE PriceOption ADD COLUMN value_ugx DECIMAL(11,2);

4. Update CurrencyConfigService._determineCurrencyConfig() method:
   case 4: // Uganda
     return CurrencyConfig(
       countryId: countryId,
       countryName: countryName,
       currencyCode: 'UGX',
       currencySymbol: 'UGX',
       position: 'before',
       decimalPlaces: 0,
       productField: 'unit_cost_ugx',
       priceOptionField: 'value_ugx',
     );

5. The system will automatically detect and use the new currency!
   No other code changes needed.
''');
  }

  /// Run all examples
  static Future<void> runAllExamples() async {

    await demonstrateCurrencyConfig();

    await getProductsForCurrentUser();

    await getProductsForSpecificCountry(1); // Kenya

    await getProductsForSpecificCountry(2); // Tanzania

    await getProductsForSpecificCountry(3); // Nigeria

    await searchProductsWithCurrency('product');

    await getProductByIdWithCurrency(1);

    demonstrateAddingNewCountry();

  }
}

/// Usage in your app:
/// 
/// ```dart
/// // Get products for current user (automatic currency)
/// final products = await ProductService.getProducts();
/// 
/// // Get products for specific country
/// final kenyaProducts = await ProductService.getProducts(countryId: 1);
/// final tanzaniaProducts = await ProductService.getProducts(countryId: 2);
/// final nigeriaProducts = await ProductService.getProducts(countryId: 3);
/// 
/// // Search products
/// final searchResults = await ProductService.searchProducts('milk');
/// 
/// // Get specific product
/// final product = await ProductService.getProductById(123);
/// 
/// // Get currency configuration
/// final userCurrency = await CurrencyConfigService.getCurrentUserCurrencyConfig();
/// final formattedPrice = CurrencyConfigService.formatCurrency(1000.50, userCurrency!);
/// ``` 