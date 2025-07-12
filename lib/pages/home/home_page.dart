import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:woosh/pages/Leave/leaveapplication_page.dart';
import 'package:woosh/pages/Leave/leave_dashboard_page.dart';
import 'package:woosh/pages/client/viewclient_page.dart';
import 'package:woosh/pages/journeyplan/reports/pages/product_return_page.dart';
import 'package:woosh/pages/login/login_page.dart';
import 'package:woosh/pages/order/viewOrder/vieworder_page.dart';
import 'package:woosh/pages/pos/upliftSaleCart_page.dart';
import 'package:woosh/pages/task/task.dart';
import 'package:woosh/pages/profile/profile.dart';
import 'package:woosh/utils/app_theme.dart';
import 'package:woosh/utils/error_handler.dart';
import 'package:woosh/widgets/gradient_app_bar.dart';
import 'package:woosh/widgets/gradient_widgets.dart';
import 'package:woosh/controllers/cartcontroller/cart_controller.dart';
import 'package:woosh/controllers/homecontroller/home_controller.dart';

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
  final HomeController homeController = Get.put(HomeController());
  final CartController _cartController = Get.put(CartController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(
        title: 'Dashboard',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => homeController.refreshData(),
            tooltip: 'Refresh Dashboard',
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Get.to(() => const ProfilePage()),
            tooltip: 'Profile',
          ),
        ],
      ),
      body: Obx(() {
        if (homeController.isDataLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: () => homeController.refreshData(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildUserProfileSection(),
                const SizedBox(height: 24),
                _buildQuickStatsSection(),
                const SizedBox(height: 24),
                _buildMenuGrid(),
                const SizedBox(height: 24),
                _buildSessionStatusCard(),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildUserProfileSection() {
    final userData = homeController.getUserData();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [Colors.blue.shade50, Colors.blue.shade100],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person,
                color: Colors.blue.shade700,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                    userData['name'] ?? 'User',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
            Text(
                    userData['phone'] ?? 'No phone number',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStatsSection() {
    final stats = homeController.getDashboardStats();

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Pending Journey Plans',
            stats['pendingJourneyPlans']?.toString() ?? '0',
            Icons.route,
            Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Pending Tasks',
            stats['pendingTasks']?.toString() ?? '0',
            Icons.task,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Unread Notices',
            stats['unreadNotices']?.toString() ?? '0',
            Icons.notifications,
            Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.2,
              children: [
        _buildMenuTile(
          'Journey Plans',
          Icons.route,
          Colors.blue,
          () => Get.to(() => const JourneyPlansPage()),
          enabled: homeController.hasActiveSession,
        ),
        _buildMenuTile(
          'Clients',
          Icons.people,
          Colors.green,
          () => Get.to(() => const ViewClientPage()),
        ),
        _buildMenuTile(
          'Tasks',
          Icons.task,
          Colors.purple,
          () => Get.to(() => const TaskPage()),
        ),
        _buildMenuTile(
          'Notices',
          Icons.notifications,
          Colors.red,
          () => Get.to(() => const NoticeBoardPage()),
        ),
        _buildMenuTile(
          'Leave',
          Icons.event_note,
          Colors.teal,
          () => Get.to(() => const LeaveDashboardPage()),
        ),
        _buildMenuTile(
          'Targets',
          Icons.track_changes,
          Colors.indigo,
          () => Get.to(() => const TargetsPage()),
                  ),
              ],
            );
  }

  Widget _buildMenuTile(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap, {
    bool enabled = true,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: enabled
                  ? [color.withOpacity(0.1), color.withOpacity(0.2)]
                  : [
                      Colors.grey.withOpacity(0.1),
                      Colors.grey.withOpacity(0.2)
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
                  children: [
              Icon(
                icon,
                color: enabled ? color : Colors.grey,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: enabled ? color : Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSessionStatusCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: homeController.hasActiveSession
                ? [Colors.green.shade50, Colors.green.shade100]
                : [Colors.red.shade50, Colors.red.shade100],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              homeController.hasActiveSession
                  ? Icons.play_circle
                  : Icons.stop_circle,
              color:
                  homeController.hasActiveSession ? Colors.green : Colors.red,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  Text(
                    homeController.hasActiveSession
                        ? 'Session Active'
                        : 'Session Inactive',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: homeController.hasActiveSession
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                    ),
                  ),
                  Text(
                    homeController.hasActiveSession
                        ? 'You can access all features'
                        : 'Start your session to access journey plans',
                    style: TextStyle(
                      fontSize: 12,
                      color: homeController.hasActiveSession
                          ? Colors.green.shade600
                          : Colors.red.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
