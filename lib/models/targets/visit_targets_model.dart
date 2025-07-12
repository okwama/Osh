import 'package:flutter/material.dart';

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
