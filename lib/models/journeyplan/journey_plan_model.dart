class JourneyPlanModel {
  final int id;
  final DateTime date;
  final String time;
  final int? userId;
  final int clientId;
  final int status;
  final DateTime? checkInTime;
  final double? latitude;
  final double? longitude;
  final String? imageUrl;
  final String? notes;
  final double? checkoutLatitude;
  final double? checkoutLongitude;
  final DateTime? checkoutTime;
  final bool showUpdateLocation;
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

  factory JourneyPlanModel.fromMap(Map<String, dynamic> map) {
    return JourneyPlanModel(
      id: map['id'] ?? 0,
      date: _parseDateTime(map['date']),
      time: map['time'] ?? '',
      userId: map['userId'],
      clientId: map['clientId'] ?? 0,
      status: map['status'] ?? 0,
      checkInTime: map['checkInTime'] != null
          ? _parseDateTime(map['checkInTime'])
          : null,
      latitude: map['latitude'] != null ? (map['latitude']).toDouble() : null,
      longitude:
          map['longitude'] != null ? (map['longitude']).toDouble() : null,
      imageUrl: map['imageUrl'],
      notes: map['notes'],
      checkoutLatitude: map['checkoutLatitude'] != null
          ? (map['checkoutLatitude']).toDouble()
          : null,
      checkoutLongitude: map['checkoutLongitude'] != null
          ? (map['checkoutLongitude']).toDouble()
          : null,
      checkoutTime: map['checkoutTime'] != null
          ? _parseDateTime(map['checkoutTime'])
          : null,
      showUpdateLocation:
          map['showUpdateLocation'] == 1 || map['showUpdateLocation'] == true,
      routeId: map['routeId'],
    );
  }

  Map<String, dynamic> toMap() {
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
      'showUpdateLocation': showUpdateLocation ? 1 : 0,
      'routeId': routeId,
    };
  }

  /// Get status display text
  String get statusText {
    switch (status) {
      case 0:
        return 'Planned';
      case 1:
        return 'Checked In';
      case 2:
        return 'Completed';
      case 3:
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }

  /// Check if journey is planned
  bool get isPlanned => status == 0;

  /// Check if journey is checked in
  bool get isCheckedIn => status == 1;

  /// Check if journey is completed
  bool get isCompleted => status == 2;

  /// Check if journey is cancelled
  bool get isCancelled => status == 3;

  /// Check if user has checked in
  bool get hasCheckedIn => checkInTime != null;

  /// Check if user has checked out
  bool get hasCheckedOut => checkoutTime != null;

  /// Get visit duration in minutes
  int? get visitDurationMinutes {
    if (checkInTime != null && checkoutTime != null) {
      return checkoutTime!.difference(checkInTime!).inMinutes;
    }
    return null;
  }

  /// Get formatted visit duration
  String get visitDurationText {
    final duration = visitDurationMinutes;
    if (duration == null) return 'N/A';

    final hours = duration ~/ 60;
    final minutes = duration % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  /// Check if visit is overdue (more than 2 hours)
  bool get isOverdue {
    if (checkInTime != null && checkoutTime == null) {
      final now = DateTime.now();
      final duration = now.difference(checkInTime!).inHours;
      return duration > 2;
    }
    return false;
  }

  /// Create a copy with updated fields
  JourneyPlanModel copyWith({
    int? id,
    DateTime? date,
    String? time,
    int? userId,
    int? clientId,
    int? status,
    DateTime? checkInTime,
    double? latitude,
    double? longitude,
    String? imageUrl,
    String? notes,
    double? checkoutLatitude,
    double? checkoutLongitude,
    DateTime? checkoutTime,
    bool? showUpdateLocation,
    int? routeId,
  }) {
    return JourneyPlanModel(
      id: id ?? this.id,
      date: date ?? this.date,
      time: time ?? this.time,
      userId: userId ?? this.userId,
      clientId: clientId ?? this.clientId,
      status: status ?? this.status,
      checkInTime: checkInTime ?? this.checkInTime,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      imageUrl: imageUrl ?? this.imageUrl,
      notes: notes ?? this.notes,
      checkoutLatitude: checkoutLatitude ?? this.checkoutLatitude,
      checkoutLongitude: checkoutLongitude ?? this.checkoutLongitude,
      checkoutTime: checkoutTime ?? this.checkoutTime,
      showUpdateLocation: showUpdateLocation ?? this.showUpdateLocation,
      routeId: routeId ?? this.routeId,
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) {
      try {
        // Handle both ISO string and MySQL datetime formats
        if (value.contains('T')) {
          return DateTime.parse(value);
        } else {
          // MySQL datetime format: YYYY-MM-DD HH:MM:SS
          return DateTime.parse(value.replaceAll(' ', 'T'));
        }
      } catch (e) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  @override
  String toString() {
    return 'JourneyPlanModel(id: $id, clientId: $clientId, date: $date, status: $statusText)';
  }
}