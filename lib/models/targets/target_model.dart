import 'package:flutter/material.dart';

enum TargetType {
  SALES,
}

class Target {
  final int id;
  final int salesRepId;
  final bool isCurrent;
  final int targetValue;
  final int achievedValue;
  final bool achieved;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double progress;

  Target({
    required this.id,
    required this.salesRepId,
    required this.isCurrent,
    required this.targetValue,
    required this.achievedValue,
    required this.achieved,
    required this.createdAt,
    required this.updatedAt,
    required this.progress,
  });

  // Add these getters to maintain compatibility with the UI
  DateTime get startDate => createdAt;
  DateTime get endDate => updatedAt;
  bool get isCompleted => achieved;
  String get title => 'Sales Target #$id';
  String get description => 'Target: $targetValue products';

  // Get color based on progress
  Color get statusColor {
    if (achieved) return Colors.green;
    if (progress >= 80) return Colors.green;
    if (progress >= 50) return Colors.orange;
    return Colors.red;
  }

  // Get text representation of target type
  String get typeText {
    switch (TargetType.SALES) {
      case TargetType.SALES:
        return 'Products Sold';
      default:
        return 'Unknown';
    }
  }

  // Check if target is active based on current date
  bool isActive() {
    final now = DateTime.now();
    return now.isAfter(createdAt) && now.isBefore(updatedAt) && !achieved;
  }

  // Check if target is overdue
  bool isOverdue() {
    final now = DateTime.now();
    return now.isAfter(updatedAt) && !achieved;
  }

  // Factory method to create a Target from JSON
  factory Target.fromJson(Map<String, dynamic> json) {
    return Target(
      id: json['id'],
      salesRepId: json['salesRepId'],
      isCurrent: json['isCurrent'] ?? false,
      targetValue: json['targetValue'],
      achievedValue: json['achievedValue'] ?? 0,
      achieved: json['achieved'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      progress: (json['progress'] ?? 0).toDouble(),
    );
  }

  // Convert Target to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'salesRepId': salesRepId,
      'isCurrent': isCurrent,
      'targetValue': targetValue,
      'achievedValue': achievedValue,
      'achieved': achieved,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'progress': progress,
    };
  }

  // Create a copy of this Target with specified changes
  Target copyWith({
    int? id,
    int? salesRepId,
    bool? isCurrent,
    int? targetValue,
    int? achievedValue,
    bool? achieved,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? progress,
  }) {
    return Target(
      id: id ?? this.id,
      salesRepId: salesRepId ?? this.salesRepId,
      isCurrent: isCurrent ?? this.isCurrent,
      targetValue: targetValue ?? this.targetValue,
      achievedValue: achievedValue ?? this.achievedValue,
      achieved: achieved ?? this.achieved,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      progress: progress ?? this.progress,
    );
  }
}

// Extension to get display text
extension TargetTypeExtension on TargetType {
  String get displayText {
    switch (this) {
      case TargetType.SALES:
        return 'Products Sold';
    }
  }
}
