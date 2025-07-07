import 'package:woosh/services/core/stock_service.dart';

/// Test utility for stock service performance
class StockTest {
  static void testStockService() {

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

    // Get cache statistics
    final stats = StockService.instance.getCacheStats();
  }
}