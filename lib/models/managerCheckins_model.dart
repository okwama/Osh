import 'package:woosh/models/outlet_model.dart';

class ManagerCheckin {
  final int id;
  final int managerId;
  final int outletId;
  final DateTime date;
  final DateTime? checkInAt;
  final DateTime? checkOutAt;
  final double? latitude;
  final double? longitude;
  final String? notes;
  final Outlet? outlet;

  ManagerCheckin({
    required this.id,
    required this.managerId,
    required this.outletId,
    required this.date,
    this.checkInAt,
    this.checkOutAt,
    this.latitude,
    this.longitude,
    this.notes,
    this.outlet,
  });

  factory ManagerCheckin.fromJson(Map<String, dynamic> json) {
    return ManagerCheckin(
      id: json['id'],
      managerId: json['managerId'],
      outletId: json['outletId'],
      date: DateTime.parse(json['date']),
      checkInAt:
          json['checkInAt'] != null ? DateTime.parse(json['checkInAt']) : null,
      checkOutAt: json['checkOutAt'] != null
          ? DateTime.parse(json['checkOutAt'])
          : null,
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      notes: json['notes'],
      outlet: json['outlet'] != null ? Outlet.fromJson(json['outlet']) : null,
    );
  }
}
