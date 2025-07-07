import 'package:woosh/models/journeyplan/report/report_model.dart';
import 'package:woosh/models/client_model.dart';
import 'package:woosh/services/database_service.dart';
import 'package:woosh/services/core/foreign_key_validation_service.dart';
import 'report_service.dart';

/// Service for handling feedback report operations
class FeedbackReportService {
  static final DatabaseService _db = DatabaseService.instance;

  /// Submit a feedback report with foreign key validation
  static Future<Report> submitFeedbackReport({
    required int journeyPlanId,
    required int clientId,
    required String comment,
    int? userId,
  }) async {
    try {
      // Get validated user ID
      final validatedUserId = userId ??
          await ForeignKeyValidationService.getCurrentUserIdValidated();
      if (validatedUserId == null) {
        throw Exception('Invalid user ID');
      }

      // Validate all foreign keys before proceeding
      await ForeignKeyValidationService.validateAndThrow(
        userId: validatedUserId,
        clientId: clientId,
        journeyPlanId: journeyPlanId,
      );

      print('✅ Foreign key validation passed for FeedbackReport submission');

      // Start transaction
      await _db.query('START TRANSACTION');

      try {
        // 1. Create main report record
        const reportSql = '''
          INSERT INTO Report (
            journeyPlanId, clientId, userId, type, createdAt
          ) VALUES (?, ?, ?, 'FEEDBACK', NOW())
        ''';

        final reportResult = await _db.query(reportSql, [
          journeyPlanId,
          clientId,
          validatedUserId,
        ]);

        final reportId = reportResult.insertId;
        if (reportId == null) {
          throw Exception('Failed to create report');
        }

        // 2. Create feedback report record
        const feedbackSql = '''
          INSERT INTO FeedbackReport (
            reportId, clientId, comment, userId, createdAt
          ) VALUES (?, ?, ?, ?, ?)
        ''';

        await _db.query(feedbackSql, [
          reportId,
          clientId,
          comment,
          validatedUserId,
          DateTime.now().toIso8601String()
        ]);

        // Commit transaction
        await _db.query('COMMIT');

        print('✅ FeedbackReport submitted successfully');

        // Return simple success report without fetching from database
        return Report(
          id: reportId,
          type: ReportType.FEEDBACK,
          journeyPlanId: journeyPlanId,
          salesRepId: validatedUserId,
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
        print('❌ Transaction rolled back due to error: $e');
        rethrow;
      }
    } catch (e) {
      print('❌ Error submitting feedback report: $e');

      // Provide more specific error messages
      if (e.toString().contains('Foreign key validation failed')) {
        throw Exception(
            'Invalid data provided. Please check user, client, and journey plan IDs.');
      } else if (e.toString().contains('User not authenticated')) {
        throw Exception('Please log in again to submit reports.');
      } else {
        rethrow;
      }
    }
  }

  /// Update feedback report comment
  static Future<bool> updateFeedbackReport({
    required int reportId,
    required String comment,
    int? userId,
  }) async {
    try {
      final validatedUserId = userId ??
          await ForeignKeyValidationService.getCurrentUserIdValidated();
      if (validatedUserId == null) {
        throw Exception('Invalid user ID');
      }

      const sql = '''
        UPDATE FeedbackReport 
        SET comment = ?
        WHERE reportId = ? AND userId = ?
      ''';

      final result = await _db.query(sql, [comment, reportId, validatedUserId]);
      print('✅ FeedbackReport updated successfully');
      return result.affectedRows! > 0;
    } catch (e) {
      print('❌ Error updating feedback report: $e');
      return false;
    }
  }
}
