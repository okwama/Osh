import 'package:woosh/models/journeyplan/report/report_model.dart';
import 'package:woosh/models/journeyplan/report/feedbackReport_model.dart';
import 'package:woosh/models/journeyplan/report/productReport_model.dart';
import 'package:woosh/models/journeyplan/report/visibilityReport_model.dart';
import 'package:woosh/models/journeyplan/report/productReturn_model.dart';
import 'package:woosh/models/journeyplan/report/productSample_model.dart';

/// Utility class for report-related operations
class ReportUtils {
  /// Parse report type from various input formats
  static ReportType parseReportType(dynamic type) {
    if (type == null) {
      throw Exception('Report type cannot be null');
    }

    // Handle both string and enum types
    String typeStr;
    if (type is String) {
      typeStr = type.toUpperCase().replaceAll(' ', '_');
    } else if (type is ReportType) {
      return type;
    } else {
      typeStr = type.toString().toUpperCase().replaceAll(' ', '_');
    }

    // Try exact match first
    switch (typeStr) {
      case 'PRODUCT_AVAILABILITY':
        return ReportType.PRODUCT_AVAILABILITY;
      case 'VISIBILITY_ACTIVITY':
        return ReportType.VISIBILITY_ACTIVITY;
      case 'FEEDBACK':
        return ReportType.FEEDBACK;
      case 'PRODUCT_RETURN':
        return ReportType.PRODUCT_RETURN;
      case 'PRODUCT_SAMPLE':
        return ReportType.PRODUCT_SAMPLE;
      default:
        // Try partial match for legacy data
        if (typeStr.contains('PRODUCT') && typeStr.contains('AVAILABILITY')) {
          return ReportType.PRODUCT_AVAILABILITY;
        } else if (typeStr.contains('VISIBILITY') &&
            typeStr.contains('ACTIVITY')) {
          return ReportType.VISIBILITY_ACTIVITY;
        } else if (typeStr.contains('FEEDBACK')) {
          return ReportType.FEEDBACK;
        } else if (typeStr.contains('PRODUCT') && typeStr.contains('RETURN')) {
          return ReportType.PRODUCT_RETURN;
        } else if (typeStr.contains('PRODUCT') && typeStr.contains('SAMPLE')) {
          return ReportType.PRODUCT_SAMPLE;
        }

        throw Exception('Unknown report type: $typeStr');
    }
  }

  /// Get the correct field name for specific report types
  static String getSpecificReportFieldName(ReportType type) {
    switch (type) {
      case ReportType.PRODUCT_AVAILABILITY:
        return 'productReport';
      case ReportType.VISIBILITY_ACTIVITY:
        return 'visibilityReport';
      case ReportType.FEEDBACK:
        return 'feedbackReport';
      case ReportType.PRODUCT_RETURN:
        return 'productReturn';
      case ReportType.PRODUCT_SAMPLE:
        return 'productSample';
      default:
        return '';
    }
  }

  /// Get the specific report JSON data based on type
  static Map<String, dynamic>? getSpecificReportJson(
    ReportType type, {
    ProductReport? productReport,
    VisibilityReport? visibilityReport,
    FeedbackReport? feedbackReport,
    ProductReturn? productReturn,
    ProductSample? productSample,
  }) {
    switch (type) {
      case ReportType.PRODUCT_AVAILABILITY:
        return productReport?.toJson();
      case ReportType.VISIBILITY_ACTIVITY:
        return visibilityReport?.toJson();
      case ReportType.FEEDBACK:
        return feedbackReport?.toJson();
      case ReportType.PRODUCT_RETURN:
        return productReturn?.toJson();
      case ReportType.PRODUCT_SAMPLE:
        return productSample?.toJson();
      default:
        return null;
    }
  }

  /// Get report comment based on type
  static String getReportComment(
    ReportType type, {
    ProductReport? productReport,
    VisibilityReport? visibilityReport,
    FeedbackReport? feedbackReport,
    ProductReturn? productReturn,
    ProductSample? productSample,
  }) {
    switch (type) {
      case ReportType.PRODUCT_AVAILABILITY:
        return productReport?.comment ?? '';
      case ReportType.VISIBILITY_ACTIVITY:
        return visibilityReport?.comment ?? '';
      case ReportType.FEEDBACK:
        return feedbackReport?.comment ?? '';
      case ReportType.PRODUCT_RETURN:
        return productReturn?.reason ?? '';
      case ReportType.PRODUCT_SAMPLE:
        return productSample?.reason ?? '';
      default:
        return '';
    }
  }
}
