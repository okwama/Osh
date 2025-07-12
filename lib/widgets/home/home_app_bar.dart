import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:woosh/controllers/home_controller.dart';
import 'package:woosh/pages/order/viewOrder/vieworder_page.dart';
import 'package:woosh/widgets/gradient_app_bar.dart';

/// App bar widget for the home page
class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final HomeController controller;

  const HomeAppBar({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return GradientAppBar(
      title: 'WOOSH',
      actions: [
        // Cart icon with badge
        Obx(() {
          final cartItems = controller.cartItemsCount;
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

        // Refresh button
        Obx(() => IconButton(
              icon: controller.isRefreshing.value
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
              onPressed: controller.isRefreshing.value
                  ? null
                  : () {
                      // Show immediate feedback
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              '🔄 Refreshing dashboard and clearing cache...'),
                          duration: Duration(seconds: 1),
                          backgroundColor: Colors.blue,
                        ),
                      );

                      // Start the refresh process
                      controller.refreshData();
                    },
            )),

        // More options menu
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            if (value == 'logout') {
              controller.logout();
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
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
