import 'package:flutter/material.dart';
import 'date_range_model.dart';

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
