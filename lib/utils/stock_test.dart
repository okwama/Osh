import 'package:woosh/services/core/stock_service.dart';

/// Test utility for stock service performance
class StockTest {
  static void testStockService() {
    print('🧪 Testing StockService performance...');

    final stopwatch = Stopwatch()..start();

    // Test multiple stock checks
    for (int i = 1; i <= 100; i++) {
      StockService.instance.getStock(i);
      StockService.instance.isInStock(i);
      StockService.instance.isOutOfStock(i);
      StockService.instance.getStockStatusText(i);
    }

    stopwatch.stop();

    print(
        '✅ 400 stock operations completed in ${stopwatch.elapsedMilliseconds}ms');
    print('📊 Average: ${stopwatch.elapsedMilliseconds / 400}ms per operation');

    // Get cache statistics
    final stats = StockService.instance.getCacheStats();
    print('📈 Cache Statistics:');
    print('   - Total products: ${stats['total_products']}');
    print('   - Products in stock: ${stats['products_in_stock']}');
    print('   - Products out of stock: ${stats['products_out_of_stock']}');
    print('   - Products low stock: ${stats['products_low_stock']}');
    print('   - Total stock units: ${stats['total_stock_units']}');
    print('   - User region ID: ${stats['user_region_id']}');
    print('   - Is initialized: ${stats['is_initialized']}');
  }
}
