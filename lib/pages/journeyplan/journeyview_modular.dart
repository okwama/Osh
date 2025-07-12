import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:woosh/models/journeyplan/journeyplan_model.dart';
import 'package:woosh/widgets/journey_plan/journey_status_card.dart';
import 'package:woosh/widgets/journey_plan/journey_details_card.dart';
import 'package:woosh/widgets/journey_plan/journey_notes_section.dart';
import 'package:woosh/services/core/journeyplan/journey_location_service.dart';
import 'package:woosh/services/core/journeyplan/journey_checkin_service.dart';
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
  late JourneyLocationService _locationService;
  late JourneyCheckInService _checkInService;
  bool _isEditingNotes = false;
  bool _isSavingNotes = false;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  void _initializeServices() {
    // Initialize location service
    _locationService = JourneyLocationService();
    _locationService.onPositionChanged = _onPositionChanged;
    _locationService.onAddressChanged = _onAddressChanged;
    _locationService.onGeofenceChanged = _onGeofenceChanged;
    _locationService.onDistanceChanged = _onDistanceChanged;

    // Initialize check-in service
    _checkInService = JourneyCheckInService();
    _checkInService.onCheckInStateChanged = _onCheckInStateChanged;
    _checkInService.onCheckInSuccess = _onCheckInSuccess;
    _checkInService.onCheckInError = _onCheckInError;
    _checkInService.onAllReportsSubmitted = _onAllReportsSubmitted;

    // Initialize location based on journey status
    if (widget.journeyPlan.isCheckedIn || widget.journeyPlan.isInTransit) {
      _locationService.useCheckInLocation(widget.journeyPlan);
    } else {
      _locationService.getCurrentPosition();
      if (widget.journeyPlan.isPending) {
        _locationService.startLocationUpdates();
      }
    }
  }

  @override
  void dispose() {
    _locationService.dispose();
    _checkInService.dispose();
    super.dispose();
  }

  // Location service callbacks
  void _onPositionChanged(Position? position) {
    if (mounted) {
      setState(() {});
    }
  }

  void _onAddressChanged(String? address) {
    if (mounted) {
      setState(() {});
    }
  }

  void _onGeofenceChanged(bool within) {
    if (mounted) {
      setState(() {});
    }
  }

  void _onDistanceChanged(double distance) {
    if (mounted) {
      setState(() {});
    }
  }

  // Check-in service callbacks
  void _onCheckInStateChanged(bool checkingIn) {
    if (mounted) {
      setState(() {});
    }
  }

  void _onCheckInSuccess(JourneyPlan journeyPlan) {
    widget.onCheckInSuccess?.call(journeyPlan);
  }

  void _onCheckInError(String error) {
    Get.snackbar(
      'Check-in Error',
      error,
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  }

  void _onAllReportsSubmitted() {
    // Handle when all reports are submitted
    print('✅ All reports submitted successfully');
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
      _locationService.getCurrentPosition();
    }
  }

  void _onCheckIn() {
    _checkInService.performCheckIn(
        widget.journeyPlan, _locationService.currentPosition);
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
              currentAddress: _locationService.currentAddress,
              isFetchingLocation: _locationService.isFetchingLocation,
              isWithinGeofence: _locationService.isWithinGeofence,
              distanceToClient: _locationService.distanceToClient,
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
                    onPressed: _checkInService.isCheckingIn ? null : _onCheckIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _checkInService.isCheckingIn
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              ),
                              SizedBox(width: 12),
                              Text('Checking in...'),
                            ],
                          )
                        : const Text(
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
