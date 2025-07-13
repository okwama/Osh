import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:woosh/models/journeyplan/journeyplan_model.dart';
import 'package:woosh/services/core/task_service.dart';
import 'package:woosh/services/core/journeyplan/journey_plan_service.dart';
import 'package:woosh/services/core/session_service.dart';
import 'package:woosh/services/core/notice_service.dart';
import 'package:woosh/services/hive/product_hive_service.dart';
import 'package:woosh/services/hive/cart_hive_service.dart';
import 'package:woosh/utils/error_handler.dart';
import 'package:woosh/services/auth_service.dart';

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

  // Storage instance
  final GetStorage _storage = GetStorage();

  @override
  void onInit() {
    super.onInit();
    loadUserData();
    loadAllDataInParallel();
  }

  /// Load user data from storage
  void loadUserData() {
    try {
      final salesRep = _storage.read('salesRep');

      if (salesRep != null && salesRep is Map<String, dynamic>) {
        salesRepName.value = salesRep['name'] ?? 'User';
        salesRepPhone.value = salesRep['phoneNumber'] ?? 'No phone number';
      } else {
        salesRepName.value = 'User';
        salesRepPhone.value = 'No phone number';
      }
    } catch (e) {
      ErrorHandler.handleSilentError(e, context: 'HomeController.loadUserData');
    }
  }

  /// Load pending journey plans count
  Future<void> loadPendingJourneyPlans() async {
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
      ErrorHandler.handleSilentError(e,
          context: 'HomeController.loadPendingJourneyPlans');
      pendingJourneyPlans.value = 0;
    }
  }

  /// Load pending tasks count
  Future<void> loadPendingTasks() async {
    try {
      final tasks = await TaskService.getTasks();
      pendingTasks.value = tasks.length;
    } catch (e) {
      ErrorHandler.handleSilentError(e,
          context: 'HomeController.loadPendingTasks');
      pendingTasks.value = 0;
    }
  }

  /// Load unread notices count
  Future<void> loadUnreadNotices() async {
    try {
      // Get count of recent notices (last 30 days)
      final recentNotices = await NoticeService.getRecentNoticesCount(30);
      unreadNotices.value = recentNotices;
    } catch (e) {
      ErrorHandler.handleSilentError(e,
          context: 'HomeController.loadUnreadNotices');
      unreadNotices.value = 0;
    }
  }

  /// Check session status
  Future<void> checkSessionStatus() async {
    try {
      final userId = _storage.read<String>('userId');

      if (userId != null) {
        final currentSession =
            await SessionService.getCurrentSession(int.parse(userId));
        isSessionActive.value = currentSession?.isActive ?? false;
      }
    } catch (e) {
      // Don't change session state on database errors - keep current state
      // This prevents false "session expired" messages
      ErrorHandler.handleSilentError(e,
          context: 'HomeController.checkSessionStatus');
    }
  }

  /// Load all data in parallel
  Future<void> loadAllDataInParallel() async {
    try {
      // Load all data in parallel for better performance
      await Future.wait([
        loadPendingJourneyPlans(),
        loadPendingTasks(),
        loadUnreadNotices(),
        checkSessionStatus(),
      ]);
    } catch (e) {
      ErrorHandler.handleSilentError(e,
          context: 'HomeController.loadAllDataInParallel');
    } finally {
      isLoading.value = false;
    }
  }

  /// Clear cache in background
  Future<void> clearCacheInBackground() async {
    try {
      final keys = _storage.getKeys();
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
        _storage.remove(key);
      }
    } catch (e) {
      ErrorHandler.handleSilentError(e,
          context: 'HomeController.clearCacheInBackground');
    }
  }

  /// Clear product cache
  Future<void> clearProductCache() async {
    try {
      final productHiveService = Get.find<ProductHiveService>();
      await productHiveService.clearAllProducts();
    } catch (e) {
      ErrorHandler.handleSilentError(e,
          context: 'HomeController.clearProductCache');
    }
  }

  /// Clear cart cache
  Future<void> clearCartCache() async {
    try {
      final cartHiveService = Get.find<CartHiveService>();
      await cartHiveService.clearCart();
    } catch (e) {
      ErrorHandler.handleSilentError(e,
          context: 'HomeController.clearCartCache');
    }
  }

  /// Refresh all data
  Future<void> refreshData() async {
    isRefreshing.value = true;

    try {
      // Clear session cache
      SessionService.clearCache();

      // Clear caches in parallel
      await Future.wait([
        clearCacheInBackground(),
        clearProductCache(),
        clearCartCache(),
      ]);

      // Reload all data
      await loadAllDataInParallel();
    } catch (e) {
      ErrorHandler.handleSilentError(e, context: 'HomeController.refreshData');
    } finally {
      isLoading.value = false;
      isRefreshing.value = false;
    }
  }

  /// Logout user
  Future<void> logout() async {
    try {
      await AuthService.instance.logout();
      Get.offAllNamed('/login');
    } catch (e) {
      ErrorHandler.handleGeneralError(e,
          context: 'HomeController.logout',
          customMessage: 'Failed to logout. Please try again.');
    }
  }

  /// Get cart items count
  int get cartItemsCount {
    try {
      final cartHiveService = Get.find<CartHiveService>();
      return cartHiveService.getCartItems().length;
    } catch (e) {
      ErrorHandler.handleSilentError(e,
          context: 'HomeController.cartItemsCount');
      return 0;
    }
  }

  /// Get user profile subtitle
  String get userProfileSubtitle {
    if (isSessionActive.value) {
      return 'Active Session';
    } else {
      return 'Start Work Session';
    }
  }

  /// Check if user can access journey plans
  bool get canAccessJourneyPlans => isSessionActive.value;

  /// Get user data as a map
  Map<String, dynamic> getUserData() {
    return {
      'name': salesRepName.value,
      'phone': salesRepPhone.value,
    };
  }

  /// Get dashboard statistics
  Map<String, int> getDashboardStats() {
    return {
      'pendingJourneyPlans': pendingJourneyPlans.value,
      'pendingTasks': pendingTasks.value,
      'unreadNotices': unreadNotices.value,
    };
  }

  /// Check if user has active session
  bool get hasActiveSession => isSessionActive.value;

  /// Check if data is loading
  bool get isDataLoading => isLoading.value;
}
