import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:woosh/models/hive/session_model.dart';
import 'package:woosh/pages/Leave/leaveapplication_page.dart';
import 'package:woosh/pages/Leave/leave_dashboard_page.dart';
import 'package:woosh/pages/client/viewclient_page.dart';
import 'package:woosh/pages/journeyplan/reports/pages/product_return_page.dart';
import 'package:woosh/pages/login/login_page.dart';
import 'package:woosh/pages/order/viewOrder/vieworder_page.dart';
import 'package:woosh/pages/pos/upliftSaleCart_page.dart';
import 'package:woosh/pages/task/task.dart';
import 'package:woosh/services/core/task_service.dart';
import 'package:woosh/services/core/journey_plan_service.dart';
import 'package:woosh/services/core/session_service.dart';
import 'package:woosh/models/journeyplan/journeyplan_model.dart';
import 'package:woosh/services/core/notice_service.dart';
import 'package:woosh/services/hive/product_hive_service.dart';
import 'package:woosh/services/hive/cart_hive_service.dart';

import 'package:woosh/pages/profile/profile.dart';
import 'package:woosh/utils/app_theme.dart';
import 'package:woosh/widgets/gradient_app_bar.dart';
import 'package:woosh/widgets/gradient_widgets.dart';
import 'package:woosh/models/outlet_model.dart';
import 'package:woosh/controllers/cart_controller.dart';

import '../../components/menu_tile.dart';
import '../order/addorder_page.dart';
import '../journeyplan/journeyplans_page.dart';
import '../notice/noticeboard_page.dart';
import '../profile/targets/targets_page.dart';
import 'package:woosh/controllers/auth/auth_controller.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late String salesRepName;
  late String salesRepPhone;
  int _pendingJourneyPlans = 0;
  int _pendingTasks = 0;
  int _unreadNotices = 0;
  bool _isLoading = true;
  bool _isSessionActive = false;
  final CartController _cartController = Get.put(CartController());

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadAllDataInParallel();
  }

  void _loadUserData() {
    final box = GetStorage();
    final salesRep = box.read('salesRep');

    setState(() {
      if (salesRep != null && salesRep is Map<String, dynamic>) {
        salesRepName = salesRep['name'] ?? 'User';
        salesRepPhone = salesRep['phoneNumber'] ?? 'No phone number';
      } else {
        salesRepName = 'User';
        salesRepPhone = 'No phone number';
      }
    });
  }

  Future<void> _loadPendingJourneyPlans() async {
    try {
      final journeyPlans = await JourneyPlanService.getJourneyPlans();

      // Get today's date in local time
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      if (mounted) {
        setState(() {
          _pendingJourneyPlans = journeyPlans.where((plan) {
            // Convert plan date from UTC to local time
            final localDate = plan.date.toLocal();
            // Check if plan is pending (status = 0) AND is for today
            return plan.status == JourneyPlan.statusPending &&
                localDate.year == today.year &&
                localDate.month == today.month &&
                localDate.day == today.day;
          }).length;
        });
      }

      print('📋 Loaded $_pendingJourneyPlans pending journey plans for today');
    } catch (e) {
      print('Error loading pending journey plans: $e');
      if (mounted) {
        setState(() {
          _pendingJourneyPlans = 0;
        });
      }
    }
  }

  Future<void> _loadPendingTasks() async {
    try {
      final tasks = await TaskService.getTasks();
      if (mounted) {
        setState(() {
          _pendingTasks = tasks.length;
        });
      }
    } catch (e) {
      print('Error loading pending tasks: $e');
    }
  }

  Future<void> _loadUnreadNotices() async {
    try {
      // Get count of recent notices (last 30 days)
      final recentNotices = await NoticeService.getRecentNoticesCount(30);

      if (mounted) {
        setState(() {
          _unreadNotices = recentNotices;
        });
      }

      print('📢 Loaded $_unreadNotices recent notices');
    } catch (e) {
      print('Error loading unread notices: $e');
      if (mounted) {
        setState(() {
          _unreadNotices = 0;
        });
      }
    }
  }

  Future<void> _loadAllDataInParallel() async {
    try {
      // Load all data in parallel for better performance
      final results = await Future.wait([
        _loadPendingJourneyPlans(),
        _loadPendingTasks(),
        _loadUnreadNotices(),
        _checkSessionStatus(),
      ]);

      // Single setState call to update all data at once
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading data in parallel: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _checkSessionStatus() async {
    try {
      final box = GetStorage();
      final userId = box.read<String>('userId');

      if (userId != null) {
        final currentSession =
            await SessionService.getCurrentSession(int.parse(userId));
        if (mounted) {
          setState(() {
            _isSessionActive = currentSession?.isActive ?? false;
          });
        }
      }
    } catch (e) {
      print('Error checking session status: $e');
      // Don't change session state on database errors - keep current state
      // This prevents false "session expired" messages
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
        print('✅ Cleared ${keysToRemove.length} cache keys');
      } catch (e) {
        print('❌ Error clearing cache: $e');
      }
    });
  }

  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Clear cart data
      await _cartController.clear();

      // Clear GetStorage cache in background
      _clearCacheInBackground();

      // Clear Hive caches if services are available
      try {
        final productHiveService = Get.find<ProductHiveService>();
        await productHiveService.clearAllProducts();
        print('?? Cleared product Hive cache');
      } catch (e) {
        print('?? Could not clear product Hive cache: $e');
      }

      try {
        final cartHiveService = Get.find<CartHiveService>();
        await cartHiveService.clearCart();
        print('?? Cleared cart Hive cache');
      } catch (e) {
        print('?? Could not clear cart Hive cache: $e');
      }

      // Clear session cache
      SessionService.clearCache();
      print('?? Cleared session cache');

      print('?? Cache cleared successfully');

      // Reload all data
      await Future.wait([
        _loadPendingJourneyPlans(),
        _loadPendingTasks(),
        _loadUnreadNotices(),
        _checkSessionStatus(),
      ]);
      _loadUserData();

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('? Dashboard refreshed and all caches cleared'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('? Error during refresh: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('?? Refresh completed with some errors: $e'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSessionInactiveDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.play_circle, color: Colors.blue),
            SizedBox(width: 8),
            Text('Start Work Session'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You need to start a work session to access Journey Plans.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'Work sessions are manual and never expire automatically.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              // Navigate to profile page
              Get.to(
                () => ProfilePage(),
                preventDuplicates: true,
                transition: Transition.rightToLeft,
              )?.then((_) => _checkSessionStatus());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Start Session'),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    try {
      // Show confirmation dialog
      final shouldLogout = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: GradientText('Logout',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Cancel'),
            ),
            GoldGradientButton(
              onPressed: () => Get.back(result: true),
              child: const Text('Logout'),
            ),
          ],
        ),
      );

      if (shouldLogout != true) return;

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: GradientCircularProgressIndicator(),
        ),
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
      final authController = Get.find<AuthController>();
      await authController.logout();

      // Close loading indicator
      if (!mounted) return;
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
      print('Error during logout: $e');
      if (!mounted) return;

      // Close loading indicator if it's showing
      if (Navigator.canPop(context)) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBackground,
      appBar: GradientAppBar(
        title: 'WOOSH',
        actions: [
          Obx(() {
            final cartItems = _cartController.totalItems;
            return Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart),
                  tooltip: 'Cart',
                  onPressed: () {
                    Get.to(
                      () => const ViewOrdersPage(),
                      preventDuplicates: true,
                      transition: Transition.rightToLeft,
                    );
                  },
                ),
                if (cartItems > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '$cartItems',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            );
          }),
          IconButton(
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.refresh),
            tooltip: 'Refresh & Clear Cache',
            onPressed: _isLoading
                ? null
                : () {
                    // Show immediate feedback
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            '?? Refreshing dashboard and clearing cache...'),
                        duration: Duration(seconds: 1),
                        backgroundColor: Colors.blue,
                      ),
                    );

                    // Start the refresh process
                    _refreshData();
                  },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'logout') {
                _logout();
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Menu section title
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 1.0,
                  mainAxisSpacing: 1.0,
                  children: [
                    // User Profile Tile with Session Status
                    MenuTile(
                      title: 'Merchandiser',
                      subtitle:
                          '$salesRepName\n$salesRepPhone\n${_isSessionActive ? '🟢 Session Active' : '🔴 Session Inactive'}',
                      icon: Icons.person,
                      onTap: () {
                        Get.to(
                          () => ProfilePage(),
                          preventDuplicates: true,
                          transition: Transition.rightToLeft,
                        )?.then((_) => _checkSessionStatus());
                      },
                    ),
                    // Journey Plans with session restriction
                    MenuTile(
                      title: 'Journey Plans',
                      icon: Icons.map,
                      badgeCount: _isLoading ? null : _pendingJourneyPlans,
                      onTap: _isSessionActive
                          ? () =>
                              Get.to(() => const JourneyPlansLoadingScreen())
                          : () => _showSessionInactiveDialog(),
                    ),
                    MenuTile(
                      title: 'View Client',
                      icon: Icons.storefront_outlined,
                      onTap: () {
                        Get.to(
                          () => const ViewClientPage(),
                          preventDuplicates: true,
                          transition: Transition.rightToLeft,
                        );
                      },
                    ),
                    // Notice Board (always active)
                    MenuTile(
                      title: 'Notice Board',
                      icon: Icons.notifications,
                      badgeCount: _unreadNotices > 0 ? _unreadNotices : null,
                      onTap: () {
                        Get.to(
                          () => const NoticeBoardPage(),
                          preventDuplicates: true,
                          transition: Transition.rightToLeft,
                        )?.then((_) => _loadUnreadNotices());
                      },
                    ),
                    MenuTile(
                      title: 'Add/Edit Order',
                      icon: Icons.edit,
                      onTap: () {
                        Get.to(
                          () => const ViewClientPage(forOrderCreation: true),
                          preventDuplicates: true,
                          transition: Transition.rightToLeft,
                        );
                      },
                    ),
                    MenuTile(
                      title: 'View Orders',
                      icon: Icons.shopping_cart,
                      onTap: () {
                        Get.to(
                          () => const ViewOrdersPage(),
                          preventDuplicates: true,
                          transition: Transition.rightToLeft,
                        );
                      },
                    ),
                    // Tasks (always active)
                    MenuTile(
                      title: 'Tasks/Warnings',
                      icon: Icons.task,
                      badgeCount: _pendingTasks,
                      onTap: () {
                        Get.to(
                          () => const TaskPage(),
                          preventDuplicates: true,
                          transition: Transition.rightToLeft,
                        )?.then((_) => _loadPendingTasks());
                      },
                    ),
                    // Leave (always active)
                    MenuTile(
                      title: 'Leave',
                      icon: Icons.event_busy,
                      onTap: () {
                        Get.to(
                          () => const LeaveDashboardPage(),
                          preventDuplicates: true,
                          transition: Transition.rightToLeft,
                        );
                      },
                    ),
                    MenuTile(
                      title: 'Uplift Sale',
                      icon: Icons.shopping_cart,
                      onTap: () {
                        Get.to(
                          () => const ViewClientPage(forUpliftSale: true),
                          preventDuplicates: true,
                          transition: Transition.rightToLeft,
                        )?.then((selectedOutlet) {
                          if (selectedOutlet != null &&
                              selectedOutlet is Outlet) {
                            Get.off(
                              () => UpliftSaleCartPage(
                                outlet: selectedOutlet,
                              ),
                              transition: Transition.rightToLeft,
                            );
                          }
                        });
                      },
                    ),
                    MenuTile(
                      title: 'Uplift Sales History',
                      icon: Icons.history,
                      onTap: () {
                        Get.toNamed('/uplift-sales');
                      },
                    ),
                    MenuTile(
                      title: 'Product Return',
                      icon: Icons.assignment_return,
                      onTap: () {
                        Get.to(
                          () => const ViewClientPage(forProductReturn: true),
                          preventDuplicates: true,
                          transition: Transition.rightToLeft,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
