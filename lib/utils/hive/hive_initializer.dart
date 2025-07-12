import 'package:hive_flutter/hive_flutter.dart';
import 'package:woosh/models/hive/client_model.dart';
import 'package:woosh/models/hive/journey_plan_model.dart';
import 'package:woosh/models/hive/order_model.dart';
import 'package:woosh/models/hive/user_model.dart';
import 'package:woosh/models/hive/session_model.dart';
import 'package:woosh/models/hive/route_model.dart';
import 'package:woosh/models/hive/pending_journey_plan_model.dart';
import 'package:woosh/models/hive/product_report_hive_model.dart';
import 'package:woosh/models/hive/product_model.dart';
import 'package:woosh/models/hive/pending_session_model.dart';
import 'package:get/get.dart';
import 'package:woosh/services/hive/cart_hive_service.dart';
import 'package:woosh/services/hive/product_hive_service.dart';

class HiveInitializer {
  static Future<void> initialize() async {
    try {
      await Hive.initFlutter();

      // Register adapters
      Hive.registerAdapter(OrderModelAdapter());
      Hive.registerAdapter(OrderItemModelAdapter());
      Hive.registerAdapter(UserModelAdapter());
      Hive.registerAdapter(ClientModelAdapter());
      Hive.registerAdapter(JourneyPlanModelAdapter());
      Hive.registerAdapter(SessionModelAdapter());
      Hive.registerAdapter(RouteModelAdapter());
      Hive.registerAdapter(PendingJourneyPlanModelAdapter());
      Hive.registerAdapter(ProductReportHiveModelAdapter());
      Hive.registerAdapter(ProductQuantityHiveModelAdapter());
      Hive.registerAdapter(ProductHiveModelAdapter());
      Hive.registerAdapter(PendingSessionModelAdapter());

      // Open boxes with error handling
      await _openBoxSafely<OrderModel>('orders');
      await _openBoxSafely<UserModel>('users');
      await _openBoxSafely<ClientModel>('clients');
      await _openBoxSafely<JourneyPlanModel>('journeyPlans');
      await _openBoxSafely<SessionModel>('sessionBox');
      await _openBoxSafely<RouteModel>('routes');
      await _openBoxSafely<PendingJourneyPlanModel>('pendingJourneyPlans');
      await _openBoxSafely<ProductReportHiveModel>('productReports');
      await _openBoxSafely<ProductHiveModel>('products');
      await _openBoxSafely<PendingSessionModel>('pendingSessions');

      // Open general timestamp box for tracking last update times
      await _openBoxSafely('timestamps');

      // Initialize and register existing Hive services
      final cartHiveService = CartHiveService();
      await cartHiveService.init();
      Get.put(cartHiveService);

      final productHiveService = ProductHiveService();
      await productHiveService.init();
      Get.put(productHiveService);
    } catch (e) {
      print('⚠️ Hive initialization error: $e');
      // Clear corrupted data and retry
      await _clearCorruptedData();
      rethrow;
    }
  }

  static Future<void> _openBoxSafely<T>(String boxName) async {
    try {
      if (T == dynamic) {
        await Hive.openBox(boxName);
      } else {
        await Hive.openBox<T>(boxName);
      }
    } catch (e) {
      print('⚠️ Error opening box $boxName: $e');
      // Delete corrupted box and recreate
      await Hive.deleteBoxFromDisk(boxName);
      if (T == dynamic) {
        await Hive.openBox(boxName);
      } else {
        await Hive.openBox<T>(boxName);
      }
    }
  }

  static Future<void> _clearCorruptedData() async {
    try {
      final boxNames = [
        'orders', 'users', 'clients', 'journeyPlans', 'sessionBox',
        'routes', 'pendingJourneyPlans', 'productReports', 'products',
        'pendingSessions', 'timestamps'
      ];
      
      for (final boxName in boxNames) {
        try {
          await Hive.deleteBoxFromDisk(boxName);
          print('✅ Cleared corrupted box: $boxName');
        } catch (e) {
          print('⚠️ Failed to clear box $boxName: $e');
        }
      }
    } catch (e) {
      print('⚠️ Error clearing corrupted data: $e');
    }
  }
}
