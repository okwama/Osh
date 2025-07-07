import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:woosh/pages/profile/targets/dashboard_screen.dart';
import 'package:woosh/services/core/target_service.dart';
import 'package:woosh/widgets/cream_gradient_card.dart';

class TargetsMenuTile extends StatelessWidget {
  const TargetsMenuTile({super.key});

  @override
  Widget build(BuildContext context) {
    return CreamGradientCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.track_changes,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Targets & Performance',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                    ),
                    Text(
                      'Track your sales performance and targets',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20),

          // Menu Grid
          GridView.count(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2,
            children: [
              _buildMenuCard(
                context,
                title: 'Dashboard',
                subtitle: 'Overview',
                icon: Icons.dashboard,
                color: Colors.blue,
                onTap: () => _navigateToDashboard(context),
              ),
              _buildMenuCard(
                context,
                title: 'Visit Targets',
                subtitle: 'Daily Visits',
                icon: Icons.location_on,
                color: Colors.green,
                onTap: () => _navigateToVisits(context),
              ),
              _buildMenuCard(
                context,
                title: 'New Clients',
                subtitle: 'Acquisition',
                icon: Icons.person_add,
                color: Colors.orange,
                onTap: () => _navigateToNewClients(context),
              ),
              _buildMenuCard(
                context,
                title: 'Product Sales',
                subtitle: 'Vapes & Pouches',
                icon: Icons.inventory,
                color: Colors.purple,
                onTap: () => _navigateToProductSales(context),
              ),
              _buildMenuCard(
                context,
                title: 'All Targets',
                subtitle: 'Manage',
                icon: Icons.list_alt,
                color: Colors.teal,
                onTap: () => _navigateToAllTargets(context),
              ),
              _buildMenuCard(
                context,
                title: 'Settings',
                subtitle: 'Configure',
                icon: Icons.settings,
                color: Colors.grey,
                onTap: () => _navigateToSettings(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: color,
                size: 28,
              ),
            ),
            SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToDashboard(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DashboardScreen(),
      ),
    );
  }

  void _navigateToVisits(BuildContext context) {
    // Navigate to visits tab or show visits data
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Visit Targets'),
        content: Text('Visit targets functionality will be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _navigateToNewClients(BuildContext context) {
    // Navigate to new clients tab or show new clients data
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('New Clients'),
        content: Text('New clients functionality will be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _navigateToProductSales(BuildContext context) {
    // Navigate to product sales tab or show product sales data
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Product Sales'),
        content: Text('Product sales functionality will be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _navigateToAllTargets(BuildContext context) {
    // Navigate to all targets tab or show all targets data
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('All Targets'),
        content: Text('All targets functionality will be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _navigateToSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Targets Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading:
                  Icon(Icons.refresh, color: Theme.of(context).primaryColor),
              title: Text('Refresh Data'),
              subtitle: Text('Clear cache and reload'),
              onTap: () {
                Get.back();
                _showRefreshDialog(context);
              },
            ),
            ListTile(
              leading:
                  Icon(Icons.category, color: Theme.of(context).primaryColor),
              title: Text('Category Mapping'),
              subtitle: Text('View product classification'),
              onTap: () {
                Get.back();
                _showCategoryMapping(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showRefreshDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Refresh Data'),
        content: Text(
            'This will clear all cached data and reload from the server. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _refreshData(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
            child: Text('Refresh'),
          ),
        ],
      ),
    );
  }

  void _refreshData(BuildContext context) {
    TargetService.clearCache();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Cache cleared. Data will refresh on next load.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showCategoryMapping(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Product Category Mapping'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Vapes:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('Category IDs: 1, 3'),
            SizedBox(height: 8),
            Text('Pouches:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('Category IDs: 4, 5'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }
}

