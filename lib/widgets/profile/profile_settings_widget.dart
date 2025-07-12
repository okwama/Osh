import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:woosh/controllers/profilecontroller/profile_controller.dart';
import 'package:woosh/pages/profile/deleteaccount.dart';
// Remove direct service import - use controller instead
import 'package:woosh/utils/app_theme.dart';
import 'package:woosh/utils/error_handler.dart';
import 'package:woosh/widgets/gradient_widgets.dart';

/// Widget for displaying profile settings and session management
class ProfileSettingsWidget extends StatefulWidget {
  final ProfileController controller;

  const ProfileSettingsWidget({
    super.key,
    required this.controller,
  });

  @override
  State<ProfileSettingsWidget> createState() => _ProfileSettingsWidgetState();
}

class _ProfileSettingsWidgetState extends State<ProfileSettingsWidget> {
  bool isSessionActive = false;
  bool isProcessing = false;
  bool isCheckingSessionState = false;

  @override
  void initState() {
    super.initState();
    _checkSessionStatus();
  }

  Future<void> _checkSessionStatus() async {
    if (isCheckingSessionState) return;

    setState(() => isCheckingSessionState = true);
    final box = GetStorage();
    final userId = box.read<String>('userId');

    if (userId != null) {
      try {
        final currentSession =
            await widget.controller.getCurrentSession(int.parse(userId));

        setState(() {
          isSessionActive = currentSession?.isActive ?? false;
        });
        print(
            '✅ Session status updated: ${isSessionActive ? 'Active' : 'Inactive'} (Status: ${currentSession?.status ?? 'None'})');
      } catch (e) {
        setState(() {
          isSessionActive = false;
        });
        ErrorHandler.handleSilentError(e,
            context: 'ProfileSettingsWidget._checkSessionStatus');
      }
    } else {
      setState(() {
        isSessionActive = false;
      });
    }
    setState(() => isCheckingSessionState = false);
  }

  Future<void> _toggleSession() async {
    if (isProcessing) return;

    // Show confirmation dialog
    final shouldProceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: GradientText(
          isSessionActive ? 'End Session' : 'Start Session',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          isSessionActive
              ? 'Are you sure you want to end your current session?'
              : 'Are you sure you want to start a new session?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          GoldGradientButton(
            onPressed: () => Get.back(result: true),
            child: Text(isSessionActive ? 'End Session' : 'Start Session'),
          ),
        ],
      ),
    );

    if (shouldProceed != true) {
      return;
    }

    setState(() => isProcessing = true);

    try {
      final box = GetStorage();
      final userId = box.read<String>('userId');

      if (userId == null) {
        throw Exception('User ID not found');
      }

      if (isSessionActive) {
        // End session
        final currentSession =
            await widget.controller.getCurrentSession(int.parse(userId));
        if (currentSession != null) {
          await widget.controller.endSession(currentSession.id);
          setState(() {
            isSessionActive = false;
          });
          Get.snackbar(
            'Session Ended',
            'Your session has been ended successfully.',
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
        }
      } else {
        // Start session
        final result = await widget.controller.startSession(int.parse(userId));
        if (result['success']) {
          setState(() {
            isSessionActive = true;
          });
          Get.snackbar(
            'Session Started',
            'Your session has been started successfully.',
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
        } else {
          // Handle specific error for early session restriction
          if (result['error'] == 'EARLY_SESSION_RESTRICTED') {
            await showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      color: Colors.orange,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Session Restricted',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result['message'],
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.orange.shade700,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Your shift starts at 9:00 AM. Please wait until then to begin your work session.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.orange.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: const Text(
                      'OK',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          } else {
            throw Exception(result['message']);
          }
        }
      }
    } catch (e) {
      ErrorHandler.handleSessionError(e,
          context: 'ProfileSettingsWidget._toggleSession');
    } finally {
      setState(() => isProcessing = false);
    }
  }

  Future<void> _clearAppCache() async {
    final shouldProceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: GradientText(
          'Clear App Cache',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'This will clear all cached data including images, offline data, and temporary files. Are you sure you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          GoldGradientButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Clear Cache'),
          ),
        ],
      ),
    );

    if (shouldProceed != true) return;

    try {
      // Clear image cache
      ImageCache().clear();
      ImageCache().clearLiveImages();

      // Clear session cache - handled by controller
      // SessionService.clearCache();

      // Clear profile cache
      widget.controller.clearProfileCache();

      // Clear GetStorage cache
      final box = GetStorage();
      final keys = box.getKeys();
      for (final key in keys) {
        if (key.startsWith('cache_') ||
            key.startsWith('outlets_') ||
            key.startsWith('products_') ||
            key.startsWith('routes_') ||
            key.startsWith('notices_') ||
            key.startsWith('clients_') ||
            key.startsWith('orders_')) {
          box.remove(key);
        }
      }

      ErrorHandler.showSuccessSnackbar('App cache cleared successfully');
    } catch (e) {
      ErrorHandler.handleGeneralError(e,
          context: 'ProfileSettingsWidget._clearAppCache',
          customMessage: 'Failed to clear cache. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildMenuCard(
          context,
          icon: Icons.settings,
          title: 'Settings',
          onTap: () => Get.to(() => const DeleteAccount()),
        ),
        const SizedBox(height: 8),
        _buildMenuCard(
          context,
          icon: Icons.cleaning_services,
          title: 'Clear App Cache',
          onTap: _clearAppCache,
          iconColor: Colors.orange,
          backgroundColor: Colors.orange.withOpacity(0.1),
        ),
        const SizedBox(height: 8),
        // Session Control Button
        _buildSessionCard(context),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    Color? backgroundColor,
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
                  color: backgroundColor ??
                      Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  icon,
                  color: iconColor ?? Theme.of(context).primaryColor,
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

  Widget _buildSessionCard(BuildContext context) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: isSessionActive
                ? [
                    Colors.red.shade50,
                    Colors.red.shade100,
                  ]
                : [
                    Colors.green.shade50,
                    Colors.green.shade100,
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color:
                isSessionActive ? Colors.red.shade200 : Colors.green.shade200,
            width: 1.5,
          ),
        ),
        child: InkWell(
          onTap: isProcessing || isCheckingSessionState ? null : _toggleSession,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isSessionActive
                        ? Colors.red.shade100
                        : Colors.green.shade100,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: (isSessionActive ? Colors.red : Colors.green)
                            .withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    isSessionActive ? Icons.stop_circle : Icons.play_circle,
                    color: isSessionActive
                        ? Colors.red.shade700
                        : Colors.green.shade700,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isSessionActive ? 'Active Session' : 'Start Session',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isSessionActive
                              ? Colors.red.shade700
                              : Colors.green.shade700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isSessionActive
                            ? 'Tap to end your current session'
                            : 'Tap to begin tracking your work session',
                        style: TextStyle(
                          fontSize: 11,
                          color: isSessionActive
                              ? Colors.red.shade600
                              : Colors.green.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isCheckingSessionState)
                  Container(
                    padding: const EdgeInsets.all(8),
                    child: const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                      ),
                    ),
                  )
                else if (isProcessing)
                  Container(
                    padding: const EdgeInsets.all(8),
                    child: const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSessionActive
                          ? Colors.red.shade100
                          : Colors.green.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: isSessionActive
                          ? Colors.red.shade600
                          : Colors.green.shade600,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
