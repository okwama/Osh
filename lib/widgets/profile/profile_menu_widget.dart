import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:woosh/pages/profile/ChangePasswordPage.dart';
import 'package:woosh/pages/profile/deleteaccount.dart';
import 'package:woosh/pages/profile/targets/targets_page.dart';
import 'package:woosh/pages/profile/user_stats_page.dart';
import 'package:woosh/pages/profile/session_history_page.dart';

/// Widget for displaying profile menu options
class ProfileMenuWidget extends StatelessWidget {
  const ProfileMenuWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildMenuCard(
          context,
          icon: Icons.analytics,
          title: 'View My Statistics',
          onTap: () => Get.to(() => const UserStatsPage()),
        ),
        const SizedBox(height: 8),
        _buildMenuCard(
          context,
          icon: Icons.history,
          title: 'View Session History',
          onTap: () => Get.to(() => const SessionHistoryPage()),
        ),
        const SizedBox(height: 8),
        _buildMenuCard(
          context,
          icon: Icons.lock_outline,
          title: 'Change Password',
          onTap: () => Get.to(() => const ChangePasswordPage()),
        ),
        const SizedBox(height: 8),
        _buildMenuCard(
          context,
          icon: Icons.track_changes,
          title: 'View Targets',
          onTap: () => Get.to(() => const TargetsPage()),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  icon,
                  color: Theme.of(context).primaryColor,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: Colors.grey.shade600,
              )
            ],
          ),
        ),
      ),
    );
  }
}
