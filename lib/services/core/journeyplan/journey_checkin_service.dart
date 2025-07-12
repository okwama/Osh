import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:woosh/models/journeyplan/journeyplan_model.dart';
import 'package:woosh/services/core/journeyplan/journey_plan_service.dart';
import 'package:woosh/services/core/upload_service.dart';
import 'package:woosh/pages/journeyplan/reports/reportMain_page.dart';
import 'package:get/get.dart';

class JourneyCheckInService {
  bool _isCheckingIn = false;
  Timer? _retryTimer;
  int _retryCount = 0;
  static const int maxRetries = 3;

  // Callbacks
  Function(bool)? onCheckInStateChanged;
  Function(JourneyPlan)? onCheckInSuccess;
  Function(String)? onCheckInError;
  Function()? onAllReportsSubmitted;

  /// Get check-in state
  bool get isCheckingIn => _isCheckingIn;

  /// Perform check-in with photo capture
  Future<void> performCheckIn(
      JourneyPlan journeyPlan, Position? currentPosition) async {
    if (_isCheckingIn) return;

    try {
      _setCheckInState(true);

      // Validation checks
      if (journeyPlan.status == JourneyPlan.statusInProgress) {
        _handleCheckInError('Journey is already in progress');
        return;
      }

      // Get location with fallback
      if (currentPosition == null) {
        _handleCheckInError('Current location not available');
        return;
      }

      // Take photo
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 600,
        imageQuality: 60,
      );

      if (image == null) {
        _handleCheckInError('Photo capture cancelled');
        return;
      }

      // Show loading indicator
      _showLoadingDialog();

      // Brief delay to show loading indicator
      await Future.delayed(const Duration(seconds: 2));

      // Dismiss loading indicator
      _dismissLoadingDialog();

      // Create optimistic journey plan
      final now = DateTime.now();
      final optimisticPlan = JourneyPlan(
        id: journeyPlan.id,
        date: journeyPlan.date,
        time: journeyPlan.time,
        salesRepId: journeyPlan.salesRepId,
        status: JourneyPlan.statusInProgress,
        client: journeyPlan.client,
        showUpdateLocation: journeyPlan.showUpdateLocation,
        routeId: journeyPlan.routeId,
        checkInTime: now,
        latitude: currentPosition.latitude,
        longitude: currentPosition.longitude,
      );

      // Update parent immediately with optimistic data
      onCheckInSuccess?.call(optimisticPlan);

      // Navigate to reports page
      Get.off(
        () => ReportsOrdersPage(
          journeyPlan: optimisticPlan,
          onAllReportsSubmitted: onAllReportsSubmitted,
        ),
        transition: Transition.rightToLeft,
      );

      // Process background sync
      _processCheckInInBackground(File(image.path), optimisticPlan);
    } catch (e) {
      print('❌ Error during check-in: $e');
      _handleCheckInError('Check-in failed: ${e.toString()}');
    } finally {
      _setCheckInState(false);
    }
  }

  /// Background processing for check-in
  Future<void> _processCheckInInBackground(
      File imageFile, JourneyPlan optimisticPlan) async {
    try {
      // Upload image in background
      String? imageUrl;
      try {
        final uploadResult = await UploadService.uploadImage(imageFile);
        imageUrl = uploadResult['url'] as String?;
        print('✅ Image uploaded successfully: $imageUrl');
      } catch (e) {
        print('❌ Image upload failed: $e');
        imageUrl = null;
      }

      // Update journey plan in background
      try {
        final updatedPlan = await JourneyPlanService.updateJourneyPlan(
          journeyId: optimisticPlan.id!,
          clientId: optimisticPlan.client.id,
          status: JourneyPlan.statusInProgress,
          imageUrl: imageUrl,
          latitude: optimisticPlan.latitude,
          longitude: optimisticPlan.longitude,
          checkInTime: optimisticPlan.checkInTime,
        );

        _resetRetry();
        print('✅ Journey plan updated successfully');

        // Update parent with real data (silently)
        onCheckInSuccess?.call(updatedPlan);
      } catch (e) {
        print('❌ Journey plan update failed: $e');

        // Only schedule retry for non-server errors
        if (!_isServerError(e.toString())) {
          _scheduleRetry(
            () => _processCheckInInBackground(imageFile, optimisticPlan),
            operationName: 'background-journey-update',
          );
        } else {
          print('🔄 Server error - service will handle retries automatically');
        }
      }
    } catch (e) {
      print('❌ Background processing error: $e');
      _scheduleRetry(
        () => _processCheckInInBackground(imageFile, optimisticPlan),
        operationName: 'background-sync',
      );
    }
  }

  /// Check if error is a server error
  bool _isServerError(String error) {
    return error.contains('500') ||
        error.contains('501') ||
        error.contains('502') ||
        error.contains('503');
  }

  /// Schedule retry for failed operations
  void _scheduleRetry(Function retryFunction, {required String operationName}) {
    if (_retryCount >= maxRetries) {
      print('❌ Max retries reached for $operationName');
      return;
    }

    _retryCount++;
    final delay = Duration(seconds: _retryCount * 2); // Exponential backoff

    print(
        '🔄 Scheduling retry $_retryCount/$maxRetries for $operationName in ${delay.inSeconds}s');

    _retryTimer?.cancel();
    _retryTimer = Timer(delay, () {
      retryFunction();
    });
  }

  /// Reset retry counter
  void _resetRetry() {
    _retryCount = 0;
    _retryTimer?.cancel();
  }

  /// Show loading dialog
  void _showLoadingDialog() {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.black.withOpacity(0.8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Checking in...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  /// Dismiss loading dialog
  void _dismissLoadingDialog() {
    if (Get.isDialogOpen ?? false) {
      Get.back();
    }
  }

  /// Set check-in state
  void _setCheckInState(bool checkingIn) {
    _isCheckingIn = checkingIn;
    onCheckInStateChanged?.call(checkingIn);
  }

  /// Handle check-in error
  void _handleCheckInError(String message) {
    print('❌ Check-in error: $message');
    onCheckInError?.call(message);
  }

  /// Dispose resources
  void dispose() {
    _retryTimer?.cancel();
  }
}
