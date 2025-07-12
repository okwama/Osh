import 'package:woosh/models/journeyplan/report/report_model.dart';
import 'package:woosh/models/journeyplan/report/feedbackReport_model.dart';
import 'package:woosh/models/journeyplan/report/productReport_model.dart';
import 'package:woosh/models/journeyplan/report/visibilityReport_model.dart';
import 'package:woosh/models/journeyplan/report/product_return_item_model.dart';
import 'package:woosh/models/journeyplan/report/product_sample_item_model.dart';

/// Factory class for creating different types of reports
class ReportFactory {
  /// Create a product availability report
  static Report createProductReport({
    required int journeyPlanId,
    required int salesRepId,
    required int clientId,
    required String productName,
    int quantity = 0,
    String comment = '',
  }) {
    return Report(
      type: ReportType.PRODUCT_AVAILABILITY,
      journeyPlanId: journeyPlanId,
      salesRepId: salesRepId,
      clientId: clientId,
      productReport: ProductReport(
        reportId: 0, // Placeholder ID that will be replaced by the backend
        productName: productName,
        quantity: quantity,
        comment: comment,
      ),
    );
  }

  /// Create a visibility activity report
  static Report createVisibilityReport({
    required int journeyPlanId,
    required int salesRepId,
    required int clientId,
    required String comment,
    String? imageUrl,
  }) {
    return Report(
      type: ReportType.VISIBILITY_ACTIVITY,
      journeyPlanId: journeyPlanId,
      salesRepId: salesRepId,
      clientId: clientId,
      visibilityReport: VisibilityReport(
        reportId: 0, // Placeholder ID that will be replaced by the backend
        comment: comment,
        imageUrl: imageUrl,
      ),
    );
  }

  /// Create a feedback report
  static Report createFeedbackReport({
    required int journeyPlanId,
    required int salesRepId,
    required int clientId,
    required String comment,
  }) {
    return Report(
      type: ReportType.FEEDBACK,
      journeyPlanId: journeyPlanId,
      salesRepId: salesRepId,
      clientId: clientId,
      feedbackReport: FeedbackReport(
        reportId: 0, // Placeholder ID that will be replaced by the backend
        comment: comment,
      ),
    );
  }

  /// Create a product return report
  static Report createProductReturnReport({
    required int journeyPlanId,
    required int salesRepId,
    required int clientId,
    required List<Map<String, dynamic>> items,
    String? reason,
  }) {
    return Report(
      type: ReportType.PRODUCT_RETURN,
      journeyPlanId: journeyPlanId,
      salesRepId: salesRepId,
      clientId: clientId,
      productReturnItems:
          items.map((item) => ProductReturnItem.fromJson(item)).toList(),
    );
  }

  /// Create a product sample report
  static Report createProductSampleReport({
    required int journeyPlanId,
    required int salesRepId,
    required int clientId,
    required List<Map<String, dynamic>> items,
    String? reason,
  }) {
    return Report(
      type: ReportType.PRODUCT_SAMPLE,
      journeyPlanId: journeyPlanId,
      salesRepId: salesRepId,
      clientId: clientId,
      productSampleItems:
          items.map((item) => ProductSampleItem.fromJson(item)).toList(),
    );
  }
}
