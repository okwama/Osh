import 'package:woosh/models/journeyplan/report/report_model.dart';
import 'package:woosh/models/journeyplan/report/product_sample_item_model.dart';
import 'package:woosh/models/journeyplan/report/productSample_model.dart';
import 'package:woosh/models/client/client_model.dart';
import 'package:woosh/services/database_service.dart';
import 'report_service.dart';

/// Service for handling product sample report operations
class ProductSampleService {
  static final DatabaseService _db = DatabaseService.instance;

  /// Submit a product sample report
  static Future<Report> submitProductSampleReport({
    required int journeyPlanId,
    required int clientId,
    required List<ProductSampleItem> productSampleItems,
    int? userId,
  }) async {
    try {
      final filterUserId = userId ?? await _db.getCurrentUserId();

      // Start transaction
      await _db.query('START TRANSACTION');

      try {
        // 1. Create main report record
        const reportSql = '''
          INSERT INTO Report (
            journeyPlanId, clientId, userId, type, createdAt
          ) VALUES (?, ?, ?, 'PRODUCT_SAMPLE', NOW())
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

        // 2. Create product sample record (header only - product details go in ProductsSampleItem)
        const sampleSql = '''
          INSERT INTO ProductsSample (
            reportId, productName, quantity, reason, status, clientId, userId
          ) VALUES (?, NULL, NULL, NULL, ?, ?, ?)
        ''';

        final sampleResult = await _db.query(sampleSql, [
          reportId,
          0, // status
          clientId,
          filterUserId
        ]);
        final productSampleId = sampleResult.insertId;

        // 3. Create product sample item records
        const itemSql = '''
          INSERT INTO ProductsSampleItem (
            productsSampleId, productName, quantity, reason, clientId, userId
          ) VALUES (?, ?, ?, ?, ?, ?)
        ''';

        for (final item in productSampleItems) {
          await _db.query(itemSql, [
            productSampleId,
            item.productName,
            item.quantity,
            item.reason,
            clientId,
            filterUserId,
          ]);
        }

        // Commit transaction
        await _db.query('COMMIT');

        // Return simple success report without fetching from database
        return Report(
          id: reportId,
          type: ReportType.PRODUCT_SAMPLE,
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

  /// Update product sample status
  static Future<bool> updateProductSampleStatus({
    required int reportId,
    required int status,
    int? userId,
  }) async {
    try {
      final filterUserId = userId ?? await _db.getCurrentUserId();

      const sql = '''
        UPDATE ProductsSample 
        SET status = ? 
        WHERE reportId = ? AND userId = ?
      ''';

      final result = await _db.query(sql, [status, reportId, filterUserId]);
      return result.affectedRows! > 0;
    } catch (e) {
      return false;
    }
  }

  /// Update product sample item
  static Future<bool> updateProductSampleItem({
    required int productsSampleId,
    required String productName,
    required int quantity,
    required String reason,
    int? userId,
  }) async {
    try {
      final filterUserId = userId ?? await _db.getCurrentUserId();

      const sql = '''
        UPDATE ProductsSampleItem 
        SET quantity = ?, reason = ?
        WHERE productsSampleId = ? AND productName = ? AND userId = ?
      ''';

      final result = await _db.query(
          sql, [quantity, reason, productsSampleId, productName, filterUserId]);
      return result.affectedRows! > 0;
    } catch (e) {
      return false;
    }
  }

  /// Get product samples by journey plan for controller
  static Future<List<Report>> getProductSamplesByJourneyPlan(
      int journeyPlanId) async {
    try {
      const sql = '''
        SELECT r.id
        FROM Report r
        JOIN ProductsSample ps ON r.id = ps.reportId
        WHERE r.type = 'PRODUCT_SAMPLE' 
        AND r.journeyPlanId = ?
        ORDER BY r.createdAt DESC
      ''';

      final results = await _db.query(sql, [journeyPlanId]);
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

  /// Submit product sample for controller
  static Future<Report> submitProductSample({
    required int journeyPlanId,
    required int clientId,
    required List<ProductSample> productSamples,
    int? userId,
  }) async {
    try {
      // Convert ProductSample to ProductSampleItem for the service
      final productSampleItems = productSamples
          .map((ps) => ProductSampleItem(
                productName: ps.productName ?? '',
                quantity: ps.quantity ?? 0,
                reason: ps.reason ?? '',
              ))
          .toList();

      // Submit using existing service method
      final report = await submitProductSampleReport(
        journeyPlanId: journeyPlanId,
        clientId: clientId,
        productSampleItems: productSampleItems,
        userId: userId,
      );

      return report;
    } catch (e) {
      rethrow;
    }
  }
}
