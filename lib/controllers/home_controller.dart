import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:woosh/services/core/task_service.dart';
import 'package:woosh/services/core/journeyplan/journey_plan_service.dart';
import 'package:woosh/services/core/session_service.dart';
import 'package:woosh/services/core/notice_service.dart';
import 'package:woosh/services/hive/product_hive_service.dart';
import 'package:woosh/services/hive/cart_hive_service.dart';
import 'package:woosh/controllers/cart_controller.dart';
import 'package:woosh/controllers/auth/auth_controller.dart';
import 'package:woosh/models/journeyplan/journeyplan_model.dart';
import 'package:woosh/utils/performance_monitor.dart';
import 'package:woosh/utils/performance_optimizer.dart';
import 'package:flutter/material.dart';

/// Controller for Home page business logic and state management
class HomeController extends GetxController {
  // Observable variables
  final RxString salesRepName = 'User'.obs;
  final RxString salesRepPhone = 'No phone number'.obs;
  final RxInt pendingJourneyPlans = 0.obs;
  final RxInt pendingTasks = 0.obs;
  final RxInt unreadNotices = 0.obs;
  final RxBool isLoading = true.obs;
  final RxBool isSessionActive = false.obs;
  final RxBool isRefreshing = false.obs;

  // Services
  final CartController _cartController = Get.find<CartController>();
  final AuthController _authController = Get.find<AuthController>();

  @override
  void onInit() {
    super.onInit();
    _loadUserData();
    _loadAllDataInParallel();
  }

  /// Load user data from storage
  void _loadUserData() {
    PerformanceMonitor.startTimer('load_user_data');

    try {
      final box = GetStorage();
      final salesRep = box.read('salesRep');

      if (salesRep != null && salesRep is Map<String, dynamic>) {
        salesRepName.value = salesRep['name'] ?? 'User';
        salesRepPhone.value = salesRep['phoneNumber'] ?? 'No phone number';
      }
    } catch (e) {
      print('⚠️ Error loading user data: $e');
    } finally {
      PerformanceMonitor.endTimer('load_user_data');
    }
  }

  /// Load pending journey plans count
  Future<void> _loadPendingJourneyPlans() async {
    return PerformanceOptimizer.monitorSlowOperation(
        'load_pending_journey_plans', () async {
      try {
        final journeyPlans = await JourneyPlanService.getJourneyPlans();

        // Get today's date in local time
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        pendingJourneyPlans.value = journeyPlans.where((plan) {
          // Convert plan date from UTC to local time
          final localDate = plan.date.toLocal();
          // Check if plan is pending (status = 0) AND is for today
          return plan.status == JourneyPlan.statusPending &&
              localDate.year == today.year &&
              localDate.month == today.month &&
              localDate.day == today.day;
        }).length;
      } catch (e) {
        print('⚠️ Error loading pending journey plans: $e');
        pendingJourneyPlans.value = 0;
      }
    });
  }

  /// Load pending tasks count
  Future<void> loadPendingTasks() async {
    return PerformanceOptimizer.monitorSlowOperation('load_pending_tasks',
        () async {
      try {
        final tasks = await TaskService.getTasks();
        pendingTasks.value = tasks.length;
      } catch (e) {
        print('⚠️ Error loading pending tasks: $e');
        pendingTasks.value = 0;
      }
    });
  }

  /// Load unread notices count
  Future<void> loadUnreadNotices() async {
    return PerformanceOptimizer.monitorSlowOperation('load_unread_notices',
        () async {
      try {
        // Get count of recent notices (last 30 days)
        final recentNotices = await NoticeService.getRecentNoticesCount(30);
        unreadNotices.value = recentNotices;
      } catch (e) {
        print('⚠️ Error loading unread notices: $e');
        unreadNotices.value = 0;
      }
    });
  }

  /// Check session status
  Future<void> checkSessionStatus() async {
    return PerformanceOptimizer.monitorSlowOperation('check_session_status',
        () async {
      try {
        final box = GetStorage();
        final userId = box.read<String>('userId');

        if (userId != null) {
          final currentSession =
              await SessionService.getCurrentSession(int.parse(userId));
          isSessionActive.value = currentSession?.isActive ?? false;
        }
      } catch (e) {
        print('⚠️ Error checking session status: $e');
        // Don't change session state on database errors - keep current state
      }
    });
  }

  /// Load all data in parallel for better performance
  Future<void> _loadAllDataInParallel() async {
    PerformanceMonitor.startTimer('load_all_data_parallel');

    try {
      // Load all data in parallel for better performance
      await Future.wait([
        _loadPendingJourneyPlans(),
        loadPendingTasks(),
        loadUnreadNotices(),
        checkSessionStatus(),
      ]);
    } catch (e) {
      print('⚠️ Error loading data in parallel: $e');
    } finally {
      isLoading.value = false;
      PerformanceMonitor.endTimer('load_all_data_parallel');
    }
  }

  /// Refresh all data and clear caches
  Future<void> refreshData() async {
    if (isRefreshing.value) return;

    isRefreshing.value = true;
    PerformanceMonitor.startTimer('refresh_data');

    try {
      // Clear cart data
      await _cartController.clear();

      // Clear GetStorage cache in background
      _clearCacheInBackground();

      // Clear Hive caches if services are available
      await _clearHiveCaches();

      // Clear session cache
      SessionService.clearCache();

      // Reload all data
      await _loadAllDataInParallel();
      _loadUserData();
      await checkSessionStatus();

      Get.snackbar(
        '✅ Success',
        'Dashboard refreshed and all caches cleared',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      print('🔇 Silent error [home-refresh]: $e');
      Get.snackbar(
        '🔄 Refreshed',
        'Dashboard refreshed',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } finally {
      isRefreshing.value = false;
      PerformanceMonitor.endTimer('refresh_data');
    }
  }

  /// Clear cache in background to avoid blocking UI
  void _clearCacheInBackground() {
    Future.microtask(() async {
      try {
        final box = GetStorage();
        final keys = box.getKeys();
        final keysToRemove = keys
            .where((key) =>
                key.startsWith('cache_') ||
                key.startsWith('outlets_') ||
                key.startsWith('products_') ||
                key.startsWith('routes_') ||
                key.startsWith('notices_') ||
                key.startsWith('clients_') ||
                key.startsWith('orders_'))
            .toList();

        for (final key in keysToRemove) {
          box.remove(key);
        }
      } catch (e) {
        print('⚠️ Error clearing cache: $e');
      }
    });
  }

  /// Clear Hive caches
  Future<void> _clearHiveCaches() async {
    try {
      final productHiveService = Get.find<ProductHiveService>();
      await productHiveService.clearAllProducts();
    } catch (e) {
      print('⚠️ Error clearing product cache: $e');
    }

    try {
      final cartHiveService = Get.find<CartHiveService>();
      await cartHiveService.clearCart();
    } catch (e) {
      print('⚠️ Error clearing cart cache: $e');
    }
  }

  /// Logout user
  Future<void> logout() async {
    try {
      // Show loading indicator
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      // Clear cart data
      await _cartController.clear();

      // Clear authentication data from GetStorage
      final box = GetStorage();
      await box.remove('userId');
      await box.remove('salesRep');
      await box.remove('authToken');
      await box.remove('refreshToken');
      await box.remove('accessToken');
      await box.remove('userCredentials');
      await box.remove('userSession');
      await box.remove('loginTime');
      await box.remove('sessionId');

      // Update auth controller state
      await _authController.logout();

      // Close loading indicator
      Get.back();

      // Navigate to login page and clear all previous routes
      Get.offAllNamed('/login');

      // Show success message
      Get.snackbar(
        'Logged Out',
        'You have been successfully logged out',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      print('⚠️ Error during logout: $e');

      // Close loading indicator if it's showing
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

      // Force local logout for any errors
      final box = GetStorage();
      await box.remove('userId');
      await box.remove('salesRep');
      await box.remove('authToken');
      await box.remove('refreshToken');
      await box.remove('accessToken');

      Get.offAllNamed('/login');
      Get.snackbar(
        'Logged Out',
        'Logged out locally',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
    }
  }

  /// Get session status text
  String get sessionStatusText =>
      isSessionActive.value ? '🟢 Session Active' : '🔴 Session Inactive';

  /// Get user profile subtitle
  String get userProfileSubtitle =>
      '$salesRepName\n$salesRepPhone\n$sessionStatusText';

  /// Check if journey plans can be accessed
  bool get canAccessJourneyPlans => isSessionActive.value;

  /// Get cart items count
  int get cartItemsCount => _cartController.totalItems;
}
