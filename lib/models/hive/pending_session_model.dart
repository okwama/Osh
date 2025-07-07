import 'package:hive/hive.dart';

part 'pending_session_model.g.dart';

@HiveType(typeId: 13)
class PendingSessionModel extends HiveObject {
  @HiveField(0)
  final String userId;

  @HiveField(1)
  final String operation; // 'start' or 'end'

  @HiveField(2)
  final DateTime timestamp;

  @HiveField(3)
  final String status; // 'pending', 'syncing', 'error'

  @HiveField(4)
  final String? errorMessage;

  @HiveField(5)
  final int retryCount;

  PendingSessionModel({
    required this.userId,
    required this.operation,
    required this.timestamp,
    required this.status,
    this.errorMessage,
    this.retryCount = 0,
  });

  PendingSessionModel copyWith({
    String? status,
    String? errorMessage,
    int? retryCount,
  }) {
    return PendingSessionModel(
      userId: userId,
      operation: operation,
      timestamp: timestamp,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      retryCount: retryCount ?? this.retryCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'operation': operation,
      'timestamp': timestamp.toIso8601String(),
      'status': status,
      'errorMessage': errorMessage,
      'retryCount': retryCount,
    };
  }
}
