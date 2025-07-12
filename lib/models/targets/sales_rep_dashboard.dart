import 'package:flutter/material.dart';
import 'visit_targets_model.dart';
import 'new_clients_progress_model.dart';
import 'product_sales_models.dart';

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
