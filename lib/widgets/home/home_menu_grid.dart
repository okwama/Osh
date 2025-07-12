import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:woosh/controllers/home_controller.dart';
import 'package:woosh/pages/Leave/leave_dashboard_page.dart';
import 'package:woosh/pages/client/viewclient_page.dart';
import 'package:woosh/pages/journeyplan/journeyplans_page.dart';
import 'package:woosh/pages/journeyplan/reports/pages/product_return_page.dart';
import 'package:woosh/pages/notice/noticeboard_page.dart';
import 'package:woosh/pages/order/viewOrder/vieworder_page.dart';
import 'package:woosh/pages/pos/upliftSaleCart_page.dart';
import 'package:woosh/pages/profile/profile.dart';
import 'package:woosh/pages/task/task.dart';
import 'package:woosh/models/client/client_model.dart';
import 'package:woosh/components/menu_tile.dart';

/// Menu grid widget for the home page
class HomeMenuGrid extends StatelessWidget {
  final HomeController controller;

  const HomeMenuGrid({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 1.0,
        mainAxisSpacing: 1.0,
        children: [
          // User Profile Tile with Session Status
          Obx(() => MenuTile(
                title: 'Merchandiser',
                subtitle: controller.userProfileSubtitle,
                icon: Icons.person,
                onTap: () {
                  Get.to(
                    () => ProfilePage(),
                    preventDuplicates: true,
                    transition: Transition.rightToLeft,
                  )?.then((_) => controller.checkSessionStatus());
                },
              )),

          // Journey Plans with session restriction
          Obx(() => MenuTile(
                title: 'Journey Plans',
                icon: Icons.map,
                badgeCount: controller.isLoading.value
                    ? null
                    : controller.pendingJourneyPlans.value,
                onTap: controller.canAccessJourneyPlans
                    ? () => Get.to(() => const JourneyPlansPage())
                    : () => _showSessionInactiveDialog(context),
              )),

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
          Obx(() => MenuTile(
                title: 'Notice Board',
                icon: Icons.notifications,
                badgeCount: controller.unreadNotices.value > 0
                    ? controller.unreadNotices.value
                    : null,
                onTap: () {
                  Get.to(
                    () => const NoticeBoardPage(),
                    preventDuplicates: true,
                    transition: Transition.rightToLeft,
                  )?.then((_) => controller.loadUnreadNotices());
                },
              )),

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
          Obx(() => MenuTile(
                title: 'Tasks/Warnings',
                icon: Icons.task,
                badgeCount: controller.pendingTasks.value,
                onTap: () {
                  Get.to(
                    () => const TaskPage(),
                    preventDuplicates: true,
                    transition: Transition.rightToLeft,
                  )?.then((_) => controller.loadPendingTasks());
                },
              )),

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
              )?.then((selectedClient) {
                if (selectedClient != null && selectedClient is Client) {
                  Get.off(
                    () => UpliftSaleCartPage(
                      outlet: selectedClient,
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
    );
  }

  void _showSessionInactiveDialog(BuildContext context) {
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
              )?.then((_) => controller.checkSessionStatus());
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
}
