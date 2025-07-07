import 'package:hive/hive.dart';

part 'route_model.g.dart';

@HiveType(
    typeId:
        9) // Changed from 8 to resolve conflict with PendingJourneyPlanModel
class RouteModel extends HiveObject {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String name;

  RouteModel({
    required this.id,
    required this.name,
  });

  factory RouteModel.fromJson(Map<String, dynamic> json) {
    return RouteModel(
      id: json['id'],
      name: json['name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}
