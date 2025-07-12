import 'package:woosh/models/journeyplan/report/report_model.dart';
import 'package:woosh/models/client/client_model.dart';
import 'package:woosh/services/database_service.dart';
import 'report_service.dart';

/// Service for handling visibility activity report operations
class VisibilityReportService {
  static final DatabaseService _db = DatabaseService.instance;

  /// Submit a visibility activity report
  static Future<Report> submitVisibilityReport({
    required int journeyPlanId,
    required int clientId,
    required String comment,
    String? imageUrl,
    int? userId,
  }) async {
    try {
      final filterUserId = userId ?? _db.getCurrentUserId();

      // Start transaction
      await _db.query('START TRANSACTION');

      try {
        // 1. Create main report record
        const reportSql = '''
          INSERT INTO Report (
            journeyPlanId, clientId, userId, type, createdAt
          ) VALUES (?, ?, ?, 'VISIBILITY_ACTIVITY', NOW())
        ''';

        final reportResult = await _db.query(reportSql, [
          journeyPlanId,
          clientId,
          filterUserId,
        ]);

        final reportId = reportResult.insertId;
        if (reportId == null) {
          throw Exception('Failed to create report');
        }

        // 2. Create visibility report record
        const visibilitySql = '''
          INSERT INTO VisibilityReport (
            reportId, clientId, comment, imageUrl, userId, createdAt
          ) VALUES (?, ?, ?, ?, ?, ?)
        ''';

        await _db.query(visibilitySql, [
          reportId,
          clientId,
          comment,
          imageUrl,
          filterUserId,
          DateTime.now().toIso8601String()
        ]);

        // Commit transaction
        await _db.query('COMMIT');


        // Return simple success report without fetching from database
        return Report(
          id: reportId,
          type: ReportType.VISIBILITY_ACTIVITY,
          journeyPlanId: journeyPlanId,
          salesRepId: filterUserId,
          clientId: clientId,
          createdAt: DateTime.now(),
          updatedAt: null,
          client: Client(
            id: clientId,
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
          ),
          user: null,
        );
      } catch (e) {
        // Rollback transaction
        await _db.query('ROLLBACK');
        rethrow;
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Update visibility report comment/image
  static Future<bool> updateVisibilityReport({
    required int reportId,
    String? comment,
    String? imageUrl,
    int? userId,
  }) async {
    try {
      final filterUserId = userId ?? _db.getCurrentUserId();

      final updates = <String>[];
      final params = <dynamic>[];

      if (comment != null) {
        updates.add('comment = ?');
        params.add(comment);
      }

      if (imageUrl != null) {
        updates.add('imageUrl = ?');
        params.add(imageUrl);
      }

      if (updates.isEmpty) {
        throw Exception('No fields to update');
      }

      final sql = '''
        UPDATE VisibilityReport 
        SET ${updates.join(', ')}
        WHERE reportId = ? AND userId = ?
      ''';
      params.addAll([reportId, filterUserId]);

      final result = await _db.query(sql, params);
      return result.affectedRows! > 0;
    } catch (e) {
      return false;
    }
  }
}