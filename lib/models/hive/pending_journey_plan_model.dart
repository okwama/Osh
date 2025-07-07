import 'package:hive/hive.dart';

part 'pending_journey_plan_model.g.dart';

@HiveType(typeId: 8)
class PendingJourneyPlanModel extends HiveObject {
  @HiveField(0)
  final int clientId;

  @HiveField(1)
  final DateTime date;

  @HiveField(2)
  final String? notes;

  @HiveField(3)
  final int? routeId;

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  final String status; // 'pending', 'syncing', 'error'

  @HiveField(6)
  final String? errorMessage;

  PendingJourneyPlanModel({
    required this.clientId,
    required this.date,
    this.notes,
    this.routeId,
    required this.createdAt,
    required this.status,
    this.errorMessage,
  });

  Map<String, dynamic> toJson() {
    return {
      'clientId': clientId,
      'date': date.toIso8601String(),
      'notes': notes,
      'routeId': routeId,
      'createdAt': createdAt.toIso8601String(),
      'status': status,
      'errorMessage': errorMessage,
    };
  }

  // Create a copy with updated status
  PendingJourneyPlanModel copyWith({
    String? status,
    String? errorMessage,
  }) {
    return PendingJourneyPlanModel(
      clientId: clientId,
      date: date,
      notes: notes,
      routeId: routeId,
      createdAt: createdAt,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
