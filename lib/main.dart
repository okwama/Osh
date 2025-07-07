import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:woosh/pages/404/offlineToast.dart';
import 'package:woosh/pages/home/home_page.dart';
import 'package:woosh/pages/login/login_page.dart';
import 'package:get_storage/get_storage.dart';
import 'package:woosh/routes/app_routes.dart';
import 'package:woosh/services/token_service.dart';
import 'package:woosh/controllers/auth/auth_controller.dart';
import 'package:woosh/controllers/uplift_cart_controller.dart';
import 'package:woosh/utils/app_theme.dart';
import 'package:woosh/utils/hive/hive_initializer.dart';
import 'package:hive/hive.dart';
import 'package:woosh/models/hive/session_model.dart';
import 'package:woosh/services/core/product_service.dart';
import 'package:woosh/services/hive/product_hive_service.dart';
import 'package:woosh/services/core/stock_service.dart';
import 'package:woosh/services/core/session_service.dart';
import 'package:woosh/services/database_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:woosh/services/permission_service.dart';

/// Top-level function to calculate stock statistics for background processing
Map<String, int> calculateStockStatistics(List<dynamic> products) {
  num totalStock = 0;
  int productsInStock = 0;
  int productsOutOfStock = 0;

  for (final product in products) {
    if (product.storeQuantities.isNotEmpty) {
      final totalProductStock = product.storeQuantities
          .map((sq) => sq.quantity)
          .reduce((a, b) => a + b);
      totalStock += totalProductStock;

      if (totalProductStock > 0) {
        productsInStock++;
      } else {
        productsOutOfStock++;
      }
    }
  }

  return {
    'totalProducts': products.length,
    'productsInStock': productsInStock,
    'productsOutOfStock': productsOutOfStock,
    'totalStock': totalStock.toInt(),
  };
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // ✅ CENTRALIZED DATABASE INITIALIZATION
    await Get.putAsync(() async {
      final db = DatabaseService.instance;
      await db.initialize();
      return db;
    });

    await GetStorage.init();
    // Initialize Hive with all adapters
    await HiveInitializer.initialize();

    // Initialize timezone for session management
    SessionService.initializeTimezone();

    Get.put(AuthController());
    Get.put(UpliftCartController());

    // Request permissions before app starts
    await PermissionService().requestPermissions();

    // Initialize services in background to avoid blocking UI
    _initializeServicesInBackground();

    // Test stock service performance (remove in production)
    // StockTest.testStockService();

    runApp(MyApp());
  } catch (e) {
    // Continue with app launch even if some services fail
  }
}

/// Initialize services in background to avoid blocking UI
void _initializeServicesInBackground() {
  // Use microtask to avoid blocking the main thread
  Future.microtask(() async {
    try {
      // Initialize product stock cache
      await _initializeProductStockCache();

      // Initialize fast stock service
      await StockService.instance.initialize();

    } catch (e) {
    }
  });
}

/// Initialize product stock cache on app startup
Future<void> _initializeProductStockCache() async {
  try {

    // Check if user is authenticated
    if (!TokenService.isAuthenticated()) {
      return;
    }

    // Check connectivity
    final connectivityResult = await Connectivity().checkConnectivity();
    final isConnected = connectivityResult != ConnectivityResult.none;

    if (!isConnected) {
      return;
    }

    // Initialize ProductHiveService
    final productHiveService = ProductHiveService();
    await productHiveService.init();
    Get.put(productHiveService);

    // Check if cache is fresh (less than 10 minutes old)
    final lastUpdate = await productHiveService.getLastUpdateTime();
    final isCacheFresh = lastUpdate != null &&
        DateTime.now().difference(lastUpdate).inMinutes < 10;

    if (isCacheFresh) {
      return;
    }


    // Fetch all products with stock data
    final products = await ProductService.getProducts(
      page: 1,
      limit: 1000, // Fetch more products for comprehensive cache
      search: null,
    );

    if (products.isNotEmpty) {
      // Save to cache
      await productHiveService.saveProducts(products);
      await productHiveService.setLastUpdateTime(DateTime.now());

      print(
          '✅ Successfully cached ${products.length} products with stock data');

      // Process stock statistics in background
      _processStockStatistics(products);
    } else {
    }
  } catch (e) {
    // Don't fail app startup if stock cache fails
  }
}

/// Process stock statistics in background to avoid blocking UI
void _processStockStatistics(List<dynamic> products) {
  compute(calculateStockStatistics, products).then((stats) {
  }).catchError((e) {
  });
}

class MyApp extends StatelessWidget {
  final AuthController authController = Get.find<AuthController>();

  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Whoosh',
      defaultTransition: Transition.cupertino,
      transitionDuration: const Duration(milliseconds: 200),
      theme: ThemeData(
        primaryColor:
            goldMiddle2, // Use goldMiddle2 as primary color (most similar to previous gold)
        scaffoldBackgroundColor: appBackground,
        colorScheme: ColorScheme.light(
          primary: goldMiddle2,
          secondary: blackColor,
          surface: const Color(
              0xFFF4EBD0), // Update surface color to match background
          background: appBackground,
          error: Colors.red,
          onPrimary: const Color(0xFFFDFBD4),
          onSecondary: const Color.fromARGB(255, 252, 252, 252),
          onSurface: goldMiddle2,
          onBackground: const Color.fromARGB(255, 252, 252, 252),
          onError: const Color.fromARGB(255, 255, 255, 255),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: goldMiddle2,
          foregroundColor: const Color.fromARGB(255, 255, 255, 255),
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: const Color.fromARGB(255, 255, 255, 255),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: goldMiddle2,
            foregroundColor: const Color.fromARGB(255, 255, 255, 255),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: goldMiddle2,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color.fromARGB(255, 255, 255, 255),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:
                const BorderSide(color: Color.fromARGB(255, 156, 156, 153)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:
                const BorderSide(color: Color.fromARGB(255, 188, 188, 188)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: goldMiddle2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.red),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.red),
          ),
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
        textTheme: GoogleFonts.quicksandTextTheme(
          Theme.of(context).textTheme,
        ),
      ),
      home: Obx(() {
        if (!authController.isInitialized.value) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        // Check if user is authenticated using TokenService
        final isAuthenticated = TokenService.isAuthenticated();

        if (!isAuthenticated || !authController.isLoggedIn.value) {
          return const LoginPage();
        } else {
          // All authenticated users go to HomePage
          return HomePage();
        }
      }),
      getPages: [
        GetPage(name: '/login', page: () => const LoginPage()),
        GetPage(name: '/home', page: () => HomePage()),
        GetPage(name: '/no_connection', page: () => const OfflineToast()),
        ...AppRoutes.routes,
      ],
    );
  }
}