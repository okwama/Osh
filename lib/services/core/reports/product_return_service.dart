import 'package:woosh/models/journeyplan/report/report_model.dart';
import 'package:woosh/models/journeyplan/report/product_return_item_model.dart';
import 'package:woosh/services/database_service.dart';
import 'report_service.dart';

/// Service for handling product return report operations
class ProductReturnService {
  static final DatabaseService _db = DatabaseService.instance;

  /// Submit a product return report
  static Future<Report> submitProductReturnReport({
    required int clientId,
    required List<ProductReturnItem> productReturnItems,
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
            clientId, userId, type, createdAt
          ) VALUES (?, ?, 'PRODUCT_RETURN', NOW())
        ''';

        final reportResult = await _db.query(reportSql, [
          clientId,
          filterUserId,
        ]);

        final reportId = reportResult.insertId;
        if (reportId == null) {
          throw Exception('Failed to create report');
        }

        // 2. Create product return record
        const returnSql = '''
          INSERT INTO ProductReturn (
            reportId, status, createdAt
          ) VALUES (?, 0, NOW())
        ''';

        final returnResult = await _db.query(returnSql, [reportId]);
        final productReturnId = returnResult.insertId;

        // 3. Create product return item records
        const itemSql = '''
          INSERT INTO ProductReturnItem (
            productReturnId, productName, quantity, reason, imageUrl
          ) VALUES (?, ?, ?, ?, ?)
        ''';

        for (final item in productReturnItems) {
          await _db.query(itemSql, [
            productReturnId,
            item.productName,
            item.quantity,
            item.reason,
            item.imageUrl,
          ]);
        }

        // Commit transaction
        await _db.query('COMMIT');

        // Fetch the created report
        final createdReport = await ReportService.getReportById(reportId);
        if (createdReport == null) {
          throw Exception('Failed to fetch created report');
        }
        return createdReport;
      } catch (e) {
        // Rollback transaction
        await _db.query('ROLLBACK');
        rethrow;
      }
    } catch (e) {
      print('❌ Error submitting product return report: $e');
      rethrow;
    }
  }

  /// Get product return reports for a specific client
  static Future<List<Report>> getProductReturnReportsByClient(
      int clientId) async {
    return ReportService.getReports(
      clientId: clientId,
      type: ReportType.PRODUCT_RETURN,
      limit: 100,
    );
  }

  /// Get product return reports by status
  static Future<List<Report>> getProductReturnReportsByStatus(
      int status) async {
    try {

      const sql = '''
        SELECT r.id
        FROM Report r
        JOIN ProductReturn pr ON r.id = pr.reportId
        WHERE r.type = 'PRODUCT_RETURN' 
        AND pr.status = ?
        ORDER BY r.createdAt DESC
      ''';

      final results = await _db.query(sql, [status]);
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
      print('❌ Error fetching product return reports by status: $e');
      rethrow;
    }
  }

  /// Update product return status
  static Future<void> updateProductReturnStatus(
      int reportId, int status) async {
    try {

      const sql = '''
        UPDATE ProductReturn 
        SET status = ? 
        WHERE reportId = ?
      ''';

      await _db.query(sql, [status, reportId]);
    } catch (e) {
      print('❌ Error updating product return status: $e');
      rethrow;
    }
  }
}
