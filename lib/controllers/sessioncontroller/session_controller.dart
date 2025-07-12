import 'package:get/get.dart';
import 'package:woosh/services/core/session_service.dart';
import 'package:woosh/models/user_session/session_model.dart';
import 'package:woosh/utils/error_handler.dart';

class SessionController extends GetxController {
  final RxBool isLoading = false.obs;
  final Rx<Session?> currentSession = Rx<Session?>(null);
  final RxList<Map<String, dynamic>> sessionHistory = <Map<String, dynamic>>[].obs;

  /// Get session history for a user
  Future<Map<String, dynamic>> getSessionHistory(
    String userId, {
    String? startDate,
    String? endDate,
  }) async {
    try {
      isLoading.value = true;
      final result = await SessionService.getSessionHistory(
        userId,
        startDate: startDate,
        endDate: endDate,
      );
      if (result['success'] == true) {
        sessionHistory.value = result['sessions'] ?? [];
      }
      return result;
    } catch (e) {
      ErrorHandler.handleSilentError(e, context: 'SessionController.getSessionHistory');
      return {
        'sessions': [],
        'totalSessions': 0,
        'success': false,
        'error': e.toString(),
      };
    } finally {
      isLoading.value = false;
    }
  }

  /// Start a new session
  Future<Map<String, dynamic>> startSession(int salesRepId) async {
    try {
      isLoading.value = true;
      final result = await SessionService.startSession(salesRepId);
      if (result['success'] == true) {
        // Refresh current session
        await getCurrentSession(salesRepId);
      }
      return result;
    } catch (e) {
      ErrorHandler.handleGeneralError(e, context: 'SessionController.startSession');
      return {
        'success': false,
        'message': 'Failed to start session',
        'error': e.toString(),
      };
    } finally {
      isLoading.value = false;
    }
  }

  /// End a session
  Future<Map<String, dynamic>> endSession(int sessionId) async {
    try {
      isLoading.value = true;
      final result = await SessionService.endSession(sessionId);
      if (result['success'] == true) {
        // Clear current session
        currentSession.value = null;
      }
      return result;
    } catch (e) {
      ErrorHandler.handleGeneralError(e, context: 'SessionController.endSession');
      return {
        'success': false,
        'message': 'Failed to end session',
        'error': e.toString(),
      };
    } finally {
      isLoading.value = false;
    }
  }

  /// Get current active session
  Future<Session?> getCurrentSession(int salesRepId) async {
    try {
      isLoading.value = true;
      final result = await SessionService.getCurrentSession(salesRepId);
      currentSession.value = result;
      return result;
    } catch (e) {
      ErrorHandler.handleSilentError(e, context: 'SessionController.getCurrentSession');
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  /// Check if session started late
  bool isSessionLate(DateTime sessionStart) {
    try {
      return SessionService.isSessionLate(sessionStart);
    } catch (e) {
      ErrorHandler.handleSilentError(e, context: 'SessionController.isSessionLate');
      return false;
    }
  }

  /// Check if session started early
  bool isSessionEarly(DateTime sessionStart) {
    try {
      return SessionService.isSessionEarly(sessionStart);
    } catch (e) {
      ErrorHandler.handleSilentError(e, context: 'SessionController.isSessionEarly');
      return false;
    }
  }

  /// Check if session ended early
  bool isSessionEndedEarly(DateTime sessionEnd) {
    try {
      return SessionService.isSessionEndedEarly(sessionEnd);
    } catch (e) {
      ErrorHandler.handleSilentError(e, context: 'SessionController.isSessionEndedEarly');
      return false;
    }
  }

  /// Check if it's time to auto-end sessions
  bool shouldAutoEndSessions() {
    try {
      return SessionService.shouldAutoEndSessions();
    } catch (e) {
      ErrorHandler.handleSilentError(e, context: 'SessionController.shouldAutoEndSessions');
      return false;
    }
  }

  /// Get current time in Nairobi timezone
  DateTime getNairobiTime() {
    try {
      return SessionService.getNairobiTime();
    } catch (e) {
      ErrorHandler.handleSilentError(e, context: 'SessionController.getNairobiTime');
      return DateTime.now();
    }
  }

  /// Get shift start time for today
  DateTime getShiftStartTime() {
    try {
      return SessionService.getShiftStartTime();
    } catch (e) {
      ErrorHandler.handleSilentError(e, context: 'SessionController.getShiftStartTime');
      return DateTime.now();
    }
  }

  /// Get shift end time for today
  DateTime getShiftEndTime() {
    try {
      return SessionService.getShiftEndTime();
    } catch (e) {
      ErrorHandler.handleSilentError(e, context: 'SessionController.getShiftEndTime');
      return DateTime.now();
    }
  }

  /// Clear session data
  void clearSessionData() {
    currentSession.value = null;
    sessionHistory.clear();
  }
} 