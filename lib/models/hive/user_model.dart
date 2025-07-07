import 'package:hive/hive.dart';

part 'user_model.g.dart';

@HiveType(typeId: 4)
class UserModel extends HiveObject {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String email;

  @HiveField(3)
  final String? phoneNumber;

  @HiveField(4)
  final String? role;

  @HiveField(5)
  final String? region;

  @HiveField(6)
  final int? regionId;

  @HiveField(7)
  final int? routeId;

  @HiveField(8)
  final String? route;

  @HiveField(9)
  final Map<String, dynamic>? country;

  @HiveField(10)
  final int? countryId;

  @HiveField(11)
  final int? status;

  @HiveField(12)
  final String? photoUrl;

  @HiveField(13)
  final String? department;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phoneNumber,
    this.role,
    this.region,
    this.regionId,
    this.routeId,
    this.route,
    this.country,
    this.countryId,
    this.status,
    this.photoUrl,
    this.department,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber']?.toString(),
      role: json['role']?.toString(),
      region: json['region']?.toString(),
      regionId: json['region_id'],
      routeId: json['route_id'],
      route: json['route']?.toString(),
      country: json['country'] is Map ? json['country'] : null,
      countryId: json['countryId'],
      status: json['status'],
      photoUrl: json['photoUrl']?.toString(),
      department: json['department']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'role': role,
      'region': region,
      'region_id': regionId,
      'route_id': routeId,
      'route': route,
      'country': country,
      'countryId': countryId,
      'status': status,
      'photoUrl': photoUrl,
      'department': department,
    };
  }
}
