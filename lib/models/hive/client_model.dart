// lib/models/hive/client_model.dart
import 'package:hive/hive.dart';

part 'client_model.g.dart';

@HiveType(typeId: 6)
class ClientModel extends HiveObject {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String address;

  @HiveField(3)
  final String phone;

  @HiveField(4)
  final String email;

  @HiveField(5)
  final double latitude;

  @HiveField(6)
  final double longitude;

  @HiveField(7)
  final String status;

  @HiveField(8)
  final int countryId;

  ClientModel({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.email,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.countryId,
  });

  factory ClientModel.fromJson(Map<String, dynamic> json) {
    return ClientModel(
      id: json['id'],
      name: json['name'],
      address: json['address'],
      phone: json['phone'],
      email: json['email'],
      latitude:
          json['latitude'] != null ? (json['latitude'] as num).toDouble() : 0.0,
      longitude: json['longitude'] != null
          ? (json['longitude'] as num).toDouble()
          : 0.0,
      status: json['status'],
      countryId: json['countryId'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'phone': phone,
      'email': email,
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
      'countryId': countryId,
    };
  }
}
