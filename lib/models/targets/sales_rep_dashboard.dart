import 'package:flutter/material.dart';

/// Main dashboard model that combines all target metrics for a sales representative
class SalesRepDashboard {
  final int userId;
  final String period;
  final VisitTargets visitTargets;
  final NewClientsProgress newClients;
  final ProductSalesProgress productSales;
  final DateTime generatedAt;

  SalesRepDashboard({
    required this.userId,
    required this.period,
    required this.visitTargets,
    required this.newClients,
    required this.productSales,
    required this.generatedAt,
  });

  factory SalesRepDashboard.fromJson(Map<String, dynamic> json) {
    return SalesRepDashboard(
      userId: json['userId'] as int,
      period: json['period'] as String,
      visitTargets:
          VisitTargets.fromJson(json['visitTargets'] as Map<String, dynamic>),
      newClients: NewClientsProgress.fromJson(
          json['newClients'] as Map<String, dynamic>),
      productSales: ProductSalesProgress.fromJson(
          json['productSales'] as Map<String, dynamic>),
      generatedAt: DateTime.parse(json['generatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'period': period,
      'visitTargets': visitTargets.toJson(),
      'newClients': newClients.toJson(),
      'productSales': productSales.toJson(),
      'generatedAt': generatedAt.toIso8601String(),
    };
  }

  /// Calculate overall performance score (0-100)
  double get overallPerformanceScore {
    return (visitTargets.progress +
            newClients.progress +
            ((productSales.summary.vapes.progress +
                    productSales.summary.pouches.progress) /
                2)) /
        3;
  }

  /// Get color based on overall performance
  Color get performanceColor {
    final score = overallPerformanceScore;
    if (score >= 90) return Colors.green;
    if (score >= 75) return Colors.lightGreen;
    if (score >= 60) return Colors.orange;
    if (score >= 40) return Colors.deepOrange;
    return Colors.red;
  }

  /// Check if all targets are achieved
  bool get allTargetsAchieved {
    return visitTargets.isTargetAchieved &&
        newClients.isTargetAchieved &&
        productSales.summary.vapes.isTargetAchieved &&
        productSales.summary.pouches.isTargetAchieved;
  }

  SalesRepDashboard copyWith({
    int? userId,
    String? period,
    VisitTargets? visitTargets,
    NewClientsProgress? newClients,
    ProductSalesProgress? productSales,
    DateTime? generatedAt,
  }) {
    return SalesRepDashboard(
      userId: userId ?? this.userId,
      period: period ?? this.period,
      visitTargets: visitTargets ?? this.visitTargets,
      newClients: newClients ?? this.newClients,
      productSales: productSales ?? this.productSales,
      generatedAt: generatedAt ?? this.generatedAt,
    );
  }
}

/// Daily visit targets model
class VisitTargets {
  final String userId;
  final String date;
  final int visitTarget;
  final int completedVisits;
  final int remainingVisits;
  final int progress;
  final String status;

  VisitTargets({
    required this.userId,
    required this.date,
    required this.visitTarget,
    required this.completedVisits,
    required this.remainingVisits,
    required this.progress,
    required this.status,
  });

  factory VisitTargets.fromJson(Map<String, dynamic> json) {
    return VisitTargets(
      userId: json['userId'].toString(),
      date: json['date'] as String,
      visitTarget: json['visitTarget'] as int,
      completedVisits: json['completedVisits'] as int,
      remainingVisits: json['remainingVisits'] as int,
      progress: json['progress'] as int,
      status: json['status'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'date': date,
      'visitTarget': visitTarget,
      'completedVisits': completedVisits,
      'remainingVisits': remainingVisits,
      'progress': progress,
      'status': status,
    };
  }

  /// Check if target is achieved
  bool get isTargetAchieved => progress >= 100;

  /// Get status color
  Color get statusColor {
    if (isTargetAchieved) return Colors.green;
    if (progress >= 80) return Colors.lightGreen;
    if (progress >= 60) return Colors.orange;
    if (progress >= 40) return Colors.deepOrange;
    return Colors.red;
  }

  /// Get completion percentage as double (0.0 to 1.0)
  double get completionPercentage => progress / 100.0;

  /// Get parsed date
  DateTime get parsedDate => DateTime.parse(date);

  VisitTargets copyWith({
    String? userId,
    String? date,
    int? visitTarget,
    int? completedVisits,
    int? remainingVisits,
    int? progress,
    String? status,
  }) {
    return VisitTargets(
      userId: userId ?? this.userId,
      date: date ?? this.date,
      visitTarget: visitTarget ?? this.visitTarget,
      completedVisits: completedVisits ?? this.completedVisits,
      remainingVisits: remainingVisits ?? this.remainingVisits,
      progress: progress ?? this.progress,
      status: status ?? this.status,
    );
  }
}

/// New clients progress model
class NewClientsProgress {
  final int userId;
  final String salesRepName;
  final String period;
  final DateRange dateRange;
  final int newClientsTarget;
  final int newClientsAdded;
  final int remainingClients;
  final int progress;
  final String status;
  final DateTime generatedAt;

  NewClientsProgress({
    required this.userId,
    required this.salesRepName,
    required this.period,
    required this.dateRange,
    required this.newClientsTarget,
    required this.newClientsAdded,
    required this.remainingClients,
    required this.progress,
    required this.status,
    required this.generatedAt,
  });

  factory NewClientsProgress.fromJson(Map<String, dynamic> json) {
    return NewClientsProgress(
      userId: json['userId'] as int,
      salesRepName: json['salesRepName'] as String,
      period: json['period'] as String,
      dateRange: DateRange.fromJson(json['dateRange'] as Map<String, dynamic>),
      newClientsTarget: json['newClientsTarget'] as int,
      newClientsAdded: json['newClientsAdded'] as int,
      remainingClients: json['remainingClients'] as int,
      progress: json['progress'] as int,
      status: json['status'] as String,
      generatedAt: DateTime.parse(json['generatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'salesRepName': salesRepName,
      'period': period,
      'dateRange': dateRange.toJson(),
      'newClientsTarget': newClientsTarget,
      'newClientsAdded': newClientsAdded,
      'remainingClients': remainingClients,
      'progress': progress,
      'status': status,
      'generatedAt': generatedAt.toIso8601String(),
    };
  }

  /// Check if target is achieved
  bool get isTargetAchieved => progress >= 100;

  /// Get status color
  Color get statusColor {
    if (isTargetAchieved) return Colors.green;
    if (progress >= 80) return Colors.lightGreen;
    if (progress >= 60) return Colors.orange;
    if (progress >= 40) return Colors.deepOrange;
    return Colors.red;
  }

  /// Get completion percentage as double (0.0 to 1.0)
  double get completionPercentage => progress / 100.0;

  /// Get period display text
  String get periodDisplayText {
    switch (period) {
      case 'current_month':
        return 'This Month';
      case 'last_month':
        return 'Last Month';
      case 'current_year':
        return 'This Year';
      default:
        return period;
    }
  }

  NewClientsProgress copyWith({
    int? userId,
    String? salesRepName,
    String? period,
    DateRange? dateRange,
    int? newClientsTarget,
    int? newClientsAdded,
    int? remainingClients,
    int? progress,
    String? status,
    DateTime? generatedAt,
  }) {
    return NewClientsProgress(
      userId: userId ?? this.userId,
      salesRepName: salesRepName ?? this.salesRepName,
      period: period ?? this.period,
      dateRange: dateRange ?? this.dateRange,
      newClientsTarget: newClientsTarget ?? this.newClientsTarget,
      newClientsAdded: newClientsAdded ?? this.newClientsAdded,
      remainingClients: remainingClients ?? this.remainingClients,
      progress: progress ?? this.progress,
      status: status ?? this.status,
      generatedAt: generatedAt ?? this.generatedAt,
    );
  }
}

/// Product sales progress model for vapes and pouches
class ProductSalesProgress {
  final int userId;
  final String salesRepName;
  final String period;
  final DateRange dateRange;
  final ProductSummary summary;
  final List<ProductBreakdown> productBreakdown;
  final DateTime generatedAt;

  ProductSalesProgress({
    required this.userId,
    required this.salesRepName,
    required this.period,
    required this.dateRange,
    required this.summary,
    required this.productBreakdown,
    required this.generatedAt,
  });

  factory ProductSalesProgress.fromJson(Map<String, dynamic> json) {
    return ProductSalesProgress(
      userId: json['userId'] as int,
      salesRepName: json['salesRepName'] as String,
      period: json['period'] as String,
      dateRange: DateRange.fromJson(json['dateRange'] as Map<String, dynamic>),
      summary: ProductSummary.fromJson(json['summary'] as Map<String, dynamic>),
      productBreakdown: (json['productBreakdown'] as List<dynamic>)
          .map(
              (item) => ProductBreakdown.fromJson(item as Map<String, dynamic>))
          .toList(),
      generatedAt: DateTime.parse(json['generatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'salesRepName': salesRepName,
      'period': period,
      'dateRange': dateRange.toJson(),
      'summary': summary.toJson(),
      'productBreakdown':
          productBreakdown.map((item) => item.toJson()).toList(),
      'generatedAt': generatedAt.toIso8601String(),
    };
  }

  /// Get overall product sales progress (average of vapes and pouches)
  double get overallProgress =>
      (summary.vapes.progress + summary.pouches.progress) / 2;

  /// Get overall status color
  Color get overallStatusColor {
    final progress = overallProgress;
    if (progress >= 100) return Colors.green;
    if (progress >= 80) return Colors.lightGreen;
    if (progress >= 60) return Colors.orange;
    if (progress >= 40) return Colors.deepOrange;
    return Colors.red;
  }

  ProductSalesProgress copyWith({
    int? userId,
    String? salesRepName,
    String? period,
    DateRange? dateRange,
    ProductSummary? summary,
    List<ProductBreakdown>? productBreakdown,
    DateTime? generatedAt,
  }) {
    return ProductSalesProgress(
      userId: userId ?? this.userId,
      salesRepName: salesRepName ?? this.salesRepName,
      period: period ?? this.period,
      dateRange: dateRange ?? this.dateRange,
      summary: summary ?? this.summary,
      productBreakdown: productBreakdown ?? this.productBreakdown,
      generatedAt: generatedAt ?? this.generatedAt,
    );
  }
}

/// Product summary with vapes and pouches metrics
class ProductSummary {
  final int totalOrders;
  final int totalQuantitySold;
  final ProductMetric vapes;
  final ProductMetric pouches;

  ProductSummary({
    required this.totalOrders,
    required this.totalQuantitySold,
    required this.vapes,
    required this.pouches,
  });

  factory ProductSummary.fromJson(Map<String, dynamic> json) {
    return ProductSummary(
      totalOrders: json['totalOrders'] as int,
      totalQuantitySold: json['totalQuantitySold'] as int,
      vapes: ProductMetric.fromJson(json['vapes'] as Map<String, dynamic>),
      pouches: ProductMetric.fromJson(json['pouches'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalOrders': totalOrders,
      'totalQuantitySold': totalQuantitySold,
      'vapes': vapes.toJson(),
      'pouches': pouches.toJson(),
    };
  }

  ProductSummary copyWith({
    int? totalOrders,
    int? totalQuantitySold,
    ProductMetric? vapes,
    ProductMetric? pouches,
  }) {
    return ProductSummary(
      totalOrders: totalOrders ?? this.totalOrders,
      totalQuantitySold: totalQuantitySold ?? this.totalQuantitySold,
      vapes: vapes ?? this.vapes,
      pouches: pouches ?? this.pouches,
    );
  }
}

/// Individual product metric (vapes or pouches)
class ProductMetric {
  final int target;
  final int sold;
  final int remaining;
  final int progress;
  final String status;

  ProductMetric({
    required this.target,
    required this.sold,
    required this.remaining,
    required this.progress,
    required this.status,
  });

  factory ProductMetric.fromJson(Map<String, dynamic> json) {
    return ProductMetric(
      target: json['target'] as int,
      sold: json['sold'] as int,
      remaining: json['remaining'] as int,
      progress: json['progress'] as int,
      status: json['status'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'target': target,
      'sold': sold,
      'remaining': remaining,
      'progress': progress,
      'status': status,
    };
  }

  /// Check if target is achieved
  bool get isTargetAchieved => progress >= 100;

  /// Get status color
  Color get statusColor {
    if (isTargetAchieved) return Colors.green;
    if (progress >= 80) return Colors.lightGreen;
    if (progress >= 60) return Colors.orange;
    if (progress >= 40) return Colors.deepOrange;
    return Colors.red;
  }

  /// Get completion percentage as double (0.0 to 1.0)
  double get completionPercentage => progress / 100.0;

  ProductMetric copyWith({
    int? target,
    int? sold,
    int? remaining,
    int? progress,
    String? status,
  }) {
    return ProductMetric(
      target: target ?? this.target,
      sold: sold ?? this.sold,
      remaining: remaining ?? this.remaining,
      progress: progress ?? this.progress,
      status: status ?? this.status,
    );
  }
}

/// Product breakdown for individual products
class ProductBreakdown {
  final int productId;
  final String productName;
  final String category;
  final int? categoryId;
  final int quantity;
  final bool isVape;
  final bool isPouch;

  ProductBreakdown({
    required this.productId,
    required this.productName,
    required this.category,
    this.categoryId,
    required this.quantity,
    required this.isVape,
    required this.isPouch,
  });

  factory ProductBreakdown.fromJson(Map<String, dynamic> json) {
    return ProductBreakdown(
      productId: json['productId'] as int,
      productName: json['productName'] as String,
      category: json['category'] as String,
      categoryId: json['categoryId'] as int?,
      quantity: json['quantity'] as int,
      isVape: json['isVape'] as bool,
      isPouch: json['isPouch'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'category': category,
      'categoryId': categoryId,
      'quantity': quantity,
      'isVape': isVape,
      'isPouch': isPouch,
    };
  }

  /// Get product type display text
  String get productTypeDisplay {
    if (isVape) return 'Vape';
    if (isPouch) return 'Pouch';
    return 'Other';
  }

  /// Get category icon
  IconData get categoryIcon {
    if (isVape) return Icons.cloud;
    if (isPouch) return Icons.inventory_2;
    return Icons.category;
  }

  ProductBreakdown copyWith({
    int? productId,
    String? productName,
    String? category,
    int? categoryId,
    int? quantity,
    bool? isVape,
    bool? isPouch,
  }) {
    return ProductBreakdown(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      category: category ?? this.category,
      categoryId: categoryId ?? this.categoryId,
      quantity: quantity ?? this.quantity,
      isVape: isVape ?? this.isVape,
      isPouch: isPouch ?? this.isPouch,
    );
  }
}

/// Date range model
class DateRange {
  final String startDate;
  final String endDate;

  DateRange({
    required this.startDate,
    required this.endDate,
  });

  factory DateRange.fromJson(Map<String, dynamic> json) {
    return DateRange(
      startDate: json['startDate'] as String,
      endDate: json['endDate'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'startDate': startDate,
      'endDate': endDate,
    };
  }

  /// Get parsed start date
  DateTime get parsedStartDate => DateTime.parse(startDate);

  /// Get parsed end date
  DateTime get parsedEndDate => DateTime.parse(endDate);

  /// Get duration in days
  int get durationInDays =>
      parsedEndDate.difference(parsedStartDate).inDays + 1;

  /// Get display text for date range
  String get displayText {
    final start = parsedStartDate;
    final end = parsedEndDate;

    if (start.year == end.year && start.month == end.month) {
      return '${start.day}-${end.day} ${_getMonthName(start.month)} ${start.year}';
    } else if (start.year == end.year) {
      return '${start.day} ${_getMonthName(start.month)} - ${end.day} ${_getMonthName(end.month)} ${start.year}';
    } else {
      return '${start.day} ${_getMonthName(start.month)} ${start.year} - ${end.day} ${_getMonthName(end.month)} ${end.year}';
    }
  }

  String _getMonthName(int month) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month];
  }

  DateRange copyWith({
    String? startDate,
    String? endDate,
  }) {
    return DateRange(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }
}
