import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:woosh/models/journeyplan/journeyplan_model.dart';
import 'package:woosh/services/core/journeyplan/journey_plan_service.dart';
import 'package:woosh/services/core/journeyplan/journey_checkin_service.dart';
import 'package:woosh/services/core/journeyplan/journey_location_service.dart';
import 'package:woosh/pages/journeyplan/reports/reportMain_page.dart';
import 'package:woosh/utils/optimistic_ui_handler.dart';

class JourneyViewController extends GetxController with WidgetsBindingObserver {
  // Reactive variables
  final _journeyPlan = Rx<JourneyPlan?>(null);
  final _isCheckingIn = false.obs;
  final _isFetchingLocation = false.obs;
  final _isWithinGeofence = false.obs;
  final _distanceToClient = 0.0.obs;
  final _isNetworkAvailable = true.obs;
  final _isSessionValid = true.obs;
  final _currentAddress = Rxn<String>();
  final _capturedImage = Rxn<File>();
  final _imageUrl = Rxn<String>();

  // Text controllers
  final notesController = TextEditingController();

  // Services
  late final JourneyLocationService _locationService;
  late final JourneyCheckInService _checkInService;

  // Connectivity
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _retryTimer;
  int _retryCount = 0;
  static const int maxRetries = 3;

  // Callbacks
  Function(JourneyPlan)? onCheckInSuccess;

  // Getters
  JourneyPlan? get journeyPlan => _journeyPlan.value;
  bool get isCheckingIn => _isCheckingIn.value;
  bool get isFetchingLocation => _isFetchingLocation.value;
  bool get isWithinGeofence => _isWithinGeofence.value;
  double get distanceToClient => _distanceToClient.value;
  bool get isNetworkAvailable => _isNetworkAvailable.value;
  bool get isSessionValid => _isSessionValid.value;
  String? get currentAddress => _currentAddress.value;
  File? get capturedImage => _capturedImage.value;
  String? get imageUrl => _imageUrl.value;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);

    // Initialize services
    _locationService = JourneyLocationService();
    _checkInService = JourneyCheckInService();

    // Setup service callbacks
    _setupServiceCallbacks();
  }

  @override
  void onClose() {
    // Clean up
    _connectivitySubscription?.cancel();
    _retryTimer?.cancel();
    notesController.dispose();
    _locationService.dispose();
    _checkInService.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      // Clean up camera resources when app goes to background
      ImageCache().clear();
      ImageCache().clearLiveImages();
    }
  }

  @override
  void didHaveMemoryPressure() {
    // Clear image cache when memory is low
    ImageCache().clear();
    ImageCache().clearLiveImages();
  }

  /// Initialize with journey plan
  void initialize(JourneyPlan journeyPlan) {
    _journeyPlan.value = journeyPlan;
    notesController.text = journeyPlan.notes ?? '';

    // Check network and session validity
    _checkNetworkAndSession();

    // Handle location based on journey status
    if (journeyPlan.isCheckedIn || journeyPlan.isInTransit) {
      _useCheckInLocation();
    } else {
      _getCurrentPosition();
    }

    // Start location updates for pending journeys
    if (journeyPlan.isPending) {
      _startLocationUpdates();
    } else if (journeyPlan.isCheckedIn) {
      _fixJourneyStatus();
    }
  }

  /// Setup callbacks for services
  void _setupServiceCallbacks() {
    // Location service callbacks
    _locationService.onPositionChanged = (position) {
      if (position != null && journeyPlan?.isPending == true) {
        _checkGeofence();
      }
    };

    _locationService.onAddressChanged = (address) {
      _currentAddress.value = address;
    };

    _locationService.onGeofenceChanged = (within) {
      _isWithinGeofence.value = within;
    };

    _locationService.onDistanceChanged = (distance) {
      _distanceToClient.value = distance;
    };

    // Check-in service callbacks
    _checkInService.onCheckInStateChanged = (checking) {
      _isCheckingIn.value = checking;
    };

    _checkInService.onCheckInSuccess = (updatedPlan) {
      _journeyPlan.value = updatedPlan;
      onCheckInSuccess?.call(updatedPlan);
    };

    _checkInService.onCheckInError = (error) {
      Get.snackbar(
        'Check-in Error',
        error,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    };

    _checkInService.onAllReportsSubmitted = () {
      _handleAllReportsSubmitted();
    };
  }

  /// Check network connectivity and session validity
  Future<void> _checkNetworkAndSession() async {
    try {
      // Check network connectivity
      final connectivityResult = await Connectivity().checkConnectivity();
      _isNetworkAvailable.value = connectivityResult != ConnectivityResult.none;

      // Check session validity
      _isSessionValid.value = await _validateSession();

      print('🌐 Network: $_isNetworkAvailable, Session: $_isSessionValid');
    } catch (e) {
      _isNetworkAvailable.value = true;
      _isSessionValid.value = true;
    }
  }

  /// Validate session token
  Future<bool> _validateSession() async {
    try {
      final token = await _getAuthToken();
      return token != null;
    } catch (e) {
      return false;
    }
  }

  /// Get auth token
  Future<String?> _getAuthToken() async {
    try {
      return 'valid_token'; // Replace with actual implementation
    } catch (e) {
      return null;
    }
  }

  /// Get current position
  Future<void> _getCurrentPosition() async {
    _isFetchingLocation.value = true;
    await _locationService.getCurrentPosition();
    _isFetchingLocation.value = false;
  }

  /// Start location updates
  void _startLocationUpdates() {
    if (journeyPlan?.isPending == true) {
      _locationService.startLocationUpdates();
    }
  }

  /// Use check-in location
  void _useCheckInLocation() {
    if (journeyPlan != null) {
      _locationService.useCheckInLocation(journeyPlan!);
    }
  }

  /// Check geofence
  Future<void> _checkGeofence() async {
    if (journeyPlan != null) {
      await _locationService.checkGeofence(journeyPlan!);
    }
  }

  /// Perform check-in
  Future<void> checkIn() async {
    if (journeyPlan == null) return;

    await _checkInService.performCheckIn(
      journeyPlan!,
      _locationService.currentPosition,
    );
  }

  /// Fix journey status if stuck in checked-in
  Future<void> _fixJourneyStatus() async {
    try {
      if (journeyPlan?.id == null || !journeyPlan!.isCheckedIn) return;

      print('🔧 Fixing journey status from checked-in to in-progress');

      final inProgressPlan = await JourneyPlanService.updateJourneyPlan(
        journeyId: journeyPlan!.id!,
        clientId: journeyPlan!.client.id,
        status: JourneyPlan.statusInProgress,
      );

      _journeyPlan.value = inProgressPlan;
      onCheckInSuccess?.call(inProgressPlan);
    } catch (e) {
      print('❌ Error fixing journey status: $e');
    }
  }

  /// Handle all reports submitted with optimistic UI
  Future<void> _handleAllReportsSubmitted() async {
    if (journeyPlan?.id == null) return;

    if (journeyPlan!.status != JourneyPlan.statusInProgress) {
      OptimisticUIHandler.logSilentError(
          'Journey not in progress, cannot complete',
          context: 'completion');
      return;
    }

    // Create optimistic completed plan
    final optimisticPlan = JourneyPlan(
      id: journeyPlan!.id,
      date: journeyPlan!.date,
      time: journeyPlan!.time,
      salesRepId: journeyPlan!.salesRepId,
      status: JourneyPlan.statusCompleted,
      notes: journeyPlan!.notes,
      checkInTime: journeyPlan!.checkInTime,
      latitude: journeyPlan!.latitude,
      longitude: journeyPlan!.longitude,
      imageUrl: journeyPlan!.imageUrl,
      client: journeyPlan!.client,
      checkoutTime: DateTime.now(),
      checkoutLatitude: journeyPlan!.latitude,
      checkoutLongitude: journeyPlan!.longitude,
      showUpdateLocation: journeyPlan!.showUpdateLocation,
      routeId: journeyPlan!.routeId,
    );

    // Use optimistic completion with immediate navigation
    await OptimisticUIHandler.optimisticComplete(
      successMessage: 'Visit completed successfully',
      operation: () async {
        await JourneyPlanService.updateJourneyPlan(
          journeyId: journeyPlan!.id!,
          clientId: journeyPlan!.client.id,
          status: JourneyPlan.statusCompleted,
        );
      },
      onOptimisticSuccess: () {
        _journeyPlan.value = optimisticPlan;
        onCheckInSuccess?.call(optimisticPlan);
      },
      navigationRoute: '/journeyplans',
      onFinalSuccess: () {
        print('✅ Journey completion synced with server');
      },
    );
  }

  /// Update client location with optimistic UI
  Future<void> updateClientLocation() async {
    if (_locationService.currentPosition == null) {
      OptimisticUIHandler.logSilentError('Current location not available',
          context: 'location-update');
      return;
    }

    _isFetchingLocation.value = true;

    // Show brief loading then refresh in background
    OptimisticUIHandler.showBriefLoading('Updating location...');

    // Perform refresh silently in background
    OptimisticUIHandler.silentBackground(
      operation: () => refreshJourneyStatus(),
      onSuccess: () {
        print('✅ Location refresh completed silently');
      },
      onFailure: () {
        OptimisticUIHandler.logSilentError('Location refresh failed',
            context: 'background-refresh');
      },
      operationName: 'location-refresh',
    );

    _isFetchingLocation.value = false;
  }

  /// Refresh journey status silently
  Future<void> refreshJourneyStatus() async {
    try {
      if (journeyPlan?.id == null) return;

      final updatedPlan =
          await JourneyPlanService.getJourneyPlanById(journeyPlan!.id!);

      if (updatedPlan != null) {
        _journeyPlan.value = updatedPlan;
        onCheckInSuccess?.call(updatedPlan);

        if (updatedPlan.isCheckedIn || updatedPlan.isInTransit) {
          _useCheckInLocation();
        }

        print('✅ Journey status refreshed successfully');
      }
    } catch (e) {
      OptimisticUIHandler.logSilentError(e, context: 'journey-refresh');
      // No user notification - handled silently
    }
  }

  /// Refresh location
  void refreshLocation() {
    Get.snackbar(
      'Refreshing',
      'Getting current location...',
      duration: const Duration(seconds: 1),
    );

    if (journeyPlan?.isPending == true) {
      _getCurrentPosition();
    } else {
      refreshJourneyStatus();
    }
  }

  /// Navigate to reports page
  void navigateToReports() async {
    if (journeyPlan == null) return;

    final result = await Get.to(
      () => ReportsOrdersPage(
        journeyPlan: journeyPlan!,
        onAllReportsSubmitted: _handleAllReportsSubmitted,
      ),
      transition: Transition.rightToLeft,
    );

    // Handle result from report pages
    if (result is JourneyPlan) {
      _journeyPlan.value = result;
      onCheckInSuccess?.call(result);
      print(
          '✅ Journey plan updated from report checkout: ${result.statusText}');
    }
  }

  /// Save notes with optimistic UI
  Future<void> saveNotes(String notes) async {
    if (journeyPlan?.id == null) return;

    // Create optimistic journey plan with updated notes
    final optimisticPlan = JourneyPlan(
      id: journeyPlan!.id,
      date: journeyPlan!.date,
      time: journeyPlan!.time,
      salesRepId: journeyPlan!.salesRepId,
      status: journeyPlan!.status,
      notes: notes.trim(),
      checkInTime: journeyPlan!.checkInTime,
      latitude: journeyPlan!.latitude,
      longitude: journeyPlan!.longitude,
      imageUrl: journeyPlan!.imageUrl,
      client: journeyPlan!.client,
      checkoutTime: journeyPlan!.checkoutTime,
      checkoutLatitude: journeyPlan!.checkoutLatitude,
      checkoutLongitude: journeyPlan!.checkoutLongitude,
      showUpdateLocation: journeyPlan!.showUpdateLocation,
      routeId: journeyPlan!.routeId,
    );

    // Use optimistic update
    await OptimisticUIHandler.optimisticUpdate(
      successMessage: 'Notes saved successfully',
      operation: () => JourneyPlanService.updateJourneyPlan(
        journeyId: journeyPlan!.id!,
        clientId: journeyPlan!.client.id,
        notes: notes.trim(),
        status: journeyPlan!.status,
      ),
      onOptimisticSuccess: () {
        _journeyPlan.value = optimisticPlan;
        onCheckInSuccess?.call(optimisticPlan);
      },
      onFinalSuccess: () {
        print('✅ Notes synced with server');
      },
    );
  }

  /// Check if journey can be completed
  bool canCompleteJourney() {
    return journeyPlan?.id != null &&
        journeyPlan!.status == JourneyPlan.statusInProgress;
  }

  /// Complete journey manually
  Future<void> completeJourney() async {
    if (!canCompleteJourney()) {
      Get.snackbar(
        'Cannot Complete',
        'Cannot complete visit at this time',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    await _handleAllReportsSubmitted();
  }
}
