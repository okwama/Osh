import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:woosh/models/journeyplan/journeyplan_model.dart';
import 'package:woosh/widgets/journey_plan/journey_status_card.dart';
import 'package:woosh/widgets/journey_plan/journey_details_card.dart';
import 'package:woosh/widgets/journey_plan/journey_notes_section.dart';
import 'package:woosh/controllers/journeycontroller/journey_checkin_controller.dart';
import 'package:woosh/widgets/gradient_app_bar.dart';
import 'package:woosh/utils/app_theme.dart';
import 'package:get/get.dart';

class JourneyViewModular extends StatefulWidget {
  final JourneyPlan journeyPlan;
  final Function(JourneyPlan)? onCheckInSuccess;

  const JourneyViewModular({
    super.key,
    required this.journeyPlan,
    this.onCheckInSuccess,
  });

  @override
  State<JourneyViewModular> createState() => _JourneyViewModularState();
}

class _JourneyViewModularState extends State<JourneyViewModular> {
  late JourneyCheckinController _checkinController;
  bool _isEditingNotes = false;
  bool _isSavingNotes = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    // Initialize controllers
    // _locationController = Get.put(JourneyLocationController());
    _checkinController = Get.put(JourneyCheckinController());

    // Initialize location based on journey status
    if (widget.journeyPlan.isCheckedIn || widget.journeyPlan.isInTransit) {
      // Use check-in location from journey plan
      print('📍 Using check-in location from journey plan');
    } else {
      // Get current position for pending journeys
      print('📍 Getting current position for pending journey');
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  // Action handlers
  void _onRefresh() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Refreshing...'),
        duration: Duration(seconds: 1),
      ),
    );

    if (widget.journeyPlan.isPending) {
      // Refresh location data
      print('🔄 Refreshing location data');
    }
  }

  void _onCheckIn() {
    // Perform check-in using controller
    print('🔍 Performing check-in for journey plan: ${widget.journeyPlan.id}');
    // TODO: Implement check-in logic using controller
  }

  void _onUpdateLocation() {
    // This would be implemented if client location update is needed
    Get.snackbar(
      'Info',
      'Client location update is not yet implemented for this journey.',
      backgroundColor: Colors.blue,
      colorText: Colors.white,
    );
  }

  void _onNotesChanged(String notes) {
    // Handle notes changes
    print('📝 Notes changed: $notes');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBackground,
      appBar: GradientAppBar(
        title: 'Journey Check-In',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _onRefresh,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            // Status Card
            JourneyStatusCard(journeyPlan: widget.journeyPlan),

            // Journey Details Card
            JourneyDetailsCard(
              journeyPlan: widget.journeyPlan,
              currentAddress: 'Location data will be loaded',
              isFetchingLocation: false,
              isWithinGeofence: false,
              distanceToClient: 0.0,
              onUpdateLocation: _onUpdateLocation,
              showUpdateLocation: widget.journeyPlan.showUpdateLocation,
            ),

            // Notes Section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: JourneyNotesSection(
                  initialNotes: widget.journeyPlan.notes,
                  onNotesChanged: _onNotesChanged,
                  isEditing: _isEditingNotes,
                  isSaving: _isSavingNotes,
                ),
              ),
            ),

            // Check-in Button
            if (widget.journeyPlan.isPending)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _onCheckIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Check In',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
