import 'package:woosh/models/journeyplan/report/report_model.dart';
import 'package:woosh/models/journeyplan/report/feedbackReport_model.dart';
import 'package:woosh/models/journeyplan/report/productReport_model.dart';
import 'package:woosh/models/journeyplan/report/product_return_item_model.dart';
import 'package:woosh/models/journeyplan/report/product_sample_item_model.dart';
import 'package:woosh/models/journeyplan/report/visibilityReport_model.dart';
import 'package:woosh/models/journeyplan/report/productReturn_model.dart';
import 'package:woosh/models/journeyplan/report/productSample_model.dart';
import 'package:woosh/models/salerep/sales_rep_model.dart';
import 'package:woosh/models/client/client_model.dart';

/// Mixin containing all display-related getters and methods for Report class
mixin ReportDisplayMixin {
  // Core display getters
  String get displayId;
  String get displayType;
  String get displayJourneyPlanId;
  String get displaySalesRepId;
  String get displayOrderId;
  String get displayClientId;
  String get displayCreatedAt;
  String get displayUpdatedAt;

  // User and client display info
  String get displayUserName;
  String get displayUserEmail;
  String get displayUserPhone;
  String get displayClientName;
  String get displayClientLocation;

  // Report specific display info
  String get displayComment;
  String? get displayImageUrl;

  // Product return items display
  List<Map<String, String>> get displayProductReturnItems;

  // Product sample items display
  List<Map<String, String>> get displayProductSampleItems;

  // Product availability display
  Map<String, String> get displayProductAvailability;

  // Visibility activity display
  Map<String, String> get displayVisibilityActivity;

  // Feedback display
  Map<String, String> get displayFeedback;

  // Product return display
  Map<String, dynamic> get displayProductReturn;

  // Product sample display
  Map<String, dynamic> get displayProductSample;

  // Get all display data as a map
  Map<String, dynamic> get displayData;
}

/// Implementation of ReportDisplayMixin
class ReportDisplayHelper {
  static String getDisplayId(int? id) => id?.toString() ?? 'N/A';

  static String getDisplayType(ReportType type) =>
      type.toString().split('.').last.replaceAll('_', ' ');

  static String getDisplayJourneyPlanId(int? journeyPlanId) =>
      journeyPlanId?.toString() ?? 'N/A';

  static String getDisplaySalesRepId(int salesRepId) => salesRepId.toString();

  static String getDisplayOrderId() => 'N/A';

  static String getDisplayClientId(int clientId) => clientId.toString();

  static String getDisplayCreatedAt(DateTime? createdAt) =>
      createdAt?.toLocal().toString() ?? 'N/A';

  static String getDisplayUpdatedAt(DateTime? updatedAt) =>
      updatedAt?.toLocal().toString() ?? 'N/A';

  // User and client display info
  static String getDisplayUserName(SalesRepModel? user) =>
      user?.name ?? 'Unknown User';
  static String getDisplayUserEmail(SalesRepModel? user) =>
      user?.email ?? 'No Email';
  static String getDisplayUserPhone(SalesRepModel? user) =>
      user?.phoneNumber ?? 'No Phone';
  static String getDisplayClientName(Client? client) =>
      client?.name ?? 'Unknown Client';
  static String getDisplayClientLocation(Client? client) =>
      client?.location ?? 'No Location';

  // Report specific display info
  static String getDisplayComment(
    ReportType type, {
    ProductReport? productReport,
    VisibilityReport? visibilityReport,
    FeedbackReport? feedbackReport,
    ProductReturn? productReturn,
    ProductSample? productSample,
  }) {
    switch (type) {
      case ReportType.PRODUCT_AVAILABILITY:
        return productReport?.comment ?? 'No comment';
      case ReportType.VISIBILITY_ACTIVITY:
        return visibilityReport?.comment ?? 'No comment';
      case ReportType.FEEDBACK:
        return feedbackReport?.comment ?? 'No comment';
      case ReportType.PRODUCT_RETURN:
        return productReturn?.reason ?? 'No reason provided';
      case ReportType.PRODUCT_SAMPLE:
        return productSample?.reason ?? 'No reason provided';
      default:
        return 'No comment';
    }
  }

  // Getter to access the report image URL if available
  static String? getDisplayImageUrl(
      ReportType type, VisibilityReport? visibilityReport) {
    switch (type) {
      case ReportType.VISIBILITY_ACTIVITY:
        return visibilityReport?.imageUrl;
      default:
        return null;
    }
  }

  // Product return items display
  static List<Map<String, String>> getDisplayProductReturnItems(
      List<ProductReturnItem>? productReturnItems) {
    if (productReturnItems == null || productReturnItems.isEmpty) {
      return [
        {'message': 'No return items'}
      ];
    }
    return productReturnItems
        .map((item) => {
              'product': item.productName ?? 'Unknown Product',
              'quantity': item.quantity?.toString() ?? '0',
              'reason': item.reason ?? 'No reason provided',
            })
        .toList();
  }

  // Product sample items display
  static List<Map<String, String>> getDisplayProductSampleItems(
      List<ProductSampleItem>? productSampleItems) {
    if (productSampleItems == null || productSampleItems.isEmpty) {
      return [
        {'message': 'No sample items'}
      ];
    }
    return productSampleItems
        .map((item) => {
              'product': item.productName ?? 'Unknown Product',
              'quantity': item.quantity?.toString() ?? '0',
              'reason': item.reason ?? 'No reason provided',
            })
        .toList();
  }

  // Product availability display
  static Map<String, String> getDisplayProductAvailability(
      ProductReport? productReport) {
    if (productReport == null) {
      return {
        'product': 'No product data',
        'quantity': 'N/A',
        'comment': 'No comment'
      };
    }
    return {
      'product': productReport.productName ?? 'Unknown Product',
      'quantity': productReport.quantity?.toString() ?? '0',
      'comment': productReport.comment ?? 'No comment'
    };
  }

  // Visibility activity display
  static Map<String, String> getDisplayVisibilityActivity(
      VisibilityReport? visibilityReport) {
    if (visibilityReport == null) {
      return {'comment': 'No visibility data', 'image': 'No image'};
    }
    return {
      'comment': visibilityReport.comment ?? 'No comment',
      'image': visibilityReport.imageUrl ?? 'No image'
    };
  }

  // Feedback display
  static Map<String, String> getDisplayFeedback(
      FeedbackReport? feedbackReport) {
    if (feedbackReport == null) {
      return {'comment': 'No feedback data'};
    }
    return {'comment': feedbackReport.comment ?? 'No comment'};
  }

  // Product return display
  static Map<String, dynamic> getDisplayProductReturn(
      ProductReturn? productReturn,
      List<ProductReturnItem>? productReturnItems) {
    if (productReturn == null) {
      return {
        'reason': 'No return data',
        'items': [
          {'message': 'No return items'}
        ]
      };
    }
    return {
      'reason': productReturn.reason ?? 'No reason provided',
      'items': getDisplayProductReturnItems(productReturnItems)
    };
  }

  // Product sample display
  static Map<String, dynamic> getDisplayProductSample(
      ProductSample? productSample,
      List<ProductSampleItem>? productSampleItems) {
    if (productSample == null) {
      return {
        'reason': 'No sample data',
        'items': [
          {'message': 'No sample items'}
        ]
      };
    }
    return {
      'reason': productSample.reason ?? 'No reason provided',
      'items': getDisplayProductSampleItems(productSampleItems)
    };
  }

  // Get all display data as a map
  static Map<String, dynamic> getDisplayData({
    required int? id,
    required ReportType type,
    required int? journeyPlanId,
    required int salesRepId,
    required int clientId,
    required DateTime? createdAt,
    required DateTime? updatedAt,
    required SalesRepModel? user,
    required Client? client,
    required String displayComment,
    required String? displayImageUrl,
    required Map<String, dynamic> specificData,
  }) {
    return {
      'id': getDisplayId(id),
      'type': getDisplayType(type),
      'journeyPlanId': getDisplayJourneyPlanId(journeyPlanId),
      'salesRepId': getDisplaySalesRepId(salesRepId),
      'orderId': getDisplayOrderId(),
      'clientId': getDisplayClientId(clientId),
      'createdAt': getDisplayCreatedAt(createdAt),
      'updatedAt': getDisplayUpdatedAt(updatedAt),
      'user': {
        'name': getDisplayUserName(user),
        'email': getDisplayUserEmail(user),
        'phone': getDisplayUserPhone(user),
      },
      'client': {
        'name': getDisplayClientName(client),
        'location': getDisplayClientLocation(client),
      },
      'comment': displayComment,
      'imageUrl': displayImageUrl,
      'specificData': specificData,
    };
  }

  static Map<String, dynamic> getSpecificDisplayData(
    ReportType type, {
    ProductReport? productReport,
    VisibilityReport? visibilityReport,
    FeedbackReport? feedbackReport,
    ProductReturn? productReturn,
    ProductSample? productSample,
    List<ProductReturnItem>? productReturnItems,
    List<ProductSampleItem>? productSampleItems,
  }) {
    switch (type) {
      case ReportType.PRODUCT_AVAILABILITY:
        return {
          'productAvailability': getDisplayProductAvailability(productReport)
        };
      case ReportType.VISIBILITY_ACTIVITY:
        return {
          'visibilityActivity': getDisplayVisibilityActivity(visibilityReport)
        };
      case ReportType.FEEDBACK:
        return {'feedback': getDisplayFeedback(feedbackReport)};
      case ReportType.PRODUCT_RETURN:
        return {
          'productReturn':
              getDisplayProductReturn(productReturn, productReturnItems)
        };
      case ReportType.PRODUCT_SAMPLE:
        return {
          'productSample':
              getDisplayProductSample(productSample, productSampleItems)
        };
      default:
        return {'message': 'Unknown report type'};
    }
  }
}
