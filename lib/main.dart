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
import 'package:woosh/controllers/upliftcontroler/uplift_cart_controller.dart';
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
import 'package:woosh/services/core/client_storage_service.dart';

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
    // 🚀 FAST STARTUP: Initialize only essential services
    await GetStorage.init();
    await HiveInitializer.initialize();

    // 🚀 CRITICAL: Register controllers before app launch
    Get.put(AuthController());
    Get.put(UpliftCartController());

    // Initialize timezone for session management
    SessionService.initializeTimezone();

    // Request permissions (non-blocking)
    PermissionService().requestPermissions();

    // 🚀 LAUNCH APP IMMEDIATELY
    runApp(MyApp());

    // 🚀 INITIALIZE HEAVY SERVICES IN BACKGROUND
    _initializeServicesInBackground();
  } catch (e) {
    print('⚠️ Startup error: $e');

    // 🔧 EMERGENCY FIX: Clear corrupted Hive data if needed
    if (e
        .toString()
        .contains('type \'Null\' is not a subtype of type \'int\'')) {
      print('🔧 Emergency: Clearing corrupted Hive data...');
      try {
        await ClientStorageService.clearCorruptedData();
      } catch (clearError) {
        print('⚠️ Failed to clear corrupted data: $clearError');
      }
    }

    // Continue with app launch even if some services fail
    runApp(MyApp());
  }
}

/// Initialize services in background to avoid blocking UI
void _initializeServicesInBackground() {
  // Use microtask to avoid blocking the main thread
  Future.microtask(() async {
    try {
      // 🚀 DELAYED INITIALIZATION: Wait for app to be ready
      await Future.delayed(const Duration(seconds: 2));

      // Initialize database service (non-blocking)
      Get.putAsync(() async {
        try {
          final db = DatabaseService.instance;
          await db.initialize();
          return db;
        } catch (e) {
          print('⚠️ Database initialization failed: $e');
          // Return a mock service for offline mode
          return DatabaseService.instance;
        }
      });

      // Initialize product stock cache (non-blocking)
      _initializeProductStockCache();

      // Initialize fast stock service (non-blocking)
      StockService.instance.initialize().catchError((e) {
        print('⚠️ Stock service initialization failed: $e');
      });

      print('✅ Background services initialized successfully');
    } catch (e) {
      print('⚠️ Background service initialization failed: $e');
    }
  });
}

/// Initialize product stock cache on app startup
Future<void> _initializeProductStockCache() async {
  try {
    // 🚀 FAST CHECK: Only proceed if user is authenticated
    if (await TokenService.getValidAccessToken() == null) {
      return;
    }

    // 🚀 FAST CHECK: Only proceed if connected
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      return;
    }

    // Initialize ProductHiveService
    final productHiveService = ProductHiveService();
    await productHiveService.init();
    Get.put(productHiveService);

    // 🚀 FAST CHECK: Use cached data if fresh (30 minutes instead of 10)
    final lastUpdate = await productHiveService.getLastUpdateTime();
    final isCacheFresh = lastUpdate != null &&
        DateTime.now().difference(lastUpdate).inMinutes < 30;

    if (isCacheFresh) {
      print('✅ Using fresh product cache');
      return;
    }

    // 🚀 OPTIMIZED FETCH: Reduced limit for faster loading
    final products = await ProductService.getProducts(
      page: 1,
      limit: 500, // Reduced from 1000 for faster loading
      search: null,
    ).timeout(
      const Duration(seconds: 10), // Reduced timeout
      onTimeout: () {
        print('⏰ Product cache timeout, using existing data');
        return [];
      },
    );

    if (products.isNotEmpty) {
      // Save to cache
      await productHiveService.saveProducts(products);
      await productHiveService.setLastUpdateTime(DateTime.now());

      print('✅ Successfully cached ${products.length} products');

      // Process stock statistics in background
      _processStockStatistics(products);
    }
  } catch (e) {
    print('⚠️ Product cache initialization failed: $e');
  }
}

/// Process stock statistics in background to avoid blocking UI
void _processStockStatistics(List<dynamic> products) {
  compute(calculateStockStatistics, products)
      .then((stats) {})
      .catchError((e) {});
}

/// Get the initial page based on authentication status
Future<Widget> _getInitialPage(AuthController authController) async {
  // Check if user is authenticated using TokenService
  final isAuthenticated = await TokenService.getValidAccessToken() != null;

  if (!isAuthenticated || !authController.isLoggedIn.value) {
    return const LoginPage();
  } else {
    // All authenticated users go to HomePage
    return HomePage();
  }
}

class MyApp extends StatelessWidget {
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
        try {
          final authController = Get.find<AuthController>();

          // Add timeout for initialization to prevent infinite loading
          if (!authController.isInitialized.value) {
            // Show loading for max 5 seconds, then proceed anyway
            return FutureBuilder(
              future: Future.delayed(const Duration(seconds: 5)),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                } else {
                  // Force proceed after timeout
                  return FutureBuilder(
                    future: _getInitialPage(authController),
                    builder: (context, pageSnapshot) {
                      if (pageSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Scaffold(
                          body: Center(child: CircularProgressIndicator()),
                        );
                      }
                      return pageSnapshot.data ?? const LoginPage();
                    },
                  );
                }
              },
            );
          }

          return FutureBuilder(
            future: _getInitialPage(authController),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              return snapshot.data ?? const LoginPage();
            },
          );
        } catch (e) {
          // If AuthController is not available, show login page
          return const LoginPage();
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
