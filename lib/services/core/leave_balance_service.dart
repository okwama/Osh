import 'package:woosh/services/database_service.dart';
import 'package:woosh/models/leaves/leave_model.dart';

/// Service for managing leave balances using direct database connections
class LeaveBalanceService {
  static final DatabaseService _db = DatabaseService.instance;

  /// Get staff leave balances with single JOIN query and accurate used calculation
  static Future<List<LeaveBalance>> getStaffLeaveBalances(
      int staffId, int year) async {
    try {
      const employeeTypeId = 2; // sales_rep

      print('🔍 Loading leave balances for staff ID: $staffId, year: $year');

      // First, get all approved leave requests for this staff member in the given year
      const approvedLeaveSql = '''
        SELECT 
          leave_type_id,
          SUM(CASE WHEN is_half_day = 1 THEN 0.5 ELSE DATEDIFF(end_date, start_date) + 1 END) as total_used_days
        FROM leave_requests 
        WHERE employee_type_id = ? AND employee_id = ? AND status = 'approved' AND YEAR(start_date) = ?
        GROUP BY leave_type_id
      ''';

      final approvedLeaveResults =
          await _db.query(approvedLeaveSql, [employeeTypeId, staffId, year]);

      // Create a map of leave type ID to actual used days
      final Map<int, double> actualUsedDays = {};
      for (final row in approvedLeaveResults) {
        final fields = row.fields;
        final leaveTypeId = fields['leave_type_id'];
        final usedDays = (fields['total_used_days'] ?? 0).toDouble();
        actualUsedDays[leaveTypeId] = usedDays;
        print('📊 Actual used days for leave type $leaveTypeId: $usedDays');
      }

      // Single query with LEFT JOIN to get all leave types and existing balances
      const sql = '''
        SELECT 
          lt.id as lt_id, lt.name as lt_name, lt.max_days_per_year,
          lt.accrues, lt.monthly_accrual, lt.requires_attachment,
          lt.createdAt as lt_createdAt, lt.updatedAt as lt_updatedAt,
          lb.id as lb_id, lb.employee_type_id, lb.employee_id, lb.leave_type_id,
          lb.year, lb.accrued, lb.used, lb.carried_forward,
          lb.createdAt as lb_createdAt, lb.updatedAt as lb_updatedAt
        FROM leave_types lt
        LEFT JOIN leave_balances lb ON lt.id = lb.leave_type_id 
          AND lb.employee_type_id = ? AND lb.employee_id = ? AND lb.year = ?
        ORDER BY lt.name
      ''';

      final queryResults =
          await _db.query(sql, [employeeTypeId, staffId, year]);

      print('🔍 Leave balance query results: ${queryResults.length} rows');

      final results = queryResults.map((row) {
        final fields = row.fields;
        final leaveTypeId = fields['lt_id'];

        // Create LeaveType object
        final leaveType = LeaveType(
          id: leaveTypeId,
          name: _parseString(fields['lt_name']) ?? 'Unknown',
          maxDaysPerYear: fields['max_days_per_year']?.toDouble(),
          accrues: fields['accrues'] == 1,
          monthlyAccrual: (fields['monthly_accrual'] ?? 0).toDouble(),
          requiresAttachment: fields['requires_attachment'] == 1,
          createdAt: _parseDateTime(fields['lt_createdAt']),
          updatedAt: _parseDateTime(fields['lt_updatedAt']),
        );

        // Get actual used days from approved leave requests
        final actualUsed = actualUsedDays[leaveTypeId] ?? 0.0;

        // If balance exists, use it but override used with actual value
        if (fields['lb_id'] != null) {
          return LeaveBalance(
            id: fields['lb_id'],
            employeeType: _parseEmployeeType(fields['employee_type_id']),
            employeeId: fields['employee_id'],
            leaveTypeId: fields['leave_type_id'],
            year: fields['year'],
            accrued: (fields['accrued'] ?? 0).toDouble(),
            used: actualUsed, // Use actual used days from approved requests
            carriedForward: (fields['carried_forward'] ?? 0).toDouble(),
            createdAt: _parseDateTime(fields['lb_createdAt']),
            updatedAt: _parseDateTime(fields['lb_updatedAt']),
            leaveType: leaveType,
          );
        } else {
          // Create default balance with max days per year as accrued
          return LeaveBalance(
            employeeType: EmployeeType.SALES_REP,
            employeeId: staffId,
            leaveTypeId: leaveType.id,
            year: year,
            accrued: leaveType.maxDaysPerYear ?? 0.0,
            used: actualUsed, // Use actual used days from approved requests
            carriedForward: 0.0,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            leaveType: leaveType,
          );
        }
      }).toList();

      print(
          '✅ Processed ${results.length} leave balance records with accurate used calculations');
      return results;
    } catch (e) {
      print('❌ Get staff leave balances error: $e');
      rethrow;
    }
  }

  /// Get leave balance for specific employee and year with single JOIN query
  static Future<Map<String, dynamic>> getEmployeeLeaveBalance(
      int employeeId, int year) async {
    try {
      const sql = '''
        SELECT 
          lb.leave_type_id, lb.accrued, lb.used, lb.carried_forward,
          lt.name as leave_type_name, lt.max_days_per_year
        FROM leave_balances lb
        LEFT JOIN leave_types lt ON lb.leave_type_id = lt.id
        WHERE lb.employee_id = ? AND lb.year = ?
        ORDER BY lt.name
      ''';

      final results = await _db.query(sql, [employeeId, year]);

      final balances = <String, Map<String, dynamic>>{};

      for (final row in results) {
        final fields = row.fields;
        final leaveTypeName =
            _parseString(fields['leave_type_name']) ?? 'Unknown';
        final accrued = (fields['accrued'] ?? 0).toDouble();
        final used = (fields['used'] ?? 0).toDouble();
        final carriedForward = (fields['carried_forward'] ?? 0).toDouble();
        final maxDaysPerYear = (fields['max_days_per_year'] ?? 0).toDouble();

        balances[leaveTypeName] = {
          'accrued': accrued,
          'used': used,
          'carried_forward': carriedForward,
          'available': accrued + carriedForward - used,
          'max_days_per_year': maxDaysPerYear,
        };
      }

      return balances;
    } catch (e) {
      print('❌ Get employee leave balance error: $e');
      rethrow;
    }
  }

  /// Ensure user has a leave balance record for the given leave type
  static Future<void> ensureLeaveBalance(
      int employeeId, int leaveTypeId, int employeeTypeId,
      {double? maxDaysPerYear}) async {
    try {
      final currentYear = DateTime.now().year;

      // Check if balance record exists
      const checkSql = '''
        SELECT id FROM leave_balances 
        WHERE employee_type_id = ? AND employee_id = ? AND leave_type_id = ? AND year = ?
      ''';

      final checkResult = await _db.query(
          checkSql, [employeeTypeId, employeeId, leaveTypeId, currentYear]);

      if (checkResult.isEmpty) {
        // Use provided maxDaysPerYear or get it from database
        double daysPerYear = maxDaysPerYear ?? 0.0;

        if (maxDaysPerYear == null) {
          // Get leave type details (only if not provided)
          const leaveTypeSql =
              'SELECT max_days_per_year FROM leave_types WHERE id = ?';
          final leaveTypeResult = await _db.query(leaveTypeSql, [leaveTypeId]);

          if (leaveTypeResult.isNotEmpty) {
            daysPerYear =
                leaveTypeResult.first.fields['max_days_per_year']?.toDouble() ??
                    0.0;
          }
        }

        // Create default balance record with max days per year as accrued
        const insertSql = '''
          INSERT INTO leave_balances (
            employee_type_id, employee_id, leave_type_id, year, 
            accrued, used, carried_forward, createdAt, updatedAt
          ) VALUES (?, ?, ?, ?, ?, 0, 0, NOW(), NOW())
        ''';

        await _db.query(insertSql, [
          employeeTypeId,
          employeeId,
          leaveTypeId,
          currentYear,
          daysPerYear // Set accrued to max days per year for new users
        ]);
        print(
            '✅ Created default leave balance for employee $employeeId, leave type $leaveTypeId with ${daysPerYear} days');
      }
    } catch (e) {
      print('❌ Error ensuring leave balance: $e');
      // Don't throw error to avoid blocking leave application
    }
  }

  /// Update leave balance when leave is approved
  static Future<Map<String, dynamic>> updateBalanceOnApproval({
    required int employeeTypeId,
    required int employeeId,
    required int leaveTypeId,
    required DateTime startDate,
    required DateTime endDate,
    required bool isHalfDay,
  }) async {
    try {
      print('🔍 Updating balance for approved leave');
      print('   - Employee: $employeeId, Leave Type: $leaveTypeId');
      print('   - Start: $startDate, End: $endDate, Half Day: $isHalfDay');

      // Start transaction
      await _db.query('START TRANSACTION');

      try {
        // Calculate leave days
        double appliedDays;
        if (isHalfDay) {
          appliedDays = 0.5;
        } else {
          final days = endDate.difference(startDate).inDays + 1;
          appliedDays = days.toDouble();
        }

        // Determine year from start_date
        final year = startDate.year;

        print('📊 Leave calculation:');
        print('   - Applied days: $appliedDays');
        print('   - Year: $year');

        // Get or create leave balance record
        const getBalanceSql = '''
          SELECT id, accrued, used, carried_forward
          FROM leave_balances 
          WHERE employee_type_id = ? AND employee_id = ? AND leave_type_id = ? AND year = ?
          FOR UPDATE
        ''';

        final balanceResult = await _db.query(
            getBalanceSql, [employeeTypeId, employeeId, leaveTypeId, year]);

        double currentAccrued = 0.0;
        double currentUsed = 0.0;
        double currentCarriedForward = 0.0;
        bool balanceExists = false;

        if (balanceResult.isNotEmpty) {
          balanceExists = true;
          final balanceData = balanceResult.first.fields;
          currentAccrued = (balanceData['accrued'] ?? 0).toDouble();
          currentUsed = (balanceData['used'] ?? 0).toDouble();
          currentCarriedForward =
              (balanceData['carried_forward'] ?? 0).toDouble();
        } else {
          // Create default balance record
          const createBalanceSql = '''
            INSERT INTO leave_balances (
              employee_type_id, employee_id, leave_type_id, year,
              accrued, used, carried_forward, createdAt, updatedAt
            ) VALUES (?, ?, ?, ?, 0, 0, 0, NOW(), NOW())
          ''';

          await _db.query(createBalanceSql,
              [employeeTypeId, employeeId, leaveTypeId, year]);
          print('✅ Created default leave balance for year $year');
        }

        // Calculate new balance
        final newUsed = currentUsed + appliedDays;
        final totalAvailable = currentAccrued + currentCarriedForward;
        final newAvailable = totalAvailable - newUsed;

        print('📊 Balance calculation:');
        print('   - Current accrued: $currentAccrued');
        print('   - Current used: $currentUsed');
        print('   - Current carried forward: $currentCarriedForward');
        print('   - Total available: $totalAvailable');
        print('   - New used: $newUsed');
        print('   - New available: $newAvailable');

        // Update leave balance
        if (balanceExists) {
          const updateBalanceSql = '''
            UPDATE leave_balances 
            SET used = ?, updatedAt = NOW()
            WHERE employee_type_id = ? AND employee_id = ? AND leave_type_id = ? AND year = ?
          ''';

          await _db.query(updateBalanceSql,
              [newUsed, employeeTypeId, employeeId, leaveTypeId, year]);
        } else {
          // Update the newly created balance
          const updateNewBalanceSql = '''
            UPDATE leave_balances 
            SET used = ?, updatedAt = NOW()
            WHERE employee_type_id = ? AND employee_id = ? AND leave_type_id = ? AND year = ?
          ''';

          await _db.query(updateNewBalanceSql,
              [appliedDays, employeeTypeId, employeeId, leaveTypeId, year]);
        }

        // Commit transaction
        await _db.query('COMMIT');

        print('✅ Balance updated successfully');
        print('📊 Final balance:');
        print('   - New used: $newUsed');
        print('   - New available: $newAvailable');

        return {
          'success': true,
          'message': 'Balance updated successfully',
          'data': {
            'appliedDays': appliedDays,
            'newUsed': newUsed,
            'newAvailable': newAvailable,
            'year': year,
          },
        };
      } catch (e) {
        await _db.query('ROLLBACK');
        print('❌ Error in balance update transaction: $e');
        rethrow;
      }
    } catch (e) {
      print('❌ Update balance on approval error: $e');
      return {
        'success': false,
        'message': 'Failed to update balance: $e',
      };
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

  /// Sync leave balance table with actual approved leave requests
  static Future<void> syncLeaveBalances(int staffId, int year) async {
    try {
      const employeeTypeId = 2; // sales_rep

      print('🔄 Syncing leave balances for staff ID: $staffId, year: $year');

      // Get all approved leave requests for this staff member in the given year
      const approvedLeaveSql = '''
        SELECT 
          leave_type_id,
          SUM(CASE WHEN is_half_day = 1 THEN 0.5 ELSE DATEDIFF(end_date, start_date) + 1 END) as total_used_days
        FROM leave_requests 
        WHERE employee_type_id = ? AND employee_id = ? AND status = 'approved' AND YEAR(start_date) = ?
        GROUP BY leave_type_id
      ''';

      final approvedLeaveResults =
          await _db.query(approvedLeaveSql, [employeeTypeId, staffId, year]);

      // Update each leave balance with actual used days
      for (final row in approvedLeaveResults) {
        final fields = row.fields;
        final leaveTypeId = fields['leave_type_id'];
        final actualUsed = (fields['total_used_days'] ?? 0).toDouble();

        // Update the leave balance table
        const updateSql = '''
          UPDATE leave_balances 
          SET used = ?, updatedAt = NOW()
          WHERE employee_type_id = ? AND employee_id = ? AND leave_type_id = ? AND year = ?
        ''';

        await _db.query(updateSql,
            [actualUsed, employeeTypeId, staffId, leaveTypeId, year]);
        print(
            '✅ Updated leave balance for type $leaveTypeId: used = $actualUsed days');
      }

      print('✅ Leave balance sync completed');
    } catch (e) {
      print('❌ Error syncing leave balances: $e');
    }
  }
}
