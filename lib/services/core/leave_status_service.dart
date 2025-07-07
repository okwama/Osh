import 'package:woosh/services/database_service.dart';
import 'package:woosh/models/leaves/leave_model.dart';
import 'package:woosh/services/core/leave_balance_service.dart';

/// Service for checking leave status and handling status-based deductions
class LeaveStatusService {
  static final DatabaseService _db = DatabaseService.instance;

  /// Check if a leave request is approved and update balance if needed
  static Future<Map<String, dynamic>> checkAndUpdateLeaveStatus(
      int leaveRequestId) async {
    try {
      print('🔍 Checking leave status for request ID: $leaveRequestId');

      // Get leave request details
      const getRequestSql = '''
        SELECT 
          id, employee_type_id, employee_id, leave_type_id,
          start_date, end_date, is_half_day, status
        FROM leave_requests 
        WHERE id = ?
      ''';

      final requestResult = await _db.query(getRequestSql, [leaveRequestId]);

      if (requestResult.isEmpty) {
        return {
          'success': false,
          'message': 'Leave request not found',
        };
      }

      final requestData = requestResult.first.fields;
      final status = requestData['status']?.toString().toLowerCase();
      final employeeTypeId = requestData['employee_type_id'];
      final employeeId = requestData['employee_id'];
      final leaveTypeId = requestData['leave_type_id'];
      final startDate = DateTime.parse(requestData['start_date']);
      final endDate = DateTime.parse(requestData['end_date']);
      final isHalfDay = requestData['is_half_day'] == 1;

      print('📊 Leave request details:');
      print('   - Status: $status');
      print('   - Employee: $employeeId');
      print('   - Leave Type: $leaveTypeId');
      print('   - Start: $startDate, End: $endDate');
      print('   - Half Day: $isHalfDay');

      // If status is approved, update balance
      if (status == 'approved') {
        print('✅ Leave is approved - updating balance');

        final balanceResult = await LeaveBalanceService.updateBalanceOnApproval(
          employeeTypeId: employeeTypeId,
          employeeId: employeeId,
          leaveTypeId: leaveTypeId,
          startDate: startDate,
          endDate: endDate,
          isHalfDay: isHalfDay,
        );

        return {
          'success': true,
          'message': 'Leave is approved',
          'status': 'approved',
          'balanceUpdate': balanceResult,
        };
      } else if (status == 'pending') {
        return {
          'success': true,
          'message': 'Leave is pending approval',
          'status': 'pending',
        };
      } else if (status == 'rejected') {
        return {
          'success': true,
          'message': 'Leave has been rejected',
          'status': 'rejected',
        };
      } else {
        return {
          'success': false,
          'message': 'Unknown leave status: $status',
        };
      }
    } catch (e) {
      print('❌ Check leave status error: $e');
      return {
        'success': false,
        'message': 'Failed to check leave status: $e',
      };
    }
  }

  /// Get leave status for a specific request
  static Future<Map<String, dynamic>> getLeaveStatus(int leaveRequestId) async {
    try {
      const sql = '''
        SELECT 
          id, status, approved_by, updated_at,
          start_date, end_date, is_half_day,
          employee_type_id, employee_id, leave_type_id
        FROM leave_requests 
        WHERE id = ?
      ''';

      final result = await _db.query(sql, [leaveRequestId]);

      if (result.isEmpty) {
        return {
          'success': false,
          'message': 'Leave request not found',
        };
      }

      final data = result.first.fields;
      final status = data['status']?.toString().toLowerCase();

      return {
        'success': true,
        'data': {
          'id': data['id'],
          'status': status,
          'approvedBy': data['approved_by'],
          'updatedAt': _parseDateTime(data['updated_at']),
          'startDate': _parseDateTime(data['start_date']),
          'endDate': _parseDateTime(data['end_date']),
          'isHalfDay': data['is_half_day'] == 1,
          'employeeTypeId': data['employee_type_id'],
          'employeeId': data['employee_id'],
          'leaveTypeId': data['leave_type_id'],
        },
      };
    } catch (e) {
      print('❌ Get leave status error: $e');
      return {
        'success': false,
        'message': 'Failed to get leave status: $e',
      };
    }
  }

  /// Get all leave requests with their current status
  static Future<List<LeaveRequest>> getLeaveRequestsWithStatus() async {
    try {
      const sql = '''
        SELECT 
          lr.id, lr.employee_type_id, lr.employee_id, lr.leave_type_id,
          lr.start_date, lr.end_date, lr.is_half_day, lr.reason,
          lr.status, lr.attachment_url, lr.applied_at, lr.updated_at,
          lr.approved_by,
          lt.id as lt_id, lt.name as lt_name, lt.max_days_per_year,
          lt.accrues, lt.monthly_accrual, lt.requires_attachment,
          lt.createdAt as lt_createdAt, lt.updatedAt as lt_updatedAt
        FROM leave_requests lr
        LEFT JOIN leave_types lt ON lr.leave_type_id = lt.id
        ORDER BY lr.applied_at DESC
      ''';

      final results = await _db.query(sql);

      return results.map((row) {
        final fields = row.fields;

        // Create LeaveType object
        final leaveType = LeaveType(
          id: fields['lt_id'],
          name: fields['lt_name'] ?? 'Unknown',
          maxDaysPerYear: fields['max_days_per_year']?.toDouble(),
          accrues: fields['accrues'] == 1,
          monthlyAccrual: (fields['monthly_accrual'] ?? 0).toDouble(),
          requiresAttachment: fields['requires_attachment'] == 1,
          createdAt: _parseDateTime(fields['lt_createdAt']),
          updatedAt: _parseDateTime(fields['lt_updatedAt']),
        );

        return LeaveRequest(
          id: fields['id'],
          employeeType: _parseEmployeeType(fields['employee_type_id']),
          employeeId: fields['employee_id'],
          leaveTypeId: fields['leave_type_id'],
          startDate: _parseDateTime(fields['start_date']),
          endDate: _parseDateTime(fields['end_date']),
          isHalfDay: fields['is_half_day'] == 1,
          reason: fields['reason'],
          status: _parseLeaveStatus(fields['status']),
          approvedBy: fields['approved_by'],
          attachmentUrl: fields['attachment_url'],
          appliedAt: _parseDateTime(fields['applied_at']),
          updatedAt: _parseDateTime(fields['updated_at']),
          leaveType: leaveType,
        );
      }).toList();
    } catch (e) {
      print('❌ Get leave requests with status error: $e');
      rethrow;
    }
  }

  /// Monitor leave status changes and update balances automatically
  static Future<void> monitorLeaveStatusChanges() async {
    try {
      print('🔍 Monitoring leave status changes...');

      // Get all leave requests that might need balance updates
      const sql = '''
        SELECT 
          id, employee_type_id, employee_id, leave_type_id,
          start_date, end_date, is_half_day, status
        FROM leave_requests 
        WHERE status = 'approved'
        ORDER BY updated_at DESC
      ''';

      final results = await _db.query(sql);

      for (final row in results) {
        final fields = row.fields;
        final leaveRequestId = fields['id'];
        final status = fields['status']?.toString().toLowerCase();

        if (status == 'approved') {
          print(
              '🔍 Checking if balance needs update for leave request $leaveRequestId');

          // Check if balance was already updated (this is a simplified check)
          // In a real implementation, you might want to track this more precisely
          final balanceResult = await checkAndUpdateLeaveStatus(leaveRequestId);

          if (balanceResult['success']) {
            print(
                '✅ Balance check completed for leave request $leaveRequestId');
          } else {
            print(
                '❌ Balance check failed for leave request $leaveRequestId: ${balanceResult['message']}');
          }
        }
      }
    } catch (e) {
      print('❌ Monitor leave status changes error: $e');
    }
  }

  /// Parse leave status from string
  static LeaveStatus _parseLeaveStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return LeaveStatus.PENDING;
      case 'approved':
        return LeaveStatus.APPROVED;
      case 'rejected':
        return LeaveStatus.REJECTED;
      default:
        return LeaveStatus.PENDING;
    }
  }

  /// Parse employee type from ID
  static EmployeeType _parseEmployeeType(dynamic value) {
    if (value == 1) return EmployeeType.STAFF;
    if (value == 2) return EmployeeType.SALES_REP;
    return EmployeeType.STAFF; // default
  }

  /// Parse DateTime from various formats
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }
}
