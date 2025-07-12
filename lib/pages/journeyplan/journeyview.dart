import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:woosh/models/journeyplan/journeyplan_model.dart';
import 'package:intl/intl.dart';
import 'package:woosh/pages/journeyplan/reports/reportMain_page.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
// ignore: unnecessary_import
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:math';
import 'package:woosh/utils/app_theme.dart';
import 'package:woosh/widgets/gradient_app_bar.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:get/get.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:woosh/services/core/journeyplan/journey_plan_service.dart';
import 'package:woosh/utils/safe_error_handler.dart';
import 'package:woosh/services/core/upload_service.dart';
import 'package:woosh/controllers/journey_view_controller.dart';
import 'package:woosh/widgets/journey_view/journey_status_card.dart';
import 'package:woosh/widgets/journey_view/journey_details_card.dart';
import 'package:woosh/widgets/journey_view/edit_notes_dialog.dart';

class JourneyView extends StatelessWidget {
  final JourneyPlan journeyPlan;
  final Function(JourneyPlan)? onCheckInSuccess;

  const JourneyView({
    super.key,
    required this.journeyPlan,
    this.onCheckInSuccess,
  });

  @override
  Widget build(BuildContext context) {
    // Initialize controller
    final controller = Get.put(JourneyViewController());
    controller.onCheckInSuccess = onCheckInSuccess;
    controller.initialize(journeyPlan);

    return Scaffold(
      backgroundColor: appBackground,
      appBar: GradientAppBar(
        title: 'Journey Check-In',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: controller.refreshLocation,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            // Status Card
            Obx(() => controller.journeyPlan != null
                ? JourneyStatusCard(journeyPlan: controller.journeyPlan!)
                : const SizedBox.shrink()),

            // Journey Details Card
            Obx(() => controller.journeyPlan != null
                ? JourneyDetailsCard(
                    journeyPlan: controller.journeyPlan!,
                    currentAddress: controller.currentAddress,
                    isFetchingLocation: controller.isFetchingLocation,
                    isWithinGeofence: controller.isWithinGeofence,
                    distanceToClient: controller.distanceToClient,
                    onUpdateLocation: controller.updateClientLocation,
                    onEditNotes: () => _showEditNotesDialog(controller),
                    onCheckIn:
                        controller.isCheckingIn ? null : controller.checkIn,
                    onViewReports: controller.navigateToReports,
                  )
                : const SizedBox.shrink()),
          ],
        ),
      ),
    );
  }

  void _showEditNotesDialog(JourneyViewController controller) {
    EditNotesDialog.show(
      initialNotes: controller.journeyPlan?.notes,
      onSave: controller.saveNotes,
    );
  }
}
