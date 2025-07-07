import 'package:woosh/models/journeyplan/report/report_model.dart';
import 'package:woosh/models/journeyplan/report/productReport_model.dart';
import 'package:woosh/models/client_model.dart';
import 'package:woosh/services/database_service.dart';
import 'package:woosh/services/core/foreign_key_validation_service.dart';
import 'report_service.dart';

/// Service for handling product availability report operations
class ProductReportService {
  static final DatabaseService _db = DatabaseService.instance;

  /// Submit a product availability report with foreign key validation
  static Future<Report> submitProductReport({
    required int journeyPlanId,
    required int clientId,
    required List<ProductReport> productReports,
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


      // Start transaction
      await _db.query('START TRANSACTION');

      try {
        // 1. Create main report record
        const reportSql = '''
          INSERT INTO Report (
            journeyPlanId, clientId, userId, type, createdAt
          ) VALUES (?, ?, ?, 'PRODUCT_AVAILABILITY', NOW())
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

        // 2. Create product report records
        const productSql = '''
          INSERT INTO ProductReport (
            reportId, productName, quantity, comment, clientId, userId, createdAt
          ) VALUES (?, ?, ?, ?, ?, ?, NOW())
        ''';

        for (final productReport in productReports) {
          await _db.query(productSql, [
            reportId,
            productReport.productName,
            productReport.quantity,
            productReport.comment,
            clientId,
            validatedUserId,
          ]);
        }

        // Commit transaction
        await _db.query('COMMIT');


        // Return a simple success report without fetching from database
        return Report(
          id: reportId,
          type: ReportType.PRODUCT_AVAILABILITY,
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
        rethrow;
      }
    } catch (e) {

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

  /// Get product availability reports for a specific journey plan
  static Future<List<Report>> getProductReportsByJourneyPlan(
      int journeyPlanId) async {
    try {
      // Validate journey plan ID
      final isValidJourneyPlan =
          await ForeignKeyValidationService.validateJourneyPlanId(
              journeyPlanId);
      if (!isValidJourneyPlan) {
        throw Exception('Invalid journey plan ID: $journeyPlanId');
      }

      return ReportService.getReports(
        journeyPlanId: journeyPlanId,
        type: ReportType.PRODUCT_AVAILABILITY,
        limit: 100,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Get product availability reports for a specific client
  static Future<List<Report>> getProductReportsByClient(int clientId) async {
    try {
      // Validate client ID
      final isValidClient =
          await ForeignKeyValidationService.validateClientId(clientId);
      if (!isValidClient) {
        throw Exception('Invalid client ID: $clientId');
      }

      return ReportService.getReports(
        clientId: clientId,
        type: ReportType.PRODUCT_AVAILABILITY,
        limit: 100,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Get product availability reports for a specific product
  static Future<List<Report>> getProductReportsByProduct(
      String productName) async {
    try {
      if (productName.isEmpty) {
        throw Exception('Product name cannot be empty');
      }

      const sql = '''
        SELECT r.id
        FROM Report r
        JOIN ProductReport pr ON r.id = pr.reportId
        WHERE r.type = 'PRODUCT_AVAILABILITY' 
        AND pr.productName = ?
        ORDER BY r.createdAt DESC
      ''';

      final results = await _db.query(sql, [productName]);
      final reportIds = results.map((row) => row.fields['id'] as int).toList();

      // Fetch full report details
      final reports = <Report>[];
      for (final reportId in reportIds) {
        final report = await ReportService.getReportById(reportId);
        if (report != null) {
          reports.add(report);
        }
      }

      return reports;
    } catch (e) {
      rethrow;
    }
  }

  /// Validate product report data before submission
  static Future<Map<String, dynamic>> validateProductReportData({
    required int journeyPlanId,
    required int clientId,
    required List<ProductReport> productReports,
    int? userId,
  }) async {
    try {
      final validatedUserId = userId ??
          await ForeignKeyValidationService.getCurrentUserIdValidated();

      final validations = await ForeignKeyValidationService.validateMultiple(
        userId: validatedUserId,
        clientId: clientId,
        journeyPlanId: journeyPlanId,
      );

      final failedValidations = validations.entries
          .where((entry) => !entry.value)
          .map((entry) => entry.key)
          .toList();

      return {
        'isValid': failedValidations.isEmpty,
        'failedValidations': failedValidations,
        'errorMessage': failedValidations.isEmpty
            ? null
            : ForeignKeyValidationService.getValidationErrorMessage(
                validations),
        'validatedUserId': validatedUserId,
      };
    } catch (e) {
      return {
        'isValid': false,
        'failedValidations': ['validation_error'],
        'errorMessage': 'Validation error: $e',
        'validatedUserId': null,
      };
    }
  }
}