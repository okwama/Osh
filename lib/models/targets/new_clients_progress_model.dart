import 'package:flutter/material.dart';
import 'date_range_model.dart';

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
