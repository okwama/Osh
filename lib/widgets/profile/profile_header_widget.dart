import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:woosh/controllers/profilecontroller/profile_controller.dart';

/// Widget for displaying user profile header with image and role badge
class ProfileHeaderWidget extends StatelessWidget {
  final ProfileController controller;

  const ProfileHeaderWidget({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 16),
        // Profile Image Section
        _buildProfileImageSection(context),
        // Role Badge
        const SizedBox(height: 8),
        _buildRoleBadge(),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildProfileImageSection(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Theme.of(context).primaryColor,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipOval(
            child: Obx(() => controller.photoUrl.value.isNotEmpty
                ? Image.network(
                    controller.photoUrl.value,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.person, size: 50, color: Colors.grey),
                  )
                : Container(
                    color: Colors.grey.shade200,
                    child:
                        const Icon(Icons.person, size: 50, color: Colors.grey),
                  )),
          ),
        ),
        Obx(() => controller.isLoading.value
            ? const Positioned.fill(
                child: CircularProgressIndicator(),
              )
            : const SizedBox.shrink()),
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
              onPressed: controller.pickImage,
              constraints: const BoxConstraints.tightFor(width: 32, height: 32),
              padding: EdgeInsets.zero,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRoleBadge() {
    return Obx(() {
      final String role = controller.userRole.value.isEmpty
          ? 'User'
          : controller.userRole.value;

      final Color badgeColor =
          role.toLowerCase() == 'supervisor' || role.toLowerCase() == 'admin'
              ? Colors.red.shade700
              : role.toLowerCase() == 'manager'
                  ? Colors.blue.shade700
                  : Colors.green.shade700;

      final IconData roleIcon =
          role.toLowerCase() == 'supervisor' || role.toLowerCase() == 'admin'
              ? Icons.supervised_user_circle
              : role.toLowerCase() == 'manager'
                  ? Icons.manage_accounts
                  : Icons.security;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: badgeColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: badgeColor.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(roleIcon, size: 14, color: Colors.white),
            const SizedBox(width: 4),
            Text(
              role.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ],
        ),
      );
    });
  }
}
