import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:woosh/controllers/profilecontroller/profile_controller.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:woosh/services/core/session_service.dart';
import 'package:woosh/utils/app_theme.dart';
import 'package:woosh/widgets/gradient_app_bar.dart';
import 'package:woosh/widgets/version_info_widget.dart';
import 'package:woosh/widgets/profile/profile_header_widget.dart';
import 'package:woosh/widgets/profile/profile_stats_widget.dart';
import 'package:woosh/widgets/profile/profile_menu_widget.dart';
import 'package:woosh/widgets/profile/profile_settings_widget.dart';
import 'package:woosh/pages/profile/ChangePasswordPage.dart';
import 'package:woosh/pages/profile/deleteaccount.dart';
import 'package:woosh/pages/profile/targets/targets_page.dart';
import 'package:woosh/pages/profile/user_stats_page.dart';
import 'package:woosh/pages/profile/session_history_page.dart';
import 'package:get_storage/get_storage.dart';
import 'dart:async';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with WidgetsBindingObserver {
  final ProfileController controller = Get.put(ProfileController());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeSession();
  }

  Future<void> _initializeSession() async {
    // First fix any inconsistent sessions
    await SessionService.fixInconsistentSessions();
    // Then auto-end sessions if it's past 6:10 PM
    await SessionService.autoEndSessions();
  }

  @override
  void dispose() {
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
                      // Profile Header
                      ProfileHeaderWidget(controller: controller),
                      // Profile Stats
                      ProfileStatsWidget(controller: controller),
                      // Profile Menu
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: ProfileMenuWidget(),
                      ),
                      // Profile Settings
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: ProfileSettingsWidget(controller: controller),
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


}
