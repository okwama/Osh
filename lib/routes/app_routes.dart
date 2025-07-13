import 'package:get/get.dart';
import 'package:woosh/pages/journeyplan/feedback_report_page.dart';
import 'package:woosh/pages/journeyplan/reports/product_availability_page.dart';
import 'package:woosh/pages/journeyplan/reports/visibility_activity_page.dart';
import 'package:woosh/pages/journeyplan/journeyplans_page.dart';
import 'package:woosh/pages/order/viewOrder/vieworder_page.dart';
import 'package:woosh/pages/pos/upliftSaleCart_page.dart';
import 'package:woosh/controllers/upliftcontroler/uplift_cart_controller.dart';
import 'package:woosh/controllers/upliftcontroler/uplift_sale_controller.dart';
import 'package:woosh/pages/login/sign_page.dart';
import 'package:woosh/pages/pos/uplift_sales_page.dart';
import 'package:woosh/pages/test/database_test_page.dart';
import 'package:woosh/middleware/auth_middleware.dart';
import 'package:woosh/app_update.dart';

class AppRoutes {
  static final routes = [
    // Journey Plans Route (Protected)
    GetPage(
      name: '/journeyplans',
      page: () => const JourneyPlansPage(),
      transition: Transition.rightToLeft,
      middlewares: [AuthMiddleware()],
    ),
    // Report Routes (Protected)
    GetPage(
      name: '/journey/reports/feedback',
      page: () => FeedbackReportPage(journeyPlan: Get.arguments['journeyPlan']),
      transition: Transition.rightToLeft,
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/journey/reports/product',
      page: () =>
          ProductAvailabilityPage(journeyPlan: Get.arguments['journeyPlan']),
      transition: Transition.rightToLeft,
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/journey/reports/visibility',
      page: () =>
          VisibilityActivityPage(journeyPlan: Get.arguments['journeyPlan']),
      transition: Transition.rightToLeft,
      middlewares: [AuthMiddleware()],
    ),
    // Orders Route (Protected)
    GetPage(
      name: '/orders',
      page: () => const ViewOrdersPage(),
      transition: Transition.rightToLeft,
      middlewares: [AuthMiddleware()],
    ),
    // Uplift Product Routes (Protected)
    GetPage(
      name: '/uplift/cart',
      page: () => UpliftSaleCartPage(
        outlet: Get.arguments['outlet'],
      ),
      binding: BindingsBuilder(() {
        Get.lazyPut<UpliftCartController>(() => UpliftCartController());
      }),
      transition: Transition.rightToLeft,
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/uplift-sales',
      page: () => const UpliftSalesPage(),
      binding: BindingsBuilder(() {
        Get.lazyPut<UpliftSaleController>(() => UpliftSaleController());
      }),
      middlewares: [AuthMiddleware()],
    ),
    // Sign Up Route (Guest only)
    GetPage(
      name: '/sign-up',
      page: () => const SignUpPage(),
      transition: Transition.rightToLeft,
      middlewares: [GuestMiddleware()],
    ),
    // Test Routes (Protected)
    GetPage(
      name: '/test/database',
      page: () => const DatabaseTestPage(),
      transition: Transition.rightToLeft,
      middlewares: [AuthMiddleware()],
    ),
    // App Update Route (No middleware - accessible to all)
    GetPage(
      name: '/app-update',
      page: () => const UpdateWidget(),
      transition: Transition.fadeIn,
    ),
  ];
}
