import 'dart:convert';
import 'package:woosh/models/journeyplan/report/feedbackReport_model.dart';
import 'package:woosh/models/journeyplan/report/productReport_model.dart';
import 'package:woosh/models/journeyplan/report/product_return_item_model.dart';
import 'package:woosh/models/journeyplan/report/product_sample_item_model.dart';
import 'package:woosh/models/journeyplan/report/visibilityReport_model.dart';
import 'package:woosh/models/journeyplan/report/productReturn_model.dart';
import 'package:woosh/models/journeyplan/report/productSample_model.dart';
import 'package:woosh/models/salerep/sales_rep_model.dart';
import 'package:woosh/models/client_model.dart';

enum ReportType {
  PRODUCT_AVAILABILITY,
  VISIBILITY_ACTIVITY,
  FEEDBACK,
  PRODUCT_RETURN,
  PRODUCT_SAMPLE, // Added PRODUCT_SAMPLE
}

class Report {
  final int? id;
  final ReportType type;
  final int? journeyPlanId;
  final int salesRepId;
  final int clientId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final ProductReport? productReport; // For backward compatibility
  final List<ProductReport>? productReports; // New field for multiple products
  final VisibilityReport? visibilityReport;
  final FeedbackReport? feedbackReport;
  final List<ProductReturnItem>? productReturnItems;
  final List<ProductSampleItem>? productSampleItems;

  // Related reports
  final ProductReturn? productReturn;
  final ProductSample? productSample; // Added ProductSample

  final Client? client;
  final SalesRepModel? user; // Changed from User to SalesRep

  Report({
    this.id,
    required this.type,
    this.journeyPlanId,
    required this.salesRepId,
    required this.clientId,
    this.createdAt,
    this.updatedAt,
    this.productReport,
    this.productReports,
    this.visibilityReport,
    this.feedbackReport,
    this.productReturnItems,
    this.productSampleItems,
    this.productReturn,
    this.productSample, // Added ProductSample
    this.client,
    this.user, // Add user to constructor
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    final type = ReportType.values.firstWhere(
      (e) => e.toString().split('.').last == json['type'],
      orElse: () => ReportType.FEEDBACK,
    );

    // Handle product reports
    ProductReport? productReport;
    List<ProductReport>? productReports;

    if (json['specificReport'] != null) {
      if (type == ReportType.PRODUCT_AVAILABILITY) {
        if (json['specificReport'] is List) {
          final reports = (json['specificReport'] as List)
              .map((report) => ProductReport.fromJson(report))
              .toList();
          productReports = reports;
          productReport = reports.isNotEmpty ? reports.first : null;
        } else {
          productReport = ProductReport.fromJson(json['specificReport']);
          productReports = [productReport];
        }
      }
    }

    // Parse user data if available
    SalesRepModel? user;
    if (json['user'] != null) {
      user = SalesRepModel.fromMap(json['user']);
    }

    return Report(
      id: json['id'],
      type: type,
      journeyPlanId: json['journeyPlanId'],
      salesRepId: json['userId'] ?? json['salesRepId'] ?? 0,
      clientId: json['clientId'] ?? 0,
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      productReport: productReport,
      productReports: productReports,
      visibilityReport: json['specificReport'] != null &&
              type == ReportType.VISIBILITY_ACTIVITY
          ? VisibilityReport.fromJson(json['specificReport'])
          : null,
      feedbackReport:
          json['specificReport'] != null && type == ReportType.FEEDBACK
              ? FeedbackReport.fromJson(json['specificReport'])
              : null,
      productReturnItems:
          json['specificReport'] != null && type == ReportType.PRODUCT_RETURN
              ? (json['specificReport']['items'] as List)
                  .map((item) => ProductReturnItem.fromJson(item))
                  .toList()
              : null,
      productSampleItems:
          json['specificReport'] != null && type == ReportType.PRODUCT_SAMPLE
              ? (json['specificReport']['items'] as List)
                  .map((item) => ProductSampleItem.fromJson(item))
                  .toList()
              : null,
      user: user, // Add user to the Report object
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'type': type.toString().split('.').last,
      'journeyPlanId': journeyPlanId,
      'userId': salesRepId,
      'clientId': clientId,
    };

    if (id != null) data['id'] = id;
    if (createdAt != null) data['createdAt'] = createdAt!.toIso8601String();
    if (updatedAt != null) data['updatedAt'] = updatedAt!.toIso8601String();

    // Handle product reports
    if (type == ReportType.PRODUCT_AVAILABILITY) {
      if (productReports != null && productReports!.isNotEmpty) {
        data['details'] =
            productReports!.map((report) => report.toJson()).toList();
      } else if (productReport != null) {
        data['details'] = [productReport!.toJson()];
      }
    }

    // Handle other report types
    if (type == ReportType.VISIBILITY_ACTIVITY && visibilityReport != null) {
      data['details'] = visibilityReport!.toJson();
    } else if (type == ReportType.FEEDBACK && feedbackReport != null) {
      data['details'] = feedbackReport!.toJson();
    } else if (type == ReportType.PRODUCT_RETURN &&
        productReturnItems != null) {
      data['details'] = {
        'items': productReturnItems!.map((item) => item.toJson()).toList(),
      };
    } else if (type == ReportType.PRODUCT_SAMPLE &&
        productSampleItems != null) {
      data['details'] = {
        'items': productSampleItems!.map((item) => item.toJson()).toList(),
      };
    }

    return data;
  }

  Map<String, dynamic>? _getSpecificReportJson() {
    switch (type) {
      case ReportType.PRODUCT_AVAILABILITY:
        return productReport?.toJson();
      case ReportType.VISIBILITY_ACTIVITY:
        return visibilityReport?.toJson();
      case ReportType.FEEDBACK:
        return feedbackReport?.toJson();
      case ReportType.PRODUCT_RETURN:
        return productReturn?.toJson();
      case ReportType.PRODUCT_SAMPLE: // Added case for ProductSample
        return productSample?.toJson();
      default:
        return null;
    }
  }

  // Getter to access the report comment regardless of type
  String get comment {
    switch (type) {
      case ReportType.PRODUCT_AVAILABILITY:
        return productReport?.comment ?? '';
      case ReportType.VISIBILITY_ACTIVITY:
        return visibilityReport?.comment ?? '';
      case ReportType.FEEDBACK:
        return feedbackReport?.comment ?? '';
      case ReportType.PRODUCT_RETURN:
        return productReturn?.reason ?? '';
      case ReportType.PRODUCT_SAMPLE: // Added ProductSample comment
        return productSample?.reason ??
            ''; // Assuming 'description' exists in ProductSample
      default:
        return '';
    }
  }

  // Getter to access the report image URL if available
  String? get displayImageUrl {
    switch (type) {
      case ReportType.VISIBILITY_ACTIVITY:
        return visibilityReport?.imageUrl;
      default:
        return null;
    }
  }

  // Convenience method to create a product report
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

  // Convenience method to create a visibility report
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

  // Convenience method to create a feedback report
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

  // Null-safe display getters
  String get displayId => id?.toString() ?? 'N/A';
  String get displayType =>
      type.toString().split('.').last.replaceAll('_', ' ');
  String get displayJourneyPlanId => journeyPlanId?.toString() ?? 'N/A';
  String get displaySalesRepId => salesRepId.toString();
  String get displayOrderId => null.toString() ?? 'N/A';
  String get displayClientId => clientId.toString();
  String get displayCreatedAt => createdAt?.toLocal().toString() ?? 'N/A';
  String get displayUpdatedAt => updatedAt?.toLocal().toString() ?? 'N/A';

  // User and client display info
  String get displayUserName => user?.name ?? 'Unknown User';
  String get displayUserEmail => user?.email ?? 'No Email';
  String get displayUserPhone => user?.phoneNumber ?? 'No Phone';
  String get displayClientName => client?.name ?? 'Unknown Client';
  String get displayClientLocation => client?.location ?? 'No Location';

  // Report specific display info
  String get displayComment {
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

  // Product return items display
  List<Map<String, String>> get displayProductReturnItems {
    if (productReturnItems == null || productReturnItems!.isEmpty) {
      return [
        {'message': 'No return items'}
      ];
    }
    return productReturnItems!
        .map((item) => {
              'product': item.productName ?? 'Unknown Product',
              'quantity': item.quantity?.toString() ?? '0',
              'reason': item.reason ?? 'No reason provided',
            })
        .toList();
  }

  // Product sample items display
  List<Map<String, String>> get displayProductSampleItems {
    if (productSampleItems == null || productSampleItems!.isEmpty) {
      return [
        {'message': 'No sample items'}
      ];
    }
    return productSampleItems!
        .map((item) => {
              'product': item.productName ?? 'Unknown Product',
              'quantity': item.quantity?.toString() ?? '0',
              'reason': item.reason ?? 'No reason provided',
            })
        .toList();
  }

  // Product availability display
  Map<String, String> get displayProductAvailability {
    if (productReport == null) {
      return {
        'product': 'No product data',
        'quantity': 'N/A',
        'comment': 'No comment'
      };
    }
    return {
      'product': productReport!.productName ?? 'Unknown Product',
      'quantity': productReport!.quantity?.toString() ?? '0',
      'comment': productReport!.comment ?? 'No comment'
    };
  }

  // Visibility activity display
  Map<String, String> get displayVisibilityActivity {
    if (visibilityReport == null) {
      return {'comment': 'No visibility data', 'image': 'No image'};
    }
    return {
      'comment': visibilityReport!.comment ?? 'No comment',
      'image': visibilityReport!.imageUrl ?? 'No image'
    };
  }

  // Feedback display
  Map<String, String> get displayFeedback {
    if (feedbackReport == null) {
      return {'comment': 'No feedback data'};
    }
    return {'comment': feedbackReport!.comment ?? 'No comment'};
  }

  // Product return display
  Map<String, dynamic> get displayProductReturn {
    if (productReturn == null) {
      return {
        'reason': 'No return data',
        'items': [
          {'message': 'No return items'}
        ]
      };
    }
    return {
      'reason': productReturn!.reason ?? 'No reason provided',
      'items': displayProductReturnItems
    };
  }

  // Product sample display
  Map<String, dynamic> get displayProductSample {
    if (productSample == null) {
      return {
        'reason': 'No sample data',
        'items': [
          {'message': 'No sample items'}
        ]
      };
    }
    return {
      'reason': productSample!.reason ?? 'No reason provided',
      'items': displayProductSampleItems
    };
  }

  // Get all display data as a map
  Map<String, dynamic> get displayData {
    return {
      'id': displayId,
      'type': displayType,
      'journeyPlanId': displayJourneyPlanId,
      'salesRepId': displaySalesRepId,
      'orderId': displayOrderId,
      'clientId': displayClientId,
      'createdAt': displayCreatedAt,
      'updatedAt': displayUpdatedAt,
      'user': {
        'name': displayUserName,
        'email': displayUserEmail,
        'phone': displayUserPhone,
      },
      'client': {
        'name': displayClientName,
        'location': displayClientLocation,
      },
      'comment': displayComment,
      'imageUrl': displayImageUrl,
      'specificData': _getSpecificDisplayData(),
    };
  }

  Map<String, dynamic> _getSpecificDisplayData() {
    switch (type) {
      case ReportType.PRODUCT_AVAILABILITY:
        return {'productAvailability': displayProductAvailability};
      case ReportType.VISIBILITY_ACTIVITY:
        return {'visibilityActivity': displayVisibilityActivity};
      case ReportType.FEEDBACK:
        return {'feedback': displayFeedback};
      case ReportType.PRODUCT_RETURN:
        return {'productReturn': displayProductReturn};
      case ReportType.PRODUCT_SAMPLE:
        return {'productSample': displayProductSample};
      default:
        return {'message': 'Unknown report type'};
    }
  }

  @override
  String toString() {
    return 'Report{'
        'id: $displayId, '
        'type: $displayType, '
        'journeyPlanId: $displayJourneyPlanId, '
        'salesRepId: $displaySalesRepId, '
        'orderId: $displayOrderId, '
        'clientId: $displayClientId, '
        'createdAt: $displayCreatedAt, '
        'updatedAt: $displayUpdatedAt, '
        'user: $displayUserName, '
        'client: $displayClientName'
        '}';
  }

  static ReportType _parseReportType(dynamic type) {

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

  // Helper method to get the correct field name for specific report types
  static String _getSpecificReportFieldName(ReportType type) {
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
}