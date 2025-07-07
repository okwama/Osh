import 'package:hive/hive.dart';

part 'journey_plan_model.g.dart';

@HiveType(typeId: 5)
class JourneyPlanModel extends HiveObject {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final DateTime date;

  @HiveField(2)
  final String time;

  @HiveField(3)
  final int? userId;

  @HiveField(4)
  final int clientId;

  @HiveField(5)
  final int status;

  @HiveField(6)
  final DateTime? checkInTime;

  @HiveField(7)
  final double? latitude;

  @HiveField(8)
  final double? longitude;

  @HiveField(9)
  final String? imageUrl;

  @HiveField(10)
  final String? notes;

  @HiveField(11)
  final double? checkoutLatitude;

  @HiveField(12)
  final double? checkoutLongitude;

  @HiveField(13)
  final DateTime? checkoutTime;

  @HiveField(14)
  final bool showUpdateLocation;

  @HiveField(15)
  final int? routeId;

  JourneyPlanModel({
    required this.id,
    required this.date,
    required this.time,
    this.userId,
    required this.clientId,
    required this.status,
    this.checkInTime,
    this.latitude,
    this.longitude,
    this.imageUrl,
    this.notes,
    this.checkoutLatitude,
    this.checkoutLongitude,
    this.checkoutTime,
    required this.showUpdateLocation,
    this.routeId,
  });

  factory JourneyPlanModel.fromJson(Map<String, dynamic> json) {
    return JourneyPlanModel(
      id: json['id'],
      date: DateTime.parse(json['date']),
      time: json['time'],
      userId: json['userId'],
      clientId: json['clientId'],
      status: json['status'],
      checkInTime: json['checkInTime'] != null
          ? DateTime.parse(json['checkInTime'])
          : null,
      latitude: json['latitude'] != null
          ? (json['latitude'] as num).toDouble()
          : null,
      longitude: json['longitude'] != null
          ? (json['longitude'] as num).toDouble()
          : null,
      imageUrl: json['imageUrl'],
      notes: json['notes'],
      checkoutLatitude: json['checkoutLatitude'] != null
          ? (json['checkoutLatitude'] as num).toDouble()
          : null,
      checkoutLongitude: json['checkoutLongitude'] != null
          ? (json['checkoutLongitude'] as num).toDouble()
          : null,
      checkoutTime: json['checkoutTime'] != null
          ? DateTime.parse(json['checkoutTime'])
          : null,
      showUpdateLocation: json['showUpdateLocation'] ?? true,
      routeId: json['routeId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'time': time,
      'userId': userId,
      'clientId': clientId,
      'status': status,
      'checkInTime': checkInTime?.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'imageUrl': imageUrl,
      'notes': notes,
      'checkoutLatitude': checkoutLatitude,
      'checkoutLongitude': checkoutLongitude,
      'checkoutTime': checkoutTime?.toIso8601String(),
      'showUpdateLocation': showUpdateLocation,
      'routeId': routeId,
    };
  }
}
