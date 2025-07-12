import 'dart:convert';
import 'package:woosh/models/journeyplan/report/feedbackReport_model.dart';
import 'package:woosh/models/journeyplan/report/productReport_model.dart';
import 'package:woosh/models/journeyplan/report/product_return_item_model.dart';
import 'package:woosh/models/journeyplan/report/product_sample_item_model.dart';
import 'package:woosh/models/journeyplan/report/visibilityReport_model.dart';
import 'package:woosh/models/journeyplan/report/productReturn_model.dart';
import 'package:woosh/models/journeyplan/report/productSample_model.dart';
import 'package:woosh/models/journeyplan/report/report_display_mixins.dart';
import 'package:woosh/models/journeyplan/report/report_utils.dart';
import 'package:woosh/models/salerep/sales_rep_model.dart';
import 'package:woosh/models/client/client_model.dart';

enum ReportType {
  PRODUCT_AVAILABILITY,
  VISIBILITY_ACTIVITY,
  FEEDBACK,
  PRODUCT_RETURN,
  PRODUCT_SAMPLE,
}

class Report {
  final int? id;
  final ReportType type;
  final int? journeyPlanId;
  final int salesRepId;
  final int clientId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final ProductReport? productReport;
  final List<ProductReport>? productReports;
  final VisibilityReport? visibilityReport;
  final FeedbackReport? feedbackReport;
  final List<ProductReturnItem>? productReturnItems;
  final List<ProductSampleItem>? productSampleItems;
  final ProductReturn? productReturn;
  final ProductSample? productSample;
  final Client? client;
  final SalesRepModel? user;

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
    this.productSample,
    this.client,
    this.user,
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
      user: user,
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

  // Display getters using the helper class
  String get displayId => ReportDisplayHelper.getDisplayId(id);
  String get displayType => ReportDisplayHelper.getDisplayType(type);
  String get displayJourneyPlanId =>
      ReportDisplayHelper.getDisplayJourneyPlanId(journeyPlanId);
  String get displaySalesRepId =>
      ReportDisplayHelper.getDisplaySalesRepId(salesRepId);
  String get displayOrderId => ReportDisplayHelper.getDisplayOrderId();
  String get displayClientId =>
      ReportDisplayHelper.getDisplayClientId(clientId);
  String get displayCreatedAt =>
      ReportDisplayHelper.getDisplayCreatedAt(createdAt);
  String get displayUpdatedAt =>
      ReportDisplayHelper.getDisplayUpdatedAt(updatedAt);

  // User and client display info
  String get displayUserName => ReportDisplayHelper.getDisplayUserName(user);
  String get displayUserEmail => ReportDisplayHelper.getDisplayUserEmail(user);
  String get displayUserPhone => ReportDisplayHelper.getDisplayUserPhone(user);
  String get displayClientName =>
      ReportDisplayHelper.getDisplayClientName(client);
  String get displayClientLocation =>
      ReportDisplayHelper.getDisplayClientLocation(client);

  // Report specific display info
  String get displayComment => ReportUtils.getReportComment(
        type,
        productReport: productReport,
        visibilityReport: visibilityReport,
        feedbackReport: feedbackReport,
        productReturn: productReturn,
        productSample: productSample,
      );

  String? get displayImageUrl =>
      ReportDisplayHelper.getDisplayImageUrl(type, visibilityReport);

  // Product return items display
  List<Map<String, String>> get displayProductReturnItems =>
      ReportDisplayHelper.getDisplayProductReturnItems(productReturnItems);

  // Product sample items display
  List<Map<String, String>> get displayProductSampleItems =>
      ReportDisplayHelper.getDisplayProductSampleItems(productSampleItems);

  // Product availability display
  Map<String, String> get displayProductAvailability =>
      ReportDisplayHelper.getDisplayProductAvailability(productReport);

  // Visibility activity display
  Map<String, String> get displayVisibilityActivity =>
      ReportDisplayHelper.getDisplayVisibilityActivity(visibilityReport);

  // Feedback display
  Map<String, String> get displayFeedback =>
      ReportDisplayHelper.getDisplayFeedback(feedbackReport);

  // Product return display
  Map<String, dynamic> get displayProductReturn =>
      ReportDisplayHelper.getDisplayProductReturn(
          productReturn, productReturnItems);

  // Product sample display
  Map<String, dynamic> get displayProductSample =>
      ReportDisplayHelper.getDisplayProductSample(
          productSample, productSampleItems);

  // Get all display data as a map
  Map<String, dynamic> get displayData => ReportDisplayHelper.getDisplayData(
        id: id,
        type: type,
        journeyPlanId: journeyPlanId,
        salesRepId: salesRepId,
        clientId: clientId,
        createdAt: createdAt,
        updatedAt: updatedAt,
        user: user,
        client: client,
        displayComment: displayComment,
        displayImageUrl: displayImageUrl,
        specificData: ReportDisplayHelper.getSpecificDisplayData(
          type,
          productReport: productReport,
          visibilityReport: visibilityReport,
          feedbackReport: feedbackReport,
          productReturn: productReturn,
          productSample: productSample,
          productReturnItems: productReturnItems,
          productSampleItems: productSampleItems,
        ),
      );

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
}
