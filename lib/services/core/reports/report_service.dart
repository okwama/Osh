import 'package:woosh/models/journeyplan/report/report_model.dart';
import 'package:woosh/models/client_model.dart';
import 'package:woosh/models/salerep/sales_rep_model.dart';
import 'package:woosh/services/database_service.dart';

/// Main report service that orchestrates all report operations
class ReportService {
  static final DatabaseService _db = DatabaseService.instance;

  /// Get reports with pagination and filtering (simplified - only essential data)
  static Future<List<Report>> getReports({
    int page = 1,
    int limit = 20,
    int? journeyPlanId,
    int? clientId,
    int? userId,
    ReportType? type,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      String sql = '''
        SELECT 
          r.id,
          r.type,
          r.journeyPlanId,
          r.userId as salesRepId,
          r.clientId,
          r.createdAt
        FROM Report r
        WHERE 1=1
      ''';

      List<dynamic> params = [];

      // Filter by journey plan
      if (journeyPlanId != null) {
        sql += ' AND r.journeyPlanId = ?';
        params.add(journeyPlanId);
      }

      // Filter by client
      if (clientId != null) {
        sql += ' AND r.clientId = ?';
        params.add(clientId);
      }

      // Filter by user (default to current user if not specified)
      final filterUserId = userId ?? _db.getCurrentUserId();
      sql += ' AND r.userId = ?';
      params.add(filterUserId);

      // Filter by report type
      if (type != null) {
        sql += ' AND r.type = ?';
        params.add(type.toString().split('.').last);
      }

      // Filter by date range
      if (startDate != null) {
        sql += ' AND DATE(r.createdAt) >= DATE(?)';
        params.add(startDate.toIso8601String());
      }

      if (endDate != null) {
        sql += ' AND DATE(r.createdAt) <= DATE(?)';
        params.add(endDate.toIso8601String());
      }

      sql += ' ORDER BY r.createdAt DESC LIMIT ? OFFSET ?';
      params.add(limit);
      params.add((page - 1) * limit);

      final results = await _db.query(sql, params);

      return results.map((row) => _mapToSimpleReport(row.fields)).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get a specific report by ID (simplified)
  static Future<Report?> getReportById(int reportId) async {
    try {
      const sql = '''
        SELECT 
          r.id,
          r.type,
          r.journeyPlanId,
          r.userId as salesRepId,
          r.clientId,
          r.createdAt
        FROM Report r
        WHERE r.id = ?
      ''';

      final results = await _db.query(sql, [reportId]);

      if (results.isNotEmpty) {
        return _mapToSimpleReport(results.first.fields);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  /// Get reports for a specific journey plan
  static Future<List<Report>> getReportsByJourneyPlan(int journeyPlanId) async {
    return getReports(journeyPlanId: journeyPlanId, limit: 100);
  }

  /// Get reports for a specific client
  static Future<List<Report>> getReportsByClient(int clientId) async {
    return getReports(clientId: clientId, limit: 100);
  }

  /// Get reports by type
  static Future<List<Report>> getReportsByType(ReportType type) async {
    return getReports(type: type, limit: 100);
  }

  /// Update report status (simplified)
  static Future<bool> updateReportStatus(int reportId, String status) async {
    try {
      const sql = '''
        UPDATE Report 
        SET status = ?
        WHERE id = ?
      ''';

      final result = await _db.query(sql, [status, reportId]);
      return result.affectedRows! > 0;
    } catch (e) {
      return false;
    }
  }

  /// Delete a report
  static Future<bool> deleteReport(int reportId) async {
    try {
      const sql = 'DELETE FROM Report WHERE id = ?';
      final result = await _db.query(sql, [reportId]);
      return result.affectedRows! > 0;
    } catch (e) {
      return false;
    }
  }

  /// Helper method to map database row to Report (simplified with minimal data)
  static Report _mapToSimpleReport(Map<String, dynamic> row) {
    // Create minimal client object with just ID
    final client = Client(
      id: row['clientId'] ?? 0,
      name: 'Client',
      address: '',
      contact: '',
      email: '',
      latitude: null,
      longitude: null,
      balance: null,
      taxPin: '',
      location: '',
      clientType: null,
      regionId: 0,
      region: '',
      countryId: 0,
    );

    // Parse report type
    final typeString = row['type'] ?? '';
    final type = ReportType.values.firstWhere(
      (e) => e.toString().split('.').last == typeString,
      orElse: () => ReportType.FEEDBACK,
    );

    return Report(
      id: row['id'],
      type: type,
      journeyPlanId: row['journeyPlanId'],
      salesRepId: row['salesRepId'],
      clientId: row['clientId'],
      createdAt:
          row['createdAt'] != null ? DateTime.parse(row['createdAt']) : null,
      updatedAt: null,
      client: client,
      user: null,
    );
  }
}