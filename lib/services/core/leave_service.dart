import 'package:woosh/services/database_service.dart';
import 'package:woosh/models/leaves/leave_model.dart';
import 'package:woosh/services/core/leave_balance_service.dart';
import 'package:get_storage/get_storage.dart';

/// Service for managing leave applications using direct database connections
/// NOTE: This service is configured for sales reps to show only sick leave
/// Other leave types are filtered out for sales rep users
class LeaveService {
  static final DatabaseService _db = DatabaseService.instance;

  /// Get all leave types (filtered to show only sick leave for sales reps)
  static Future<List<LeaveType>> getLeaveTypes() async {
    try {
      // For sales reps, only show sick leave
      const sql =
          "SELECT * FROM leave_types WHERE name LIKE '%sick%' OR name LIKE '%Sick%' ORDER BY name";
      final results = await _db.query(sql);

      return results.map((row) {
        final fields = row.fields;
        return LeaveType(
          id: fields['id'],
          name: fields['name'],
          maxDaysPerYear: fields['max_days_per_year']?.toDouble(),
          accrues: fields['accrues'] == 1,
          monthlyAccrual: (fields['monthly_accrual'] ?? 0).toDouble(),
          requiresAttachment: fields['requires_attachment'] == 1,
          createdAt: _parseDateTime(fields['createdAt']),
          updatedAt: _parseDateTime(fields['updatedAt']),
        );
      }).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get current user ID from storage
  static int? _getCurrentUserId() {
    try {
      final box = GetStorage();

      // Try to get user ID directly first
      final userId = box.read('userId');
      if (userId != null) {
        return userId is int ? userId : int.tryParse(userId.toString());
      }

      // Fallback: try to get from salesRep data
      final salesRepData = box.read('salesRep');
      if (salesRepData is Map<String, dynamic> && salesRepData['id'] != null) {
        return salesRepData['id'] is int
            ? salesRepData['id']
            : int.tryParse(salesRepData['id'].toString());
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Submit a leave application
  static Future<Leave> submitLeaveApplication({
    required String leaveType,
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
    String? attachmentUrl,
  }) async {
    try {
      // Get current user ID
      final salesRepId = _getCurrentUserId();
      if (salesRepId == null) {
        throw Exception('User not authenticated. Please login again.');
      }

      // Get leave type details in a single query
      final leaveTypeDetails = await _getLeaveTypeDetails(leaveType);
      if (leaveTypeDetails == null) {
        throw Exception('Invalid leave type: $leaveType');
      }

      final leaveTypeId = leaveTypeDetails['id'];
      final leaveTypeName = leaveTypeDetails['name'];

      // Get employee type ID (assuming sales_rep for now)
      const employeeTypeId = 2; // sales_rep from the SQL schema

      // Calculate duration
      final duration = endDate.difference(startDate).inDays + 1;

      // Ensure user has a balance record for this leave type
      await LeaveBalanceService.ensureLeaveBalance(
        salesRepId,
        leaveTypeId,
        employeeTypeId,
        maxDaysPerYear: leaveTypeDetails['maxDaysPerYear'],
      );

      // Insert leave request
      const sql = '''
        INSERT INTO leave_requests (
          employee_type_id, employee_id, leave_type_id, 
          start_date, end_date, reason, attachment_url, status
        ) VALUES (?, ?, ?, ?, ?, ?, ?, 'pending')
      ''';

      final result = await _db.query(sql, [
        employeeTypeId,
        salesRepId,
        leaveTypeId,
        startDate.toIso8601String().split('T')[0],
        endDate.toIso8601String().split('T')[0],
        reason,
        attachmentUrl,
      ]);

      if (result.insertId == null) {
        throw Exception('Failed to create leave request');
      }

      // Create and return Leave object
      return Leave(
        id: result.insertId!,
        userId: salesRepId,
        leaveType: leaveTypeName,
        startDate: startDate,
        endDate: endDate,
        reason: reason,
        attachment: attachmentUrl,
        status: LeaveStatus.PENDING,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Create leave application (optimized version)
  static Future<bool> createLeaveApplication(LeaveRequest leaveRequest) async {
    try {
      // Get current user ID
      final salesRepId = _getCurrentUserId();
      if (salesRepId == null) {
        throw Exception('User not authenticated. Please login again.');
      }

      final leaveTypeName = leaveRequest.leaveType?.name ?? 'General';
      final leaveTypeId = leaveRequest.leaveTypeId;
      const employeeTypeId = 2; // sales_rep

      // Ensure user has a balance record for this leave type
      await LeaveBalanceService.ensureLeaveBalance(
        salesRepId,
        leaveTypeId,
        employeeTypeId,
        maxDaysPerYear: leaveRequest.leaveType?.maxDaysPerYear,
      );

      // Insert leave request directly
      const sql = '''
        INSERT INTO leave_requests (
          employee_type_id, employee_id, leave_type_id, 
          start_date, end_date, is_half_day, reason, attachment_url, status
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'pending')
      ''';

      final result = await _db.query(sql, [
        employeeTypeId,
        salesRepId,
        leaveTypeId,
        leaveRequest.startDate.toIso8601String().split('T')[0],
        leaveRequest.endDate.toIso8601String().split('T')[0],
        leaveRequest.isHalfDay ? 1 : 0,
        leaveRequest.reason,
        leaveRequest.attachmentUrl,
      ]);

      return result.insertId != null;
    } catch (e) {
      return false;
    }
  }

  /// Get user's leave requests
  static Future<List<Leave>> getUserLeaves() async {
    try {
      // Get current user ID
      final salesRepId = _getCurrentUserId();
      if (salesRepId == null) {
        throw Exception('User not authenticated. Please login again.');
      }

      const sql = '''
        SELECT 
          lr.id, lr.employee_type_id, lr.employee_id, lr.leave_type_id,
          lr.start_date, lr.end_date, lr.is_half_day, lr.reason,
          lr.status, lr.attachment_url, lr.applied_at,
          lt.name as leave_type_name
        FROM leave_requests lr
        LEFT JOIN leave_types lt ON lr.leave_type_id = lt.id
        WHERE lr.employee_id = ?
        ORDER BY lr.applied_at DESC
      ''';

      final results = await _db.query(sql, [salesRepId]);

      return results.map((row) {
        final fields = row.fields;
        return Leave(
          id: fields['id'],
          userId: fields['employee_id'],
          leaveType: fields['leave_type_name'] ?? 'Unknown',
          startDate: _parseDateTime(fields['start_date']),
          endDate: _parseDateTime(fields['end_date']),
          reason: fields['reason'],
          attachment: fields['attachment_url'],
          status: _parseLeaveStatus(fields['status']),
          createdAt: _parseDateTime(fields['applied_at']),
          updatedAt: _parseDateTime(fields['applied_at']),
        );
      }).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get staff leaves (alias for getUserLeaves)
  static Future<List<LeaveRequest>> getStaffLeaves(int staffId) async {
    try {
      const sql = '''
        SELECT 
          lr.id, lr.employee_type_id, lr.employee_id, lr.leave_type_id,
          lr.start_date, lr.end_date, lr.is_half_day, lr.reason,
          lr.status, lr.attachment_url, lr.applied_at, lr.updated_at,
          lt.id as lt_id, lt.name as lt_name, lt.max_days_per_year,
          lt.accrues, lt.monthly_accrual, lt.requires_attachment,
          lt.createdAt as lt_createdAt, lt.updatedAt as lt_updatedAt
        FROM leave_requests lr
        LEFT JOIN leave_types lt ON lr.leave_type_id = lt.id
        WHERE lr.employee_id = ?
        ORDER BY lr.applied_at DESC
      ''';

      final results = await _db.query(sql, [staffId]);

      return results.map((row) {
        final fields = row.fields;

        // Create LeaveType object
        final leaveType = LeaveType(
          id: fields['lt_id'],
          name: _parseString(fields['lt_name']) ?? 'Unknown',
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
          reason: _parseString(fields['reason']),
          status:
              _parseLeaveStatus(_parseString(fields['status']) ?? 'pending'),
          attachmentUrl: _parseString(fields['attachment_url']),
          appliedAt: _parseDateTime(fields['applied_at']),
          updatedAt: _parseDateTime(fields['updated_at']),
          leaveType: leaveType,
        );
      }).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get leave balance for user
  static Future<Map<String, dynamic>> getLeaveBalance() async {
    try {
      // Get current user ID
      final salesRepId = _getCurrentUserId();
      if (salesRepId == null) {
        throw Exception('User not authenticated. Please login again.');
      }

      const currentYear = 2024; // You might want to make this dynamic
      const employeeTypeId = 2; // sales_rep

      const sql = '''
        SELECT 
          lb.leave_type_id, lb.accrued, lb.used, lb.carried_forward,
          lt.name as leave_type_name
        FROM leave_balances lb
        LEFT JOIN leave_types lt ON lb.leave_type_id = lt.id
        WHERE lb.employee_type_id = ? AND lb.employee_id = ? AND lb.year = ?
      ''';

      final results =
          await _db.query(sql, [employeeTypeId, salesRepId, currentYear]);

      final balances = <String, Map<String, dynamic>>{};

      for (final row in results) {
        final fields = row.fields;
        final leaveTypeName = fields['leave_type_name'] ?? 'Unknown';

        balances[leaveTypeName] = {
          'accrued': fields['accrued'] ?? 0.0,
          'used': fields['used'] ?? 0.0,
          'carried_forward': fields['carried_forward'] ?? 0.0,
          'available': (fields['accrued'] ?? 0.0) +
              (fields['carried_forward'] ?? 0.0) -
              (fields['used'] ?? 0.0),
        };
      }

      return balances;
    } catch (e) {
      rethrow;
    }
  }

  /// Get leave stats
  static Future<Map<String, dynamic>> getLeaveStats(
      int staffId, int year) async {
    try {
      const employeeTypeId = 2; // sales_rep

      const sql = '''
        SELECT 
          COUNT(*) as total_applications,
          SUM(CASE WHEN status = 'pending' THEN 1 ELSE 0 END) as pending_applications,
          SUM(CASE WHEN status = 'approved' THEN 1 ELSE 0 END) as approved_applications,
          SUM(CASE WHEN status = 'rejected' THEN 1 ELSE 0 END) as rejected_applications,
          SUM(CASE WHEN status = 'approved' THEN DATEDIFF(end_date, start_date) + 1 ELSE 0 END) as total_days_approved
        FROM leave_requests
        WHERE employee_type_id = ? AND employee_id = ? AND YEAR(start_date) = ?
      ''';

      final results = await _db.query(sql, [employeeTypeId, staffId, year]);

      if (results.isNotEmpty) {
        final fields = results.first.fields;
        return {
          'total_applications': fields['total_applications'] ?? 0,
          'pending_applications': fields['pending_applications'] ?? 0,
          'approved_applications': fields['approved_applications'] ?? 0,
          'rejected_applications': fields['rejected_applications'] ?? 0,
          'total_days_approved':
              (fields['total_days_approved'] ?? 0).toDouble(),
        };
      }

      return {
        'total_applications': 0,
        'pending_applications': 0,
        'approved_applications': 0,
        'rejected_applications': 0,
        'total_days_approved': 0.0,
      };
    } catch (e) {
      rethrow;
    }
  }

  /// Get leave type details by name (single query)
  static Future<Map<String, dynamic>?> _getLeaveTypeDetails(
      String leaveTypeName) async {
    try {
      const sql =
          'SELECT id, name, max_days_per_year FROM leave_types WHERE name = ?';
      final results = await _db.query(sql, [leaveTypeName]);

      if (results.isNotEmpty) {
        final fields = results.first.fields;
        return {
          'id': fields['id'],
          'name': fields['name'],
          'maxDaysPerYear': fields['max_days_per_year']?.toDouble(),
        };
      }
      return null;
    } catch (e) {
      return null;
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

  /// Parse String from various formats (including Blob)
  static String? _parseString(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is List<int>) {
      // Handle Blob data
      try {
        return String.fromCharCodes(value);
      } catch (e) {
        return null;
      }
    }
    return value.toString();
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
