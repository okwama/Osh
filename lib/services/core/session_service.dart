import 'package:woosh/services/database_service.dart';
import 'package:woosh/models/user_session/session_model.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

/// Service for managing user sessions using direct database connections
class SessionService {
  static final DatabaseService _db = DatabaseService.instance;

  // Cache for current sessions to reduce database queries
  static final Map<int, Session?> _sessionCache = {};
  static final Map<int, DateTime> _lastCheckTime = {};
  static const Duration _cacheValidity =
      Duration(minutes: 2); // Cache for 2 minutes

  // Shift configuration
  static const String _timezone = 'Africa/Nairobi';
  static const int _shiftStartHour = 9; // 9:00 AM
  static const int _shiftEndHour = 18; // 6:00 PM
  static const int _gracePeriodMinutes = 15; // 15 minutes grace period
  static const int _autoEndMinutes =
      10; // Auto-end 10 minutes after shift end (6:10 PM)

  // Initialize timezone
  static void initializeTimezone() {
    tz.initializeTimeZones();
  }

  /// Get current time in Nairobi timezone
  static DateTime getNairobiTime() {
    return tz.TZDateTime.now(tz.getLocation(_timezone));
  }

  /// Get shift start time for today
  static DateTime getShiftStartTime() {
    final now = getNairobiTime();
    return DateTime(now.year, now.month, now.day, _shiftStartHour);
  }

  /// Get shift end time for today
  static DateTime getShiftEndTime() {
    final now = getNairobiTime();
    return DateTime(now.year, now.month, now.day, _shiftEndHour);
  }

  /// Get auto-end time (6:10 PM)
  static DateTime getAutoEndTime() {
    final now = getNairobiTime();
    return DateTime(
        now.year, now.month, now.day, _shiftEndHour, _autoEndMinutes);
  }

  /// Check if session started late
  static bool isSessionLate(DateTime sessionStart) {
    final shiftStart = getShiftStartTime();
    final lateThreshold =
        shiftStart.add(Duration(minutes: _gracePeriodMinutes));
    return sessionStart.isAfter(lateThreshold);
  }

  /// Check if session started early
  static bool isSessionEarly(DateTime sessionStart) {
    final shiftStart = getShiftStartTime();
    return sessionStart.isBefore(shiftStart);
  }

  /// Check if session ended early (before 6 PM)
  static bool isSessionEndedEarly(DateTime sessionEnd) {
    final shiftEnd = getShiftEndTime();
    return sessionEnd.isBefore(shiftEnd);
  }

  /// Check if it's time to auto-end sessions (6:10 PM)
  static bool shouldAutoEndSessions() {
    final now = getNairobiTime();
    final autoEndTime = getAutoEndTime();
    return now.isAfter(autoEndTime);
  }

  /// Format DateTime to MySQL DATETIME format (YYYY-MM-DD HH:MM:SS)
  static String _formatDateTime(DateTime dateTime) {
    return dateTime.toString().substring(0, 19).replaceFirst('T', ' ');
  }

  /// Get session history for a user
  static Future<Map<String, dynamic>> getSessionHistory(
    String userId, {
    String? startDate,
    String? endDate,
  }) async {
    try {
      String sql = '''
        SELECT 
          id, userId, loginAt, logoutAt, sessionStart, sessionEnd,
          status, isLate
        FROM LoginHistory 
        WHERE userId = ?
      ''';

      final params = <dynamic>[userId];

      if (startDate != null && endDate != null) {
        sql += ' AND DATE(loginAt) BETWEEN ? AND ?';
        params.addAll([startDate, endDate]);
      }

      sql += ' ORDER BY loginAt DESC LIMIT 50';

      final results = await _db.query(sql, params);

      final sessions = results.map((row) {
        final fields = row.fields;
        return Session(
          id: fields['id'],
          userId: fields['userId'],
          loginAt: fields['loginAt'] is DateTime
              ? fields['loginAt'] as DateTime
              : DateTime.parse(fields['loginAt'].toString()),
          logoutAt: fields['logoutAt'] != null
              ? (fields['logoutAt'] is DateTime
                  ? fields['logoutAt'] as DateTime
                  : DateTime.parse(fields['logoutAt'].toString()))
              : null,
          sessionStart: fields['sessionStart'] != null
              ? (fields['sessionStart'] is DateTime
                  ? fields['sessionStart'] as DateTime
                  : DateTime.parse(fields['sessionStart'].toString()))
              : null,
          sessionEnd: fields['sessionEnd'] != null
              ? (fields['sessionEnd'] is DateTime
                  ? fields['sessionEnd'] as DateTime
                  : DateTime.parse(fields['sessionEnd'].toString()))
              : null,
          timezone: 'UTC',
          isLate: fields['isLate'] == 1,
          status: fields['status']?.toString() ?? '0',
        );
      }).toList();

      return {
        'sessions': sessions.map((s) => s.toJson()).toList(),
        'totalSessions': sessions.length,
        'success': true,
      };
    } catch (e) {
      return {
        'sessions': [],
        'totalSessions': 0,
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Start a new session
  static Future<Map<String, dynamic>> startSession(int salesRepId) async {
    try {
      // Test database connectivity first
      try {
        await _db.query('SELECT 1 as test');
      } catch (e) {
        return {
          'success': false,
          'message': 'Database connection failed: ${e.toString()}',
          'error': e.toString(),
        };
      }

      // First, ensure the LoginHistory table exists
      await _ensureLoginHistoryTable();

      final now = getNairobiTime();
      final shiftStart = getShiftStartTime();

      // Check if it's before 9 AM and prevent session start
      if (now.isBefore(shiftStart)) {
        final timeUntilStart = shiftStart.difference(now);
        final hours = timeUntilStart.inHours;
        final minutes = timeUntilStart.inMinutes.remainder(60);

        String timeMessage;
        if (hours > 0) {
          timeMessage =
              '$hours hour${hours > 1 ? 's' : ''} and $minutes minute${minutes > 1 ? 's' : ''}';
        } else {
          timeMessage = '$minutes minute${minutes > 1 ? 's' : ''}';
        }

        return {
          'success': false,
          'message':
              'Sessions cannot be started before 9:00 AM. Please wait $timeMessage until your shift begins.',
          'error': 'EARLY_SESSION_RESTRICTED',
        };
      }

      final nowString = _formatDateTime(now);

      // Determine if session is late or early
      final isLate = isSessionLate(now);
      final isEarly = isSessionEarly(now);

      const sql = '''
        INSERT INTO LoginHistory (
          userId, loginAt, sessionStart, status, isLate, isEarly, shiftStart, shiftEnd, timezone
        ) VALUES (?, ?, ?, '1', ?, ?, ?, ?, ?)
      ''';

      final shiftStartString = _formatDateTime(shiftStart);
      final shiftEnd = _formatDateTime(getShiftEndTime());

      print(
          '📋 Session status: ${isLate ? 'LATE' : isEarly ? 'EARLY' : 'ON TIME'}');

      final result = await _db.query(sql, [
        salesRepId,
        nowString,
        nowString,
        isLate ? 1 : 0,
        isEarly ? 1 : 0,
        shiftStartString,
        shiftEnd,
        _timezone
      ]);

      if (result.insertId != null) {
        // Clear cache for this user to force refresh
        _sessionCache.remove(salesRepId);
        _lastCheckTime.remove(salesRepId);

        return {
          'success': true,
          'message': 'Session started successfully',
          'sessionId': result.insertId,
          'isLate': isLate,
          'isEarly': isEarly,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to start session - no insert ID returned',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred while starting session: ${e.toString()}',
        'error': e.toString(),
      };
    }
  }

  /// Ensure LoginHistory table exists
  static Future<void> _ensureLoginHistoryTable() async {
    try {
      const createTableSql = '''
        CREATE TABLE IF NOT EXISTS LoginHistory (
          id INT AUTO_INCREMENT PRIMARY KEY,
          userId INT NOT NULL,
          loginAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
          logoutAt DATETIME DEFAULT NULL,
          isLate TINYINT(1) DEFAULT 0,
          isEarly TINYINT(1) DEFAULT 0,
          timezone VARCHAR(191) DEFAULT 'UTC',
          shiftStart DATETIME DEFAULT NULL,
          shiftEnd DATETIME DEFAULT NULL,
          duration INT DEFAULT NULL,
          status VARCHAR(191) DEFAULT '0',
          sessionEnd DATETIME DEFAULT NULL,
          sessionStart DATETIME DEFAULT NULL,
          INDEX idx_userId (userId),
          INDEX idx_loginAt (loginAt),
          INDEX idx_logoutAt (logoutAt)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
      ''';

      await _db.query(createTableSql);
    } catch (e) {
      // Don't rethrow - table might already exist
    }
  }

  /// End a session
  static Future<Map<String, dynamic>> endSession(int sessionId) async {
    try {
      final now = getNairobiTime();
      final nowString = _formatDateTime(now);

      // Check if session ended early
      final endedEarly = isSessionEndedEarly(now);

      const sql = '''
        UPDATE LoginHistory 
        SET logoutAt = ?, sessionEnd = ?, status = '0'
        WHERE id = ? AND status = '1' AND sessionEnd IS NULL
      ''';

      final result = await _db.query(sql, [nowString, nowString, sessionId]);

      if ((result.affectedRows ?? 0) > 0) {
        // Clear all session caches since session state changed
        _sessionCache.clear();
        _lastCheckTime.clear();

        return {
          'success': true,
          'message': 'Session ended successfully',
          'endedEarly': endedEarly,
        };
      } else {
        return {
          'success': false,
          'message': 'Session not found or already ended',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred while ending session',
      };
    }
  }

  /// Get current active session with caching and better error handling
  static Future<Session?> getCurrentSession(int salesRepId) async {
    try {
      // Check if we have a valid cached session
      final lastCheck = _lastCheckTime[salesRepId];
      final cachedSession = _sessionCache[salesRepId];

      if (lastCheck != null && cachedSession != null) {
        final timeSinceLastCheck = DateTime.now().difference(lastCheck);
        if (timeSinceLastCheck < _cacheValidity) {
          print(
              '📋 Using cached session for user: $salesRepId (cached ${timeSinceLastCheck.inSeconds}s ago)');
          return cachedSession;
        }
      }

      const sql = '''
        SELECT 
          id, userId, loginAt, logoutAt, sessionStart, sessionEnd,
          status, isLate, isEarly, shiftStart, shiftEnd, timezone
        FROM LoginHistory 
        WHERE userId = ? AND status = '1' AND sessionEnd IS NULL
        ORDER BY loginAt DESC
        LIMIT 1
      ''';

      // Add timeout and retry logic
      dynamic results;
      try {
        results = await _db.query(sql, [salesRepId]);
      } catch (e) {
        // Return cached session if available, otherwise null
        return cachedSession;
      }

      Session? session;
      if (results.isEmpty) {
        session = null;
      } else {
        final fields = results.first.fields;

        session = Session(
          id: fields['id'],
          userId: fields['userId'],
          loginAt: fields['loginAt'] is DateTime
              ? fields['loginAt'] as DateTime
              : DateTime.parse(fields['loginAt'].toString()),
          logoutAt: fields['logoutAt'] != null
              ? (fields['logoutAt'] is DateTime
                  ? fields['logoutAt'] as DateTime
                  : DateTime.parse(fields['logoutAt'].toString()))
              : null,
          sessionStart: fields['sessionStart'] != null
              ? (fields['sessionStart'] is DateTime
                  ? fields['sessionStart'] as DateTime
                  : DateTime.parse(fields['sessionStart'].toString()))
              : null,
          sessionEnd: fields['sessionEnd'] != null
              ? (fields['sessionEnd'] is DateTime
                  ? fields['sessionEnd'] as DateTime
                  : DateTime.parse(fields['sessionEnd'].toString()))
              : null,
          timezone: fields['timezone']?.toString() ?? 'Africa/Nairobi',
          shiftStart: fields['shiftStart'] != null
              ? (fields['shiftStart'] is DateTime
                  ? fields['shiftStart'] as DateTime
                  : DateTime.parse(fields['shiftStart'].toString()))
              : null,
          shiftEnd: fields['shiftEnd'] != null
              ? (fields['shiftEnd'] is DateTime
                  ? fields['shiftEnd'] as DateTime
                  : DateTime.parse(fields['shiftEnd'].toString()))
              : null,
          isLate: fields['isLate'] == 1,
          isEarly: fields['isEarly'] == 1,
          status: fields['status']?.toString() ?? '0',
        );
      }

      // Update cache
      _sessionCache[salesRepId] = session;
      _lastCheckTime[salesRepId] = DateTime.now();

      return session;
    } catch (e) {
      // Return cached session if available, otherwise null
      return _sessionCache[salesRepId];
    }
  }

  /// Clear session cache for a specific user or all users
  static void clearCache([int? userId]) {
    if (userId != null) {
      _sessionCache.remove(userId);
      _lastCheckTime.remove(userId);
    } else {
      _sessionCache.clear();
      _lastCheckTime.clear();
    }
  }

  /// Force refresh session for a user (bypass cache)
  static Future<Session?> refreshSession(int salesRepId) async {
    clearCache(salesRepId);
    return await getCurrentSession(salesRepId);
  }

  /// Get complete sessions (sessions with both start and end times)
  static Future<List<Session>> getCompleteSessions(
    int salesRepId, {
    String? startDate,
    String? endDate,
  }) async {
    try {
      String sql = '''
        SELECT 
          id, userId, loginAt, logoutAt, sessionStart, sessionEnd,
          status, isLate
        FROM LoginHistory 
        WHERE userId = ? AND sessionStart IS NOT NULL AND sessionEnd IS NOT NULL
      ''';

      final params = <dynamic>[salesRepId];

      if (startDate != null && endDate != null) {
        sql += ' AND DATE(sessionStart) BETWEEN ? AND ?';
        params.addAll([startDate, endDate]);
      }

      sql += ' ORDER BY sessionStart DESC';

      final results = await _db.query(sql, params);

      return results.map((row) {
        final fields = row.fields;
        return Session(
          id: fields['id'],
          userId: fields['userId'],
          loginAt: fields['loginAt'] is DateTime
              ? fields['loginAt'] as DateTime
              : DateTime.parse(fields['loginAt'].toString()),
          logoutAt: fields['logoutAt'] != null
              ? (fields['logoutAt'] is DateTime
                  ? fields['logoutAt'] as DateTime
                  : DateTime.parse(fields['logoutAt'].toString()))
              : null,
          sessionStart: fields['sessionStart'] is DateTime
              ? fields['sessionStart'] as DateTime
              : DateTime.parse(fields['sessionStart'].toString()),
          sessionEnd: fields['sessionEnd'] is DateTime
              ? fields['sessionEnd'] as DateTime
              : DateTime.parse(fields['sessionEnd'].toString()),
          timezone: 'UTC',
          isLate: fields['isLate'] == 1,
          status: fields['status']?.toString() ?? '0',
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Fix inconsistent sessions (sessions with status '1' but have sessionEnd)
  static Future<void> fixInconsistentSessions() async {
    try {
      const sql = '''
        UPDATE LoginHistory 
        SET status = '0' 
        WHERE status = '1' AND sessionEnd IS NOT NULL
      ''';

      final result = await _db.query(sql);
      final affectedRows = result.affectedRows ?? 0;

      if (affectedRows > 0) {
        print(
            '🔧 Fixed $affectedRows inconsistent sessions (status=1 but has sessionEnd)');
        // Clear all caches since session states changed
        _sessionCache.clear();
        _lastCheckTime.clear();
      } else {
        print('🔧 No inconsistent sessions found to fix');
      }
    } catch (e) {
      print('❌ Error fixing inconsistent sessions: $e');
    }
  }

  /// Auto-end all active sessions at 6:10 PM
  static Future<void> autoEndSessions() async {
    try {
      if (!shouldAutoEndSessions()) {
        print(
            '⏰ Not yet time to auto-end sessions (current time: ${getNairobiTime()})');
        return;
      }

      const sql = '''
        UPDATE LoginHistory 
        SET logoutAt = ?, sessionEnd = ?, status = '0'
        WHERE status = '1' AND sessionEnd IS NULL
      ''';

      final now = getNairobiTime();
      final nowString = _formatDateTime(now);

      final result = await _db.query(sql, [nowString, nowString]);

      final affectedRows = result.affectedRows ?? 0;
      if (affectedRows > 0) {
        // Clear all caches since session states changed
        _sessionCache.clear();
        _lastCheckTime.clear();
        print('⏰ Auto-ended $affectedRows active sessions');
      } else {
        print('⏰ No active sessions to auto-end');
      }
    } catch (e) {
      print('❌ Error auto-ending sessions: $e');
    }
  }

  /// Get session statistics
  static Future<Map<String, dynamic>> getSessionStats(
    int salesRepId, {
    String? startDate,
    String? endDate,
  }) async {
    try {
      String sql = '''
        SELECT 
          COUNT(*) as totalSessions,
          AVG(TIMESTAMPDIFF(MINUTE, loginAt, COALESCE(logoutAt, NOW()))) as avgDuration,
          SUM(CASE WHEN isLate = 1 THEN 1 ELSE 0 END) as lateSessions,
          SUM(CASE WHEN status = '1' THEN 1 ELSE 0 END) as activeSessions,
          SUM(CASE WHEN status = '0' THEN 1 ELSE 0 END) as inactiveSessions,
          SUM(CASE WHEN sessionStart IS NOT NULL AND sessionEnd IS NOT NULL THEN 1 ELSE 0 END) as completeSessions
        FROM LoginHistory 
        WHERE userId = ?
      ''';

      final params = <dynamic>[salesRepId];

      if (startDate != null && endDate != null) {
        sql += ' AND DATE(loginAt) BETWEEN ? AND ?';
        params.addAll([startDate, endDate]);
      }

      final results = await _db.query(sql, params);

      if (results.isEmpty) {
        return {
          'totalSessions': 0,
          'avgDuration': 0,
          'lateSessions': 0,
          'activeSessions': 0,
          'inactiveSessions': 0,
          'completeSessions': 0,
        };
      }

      final fields = results.first.fields;
      return {
        'totalSessions': fields['totalSessions'] ?? 0,
        'avgDuration': (fields['avgDuration'] ?? 0).toDouble(),
        'lateSessions': fields['lateSessions'] ?? 0,
        'activeSessions': fields['activeSessions'] ?? 0,
        'inactiveSessions': fields['inactiveSessions'] ?? 0,
        'completeSessions': fields['completeSessions'] ?? 0,
      };
    } catch (e) {
      return {
        'totalSessions': 0,
        'avgDuration': 0,
        'lateSessions': 0,
        'activeSessions': 0,
        'inactiveSessions': 0,
        'completeSessions': 0,
      };
    }
  }
}
