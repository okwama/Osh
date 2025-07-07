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

    // Open boxes
    await Hive.openBox<OrderModel>('orders');
    await Hive.openBox<UserModel>('users');
    await Hive.openBox<ClientModel>('clients');
    await Hive.openBox<JourneyPlanModel>('journeyPlans');
    await Hive.openBox<SessionModel>('sessionBox');
    await Hive.openBox<RouteModel>('routes');
    await Hive.openBox<PendingJourneyPlanModel>('pendingJourneyPlans');
    await Hive.openBox<ProductReportHiveModel>('productReports');
    await Hive.openBox<ProductHiveModel>('products');
    await Hive.openBox<PendingSessionModel>('pendingSessions');

    // Open general timestamp box for tracking last update times
    await Hive.openBox('timestamps');

    // Initialize and register existing Hive services
    final cartHiveService = CartHiveService();
    await cartHiveService.init();
    Get.put(cartHiveService);

    final productHiveService = ProductHiveService();
    await productHiveService.init();
    Get.put(productHiveService);
  }
}
