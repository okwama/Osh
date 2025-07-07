import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:woosh/controllers/profile_controller.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:woosh/pages/profile/ChangePasswordPage.dart';
import 'package:woosh/pages/profile/deleteaccount.dart';
import 'package:woosh/pages/profile/targets/targets_page.dart';
import 'package:woosh/pages/profile/user_stats_page.dart';
import 'package:woosh/pages/profile/session_history_page.dart';
import 'package:woosh/services/core/session_service.dart';
import 'package:woosh/utils/app_theme.dart';
import 'package:woosh/widgets/gradient_app_bar.dart';
import 'package:woosh/widgets/gradient_widgets.dart';
import 'package:woosh/widgets/version_info_widget.dart';
import 'package:get_storage/get_storage.dart';
import 'dart:async';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with WidgetsBindingObserver {
  final ProfileController controller = Get.put(ProfileController());
  bool isSessionActive = false;
  bool isProcessing = false;
  bool isCheckingSessionState = false;

  Timer? _sessionTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeSession();
    // Remove automatic session checks - sessions are strictly manual
    // _sessionTimer = Timer.periodic(const Duration(minutes: 10), (timer) {
    //   if (mounted) {
    //     _checkSessionTimeout();
    //   }
    // });
  }

  Future<void> _initializeSession() async {
    // First fix any inconsistent sessions
    await SessionService.fixInconsistentSessions();
    // Then auto-end sessions if it's past 6:10 PM
    await SessionService.autoEndSessions();
    // Then check current session status
    await _checkSessionStatus();
  }

  Future<void> _checkSessionStatus() async {
    if (isCheckingSessionState) return;

    setState(() => isCheckingSessionState = true);
    final box = GetStorage();
    final userId = box.read<String>('userId');

    if (userId != null) {
      try {
        final currentSession =
            await SessionService.getCurrentSession(int.parse(userId));

        setState(() {
          isSessionActive = currentSession?.isActive ?? false;
        });
        print(
            '✅ Session status updated: ${isSessionActive ? 'Active' : 'Inactive'} (Status: ${currentSession?.status ?? 'None'})');
      } catch (e) {
        setState(() {
          isSessionActive = false;
        });
      }
    } else {
      setState(() {
        isSessionActive = false;
      });
    }
    setState(() => isCheckingSessionState = false);
  }

  Future<void> _checkSessionTimeout() async {
    if (!mounted) return;

    final box = GetStorage();
    final userId = box.read<String>('userId');
    if (userId == null) return;

    try {
      // Use refreshSession to bypass cache for timeout checks
      final currentSession =
          await SessionService.refreshSession(int.parse(userId));
      final isValid = currentSession?.isActive ?? false;

      // Only update UI state, don't show expired message for manual sessions
      if (mounted && isSessionActive != isValid) {
        setState(() {
          isSessionActive = isValid;
        });

        // Only show message if session was manually ended (not expired)
        if (!isValid && isSessionActive) {
          print(
              '📋 Work session ended for user: $userId (Status: ${currentSession?.status ?? 'None'})');
        }
      }
    } catch (e) {
      // Don't show error to user for background checks
      // Don't change session state on database errors
    }
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
            await SessionService.getCurrentSession(int.parse(userId));
        if (currentSession != null) {
          await SessionService.endSession(currentSession.id);
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
        final result = await SessionService.startSession(int.parse(userId));
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
      Get.snackbar(
        'Error',
        'Failed to ${isSessionActive ? 'end' : 'start'} session: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
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

      // Clear session cache
      SessionService.clearCache();

      // Clear profile cache
      controller.clearProfileCache();

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

      Get.snackbar(
        'Success',
        'App cache cleared successfully',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to clear cache: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didHaveMemoryPressure() {
    ImageCache().clear();
    ImageCache().clearLiveImages();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBackground,
      appBar: GradientAppBar(
        title: 'Profile',
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              controller.refreshProfile();
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Stack(
        children: [
          Obx(
            () => AnimationLimiter(
              child: SingleChildScrollView(
                child: Column(
                  children: AnimationConfiguration.toStaggeredList(
                    duration: const Duration(milliseconds: 375),
                    childAnimationBuilder: (widget) => SlideAnimation(
                      verticalOffset: 50.0,
                      child: FadeInAnimation(
                        child: widget,
                      ),
                    ),
                    children: [
                      const SizedBox(height: 16),
                      // Profile Image Section
                      _buildProfileImageSection(),
                      // Role Badge
                      const SizedBox(height: 8),
                      _buildRoleBadge(),
                      const SizedBox(height: 16),
                      // Profile Info Cards
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          children: [
                            _buildInfoCard(
                              context,
                              icon: Icons.person,
                              label: 'Name',
                              value: controller.userName.value,
                            ),
                            const SizedBox(height: 8),
                            _buildInfoCard(
                              context,
                              icon: Icons.email,
                              label: 'Email',
                              value: controller.userEmail.value,
                            ),
                            const SizedBox(height: 8),
                            _buildInfoCard(
                              context,
                              icon: Icons.phone,
                              label: 'Phone',
                              value: controller.userPhone.value,
                            ),
                            const SizedBox(height: 16),
                            _buildActionButtons(),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileImageSection() {
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
            child: controller.photoUrl.value.isNotEmpty
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
                  ),
          ),
        ),
        if (controller.isLoading.value)
          const Positioned.fill(
            child: CircularProgressIndicator(),
          ),
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
    final String role =
        controller.userRole.value.isEmpty ? 'User' : controller.userRole.value;

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
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value.isEmpty ? 'Not provided' : value,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
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

  Widget _buildActionButtons() {
    return Column(
      children: [
        Card(
          elevation: 1,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          child: InkWell(
            onTap: () {
              Get.to(() => const UserStatsPage());
            },
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
                      Icons.analytics,
                      color: Theme.of(context).primaryColor,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'View My Statistics',
                      style: TextStyle(
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
        ),
        const SizedBox(height: 8),
        Card(
          elevation: 1,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          child: InkWell(
            onTap: () {
              Get.to(() => const SessionHistoryPage());
            },
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
                      Icons.history,
                      color: Theme.of(context).primaryColor,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'View Session History',
                      style: TextStyle(
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
        ),
        const SizedBox(height: 8),
        Card(
          elevation: 1,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          child: InkWell(
            onTap: () {
              Get.to(() => const ChangePasswordPage());
            },
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
                      Icons.lock_outline,
                      color: Theme.of(context).primaryColor,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Change Password',
                      style: TextStyle(
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
        ),
        const SizedBox(height: 8),
        Card(
          elevation: 1,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          child: InkWell(
            onTap: () {
              Get.to(() => const TargetsPage());
            },
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
                      Icons.track_changes,
                      color: Theme.of(context).primaryColor,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'View Targets',
                      style: TextStyle(
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
        ),
        const SizedBox(height: 8),

        Card(
          elevation: 1,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          child: InkWell(
            onTap: () {
              Get.to(() => const DeleteAccount());
            },
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
                      Icons.settings,
                      color: Theme.of(context).primaryColor,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Settings',
                      style: TextStyle(
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
        ),
        const SizedBox(height: 8),
        Card(
          elevation: 1,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          child: InkWell(
            onTap: _clearAppCache,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.cleaning_services,
                      color: Colors.orange,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Clear App Cache',
                      style: TextStyle(
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
        ),
        const SizedBox(height: 8),
        // Session Control Button
        Card(
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
                color: isSessionActive
                    ? Colors.red.shade200
                    : Colors.green.shade200,
                width: 1.5,
              ),
            ),
            child: InkWell(
              onTap: isProcessing || isCheckingSessionState
                  ? null
                  : _toggleSession,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                            isSessionActive
                                ? 'Active Session'
                                : 'Start Session',
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
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.grey),
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
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.grey),
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
        ),
        const SizedBox(height: 16), // Add extra padding at the bottom
      ],
    );
  }
}
