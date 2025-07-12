import 'dart:io';
import 'package:get/get.dart';
import 'package:woosh/services/core/leave_service.dart';
import 'package:woosh/models/leaves/leave_model.dart';
import 'package:woosh/utils/error_handler.dart';

class LeaveController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxList<Leave> leaves = <Leave>[].obs;
  final RxMap<String, dynamic> leaveBalance = <String, dynamic>{}.obs;

  /// Get user's leave requests
  Future<List<Leave>> getUserLeaves() async {
    try {
      isLoading.value = true;
      final result = await LeaveService.getUserLeaves();
      leaves.value = result;
      return result;
    } catch (e) {
      ErrorHandler.handleSilentError(e,
          context: 'LeaveController.getUserLeaves');
      return [];
    } finally {
      isLoading.value = false;
    }
  }

  /// Get leave types
  Future<List<LeaveType>> getLeaveTypes() async {
    try {
      isLoading.value = true;
      final result = await LeaveService.getLeaveTypes();
      return result;
    } catch (e) {
      ErrorHandler.handleSilentError(e,
          context: 'LeaveController.getLeaveTypes');
      return [];
    } finally {
      isLoading.value = false;
    }
  }

  /// Submit leave application
  Future<Leave?> submitLeaveApplication({
    required String leaveType,
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
    String? attachmentUrl,
  }) async {
    try {
      isLoading.value = true;
      final result = await LeaveService.submitLeaveApplication(
        leaveType: leaveType,
        startDate: startDate,
        endDate: endDate,
        reason: reason,
        attachmentUrl: attachmentUrl,
      );
      if (result != null) {
        // Refresh leaves list
        await getUserLeaves();
      }
      return result;
    } catch (e) {
      ErrorHandler.handleGeneralError(e,
          context: 'LeaveController.submitLeaveApplication');
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  /// Create leave application
  Future<bool> createLeaveApplication(LeaveRequest leaveRequest) async {
    try {
      isLoading.value = true;
      final result = await LeaveService.createLeaveApplication(leaveRequest);
      if (result) {
        // Refresh leaves list
        await getUserLeaves();
      }
      return result;
    } catch (e) {
      ErrorHandler.handleGeneralError(e,
          context: 'LeaveController.createLeaveApplication');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Get leave balance
  Future<Map<String, dynamic>> getLeaveBalance() async {
    try {
      isLoading.value = true;
      final result = await LeaveService.getLeaveBalance();
      leaveBalance.value = result;
      return result;
    } catch (e) {
      ErrorHandler.handleSilentError(e,
          context: 'LeaveController.getLeaveBalance');
      return {};
    } finally {
      isLoading.value = false;
    }
  }

  /// Get leave stats
  Future<Map<String, dynamic>> getLeaveStats(int staffId, int year) async {
    try {
      isLoading.value = true;
      final result = await LeaveService.getLeaveStats(staffId, year);
      return result;
    } catch (e) {
      ErrorHandler.handleSilentError(e,
          context: 'LeaveController.getLeaveStats');
      return {
        'total_applications': 0,
        'pending_applications': 0,
        'approved_applications': 0,
        'rejected_applications': 0,
        'total_days_approved': 0.0,
      };
    } finally {
      isLoading.value = false;
    }
  }
}
