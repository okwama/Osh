import 'package:hive/hive.dart';

part 'session_model.g.dart';

@HiveType(typeId: 3)
class SessionModel extends HiveObject {
  @HiveField(0)
  final bool isActive;

  @HiveField(1)
  final DateTime? lastCheck;

  @HiveField(2)
  final DateTime? loginTime;

  @HiveField(3)
  final String? userId;

  SessionModel({
    required this.isActive,
    this.lastCheck,
    this.loginTime,
    this.userId,
  });
}
