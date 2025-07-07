import 'package:woosh/models/client_model.dart';
import 'package:flutter/material.dart';

class JourneyPlan {
  // Status constants
  static const int statusPending = 0;
  static const int statusCheckedIn = 1;
  static const int statusInProgress = 2;
  static const int statusCompleted = 3;
  static const int statusCancelled = 4;

  final int? id;
  final DateTime date;
  final String time;
  final int? salesRepId;
  final int status; // 0 for pending, 1 for checked in
  final String? notes;
  final DateTime? checkInTime;
  final double? latitude;
  final double? longitude;
  final String? imageUrl;
  final Client client;
  final DateTime? checkoutTime;
  final double? checkoutLatitude;
  final double? checkoutLongitude;
  final bool showUpdateLocation; // New flag to control button visibility
  final int? routeId; // Add routeId
  final String? routeName; // Add routeName

  JourneyPlan({
    this.id,
    required this.date,
    required this.time,
    this.salesRepId,
    required this.status,
    this.checkInTime,
    this.latitude,
    this.longitude,
    this.imageUrl,
    required this.client,
    this.notes,
    this.checkoutTime,
    this.checkoutLatitude,
    this.checkoutLongitude,
    this.showUpdateLocation =
        true, // Default to true for backward compatibility
    this.routeId, // Add routeId
    this.routeName, // Add routeName
  });

  // Helper getters for status
  String get statusText {
    switch (status) {
      case statusPending:
        return 'Pending';
      case statusCheckedIn:
        return 'Checked In';
      case statusInProgress:
        return 'In progress';
      case statusCompleted:
        return 'Completed';
      case statusCancelled:
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }

  bool get isCheckedIn => status == statusCheckedIn;
  bool get isPending => status == statusPending;
  bool get isInTransit => status == statusInProgress;
  bool get isCompleted => status == statusCompleted;
  bool get isCancelled => status == statusCancelled;

  // Helper getter for clientId
  int get clientId => client.id;

  // Helper method to get status color
  Color get statusColor {
    switch (status) {
      case statusPending:
        return const Color.fromARGB(218, 94, 71, 38);
      case statusCheckedIn:
        return Colors.blue;
      case statusInProgress:
        return Colors.purple;
      case statusCompleted:
        return Colors.green;
      case statusCancelled:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Helper method to create a copy with updated status
  JourneyPlan copyWith({
    int? id,
    DateTime? date,
    String? time,
    int? salesRepId,
    int? status,
    String? notes,
    DateTime? checkInTime,
    double? latitude,
    double? longitude,
    String? imageUrl,
    Client? client,
    DateTime? checkoutTime,
    double? checkoutLatitude,
    double? checkoutLongitude,
    bool? showUpdateLocation, // Add the new flag
    int? routeId, // Add routeId
    String? routeName, // Add routeName
  }) {
    return JourneyPlan(
      id: id ?? this.id,
      date: date ?? this.date,
      time: time ?? this.time,
      salesRepId: salesRepId ?? this.salesRepId,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      checkInTime: checkInTime ?? this.checkInTime,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      imageUrl: imageUrl ?? this.imageUrl,
      client: client ?? this.client,
      checkoutTime: checkoutTime ?? this.checkoutTime,
      checkoutLatitude: checkoutLatitude ?? this.checkoutLatitude,
      checkoutLongitude: checkoutLongitude ?? this.checkoutLongitude,
      showUpdateLocation:
          showUpdateLocation ?? this.showUpdateLocation, // Include the new flag
      routeId: routeId ?? this.routeId, // Include the new routeId
      routeName: routeName ?? this.routeName, // Include the new routeName
    );
  }

  factory JourneyPlan.fromJson(Map<String, dynamic> json) {
    // Debug logging to identify the issue
    print('JourneyPlan.fromJson - Processing JSON: ${json.keys.join(', ')}');
    print('JourneyPlan.fromJson - Date field: ${json['date']}');
    print(
        'JourneyPlan.fromJson - Client field present: ${json['client'] != null}');

    if (json['date'] == null || json['date'].toString().isEmpty) {
      throw FormatException(
          'Journey date is required - received: ${json['date']}');
    }
    if (json['client'] == null) {
      throw FormatException('Client information is required');
    }

    // Safe parsing helper functions
    double? parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        try {
          return double.parse(value);
        } catch (e) {
          print('parseDouble error for value "$value": $e');
          return null;
        }
      }
      return null;
    }

    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) {
        try {
          // Handle decimal strings by converting to double first, then to int
          if (value.contains('.')) {
            final doubleValue = double.tryParse(value);
            return doubleValue?.toInt();
          }
          return int.parse(value);
        } catch (e) {
          return null;
        }
      }
      return null;
    }

    DateTime parseDate(String dateStr) {
      try {
        return DateTime.parse(dateStr);
      } catch (e) {
        throw FormatException('Invalid date format: $dateStr');
      }
    }

    // Extract time from date if not provided
    String getTime(DateTime date) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}';
    }

    final date = parseDate(json['date']);
    final time = json['time'] ?? getTime(date);

    // Debug date and time parsing
    print('JourneyPlan parsing - date: ${json['date']} -> $date');
    print('JourneyPlan parsing - time: ${json['time']} -> $time');

    // Convert status to int, default to pending (0)
    final status = json['status'] != null
        ? (json['status'] is int
            ? json['status']
            : int.tryParse(json['status'].toString()) ?? statusPending)
        : statusPending;

    // Debug status parsing
    print('JourneyPlan parsing - status: ${json['status']} -> $status');
    print('JourneyPlan parsing - statusText: ${json['statusText']}');

    // Debug logging for each field
    final id = parseInt(json['id']);
    // Check for both userId and salesRepId (server might use userId)
    final salesRepId = parseInt(json['userId'] ?? json['salesRepId']);
    final routeId = parseInt(json['routeId']);
    final clientId = parseInt(json['clientId']); // Add clientId parsing
    final latitude = parseDouble(json['latitude']);
    final longitude = parseDouble(json['longitude']);
    final checkoutLatitude = parseDouble(json['checkoutLatitude']);
    final checkoutLongitude = parseDouble(json['checkoutLongitude']);

    print('JourneyPlan parsing - id: ${json['id']} -> $id');
    print(
        'JourneyPlan parsing - userId/salesRepId: ${json['userId'] ?? json['salesRepId']} -> $salesRepId');
    print('JourneyPlan parsing - routeId: ${json['routeId']} -> $routeId');
    print('JourneyPlan parsing - clientId: ${json['clientId']} -> $clientId');
    print('JourneyPlan parsing - latitude: ${json['latitude']} -> $latitude');
    print(
        'JourneyPlan parsing - longitude: ${json['longitude']} -> $longitude');

    // Debug client parsing
    print('JourneyPlan parsing - client: ${json['client']}');

    return JourneyPlan(
      id: id,
      date: date,
      time: time,
      salesRepId: salesRepId,
      status: status,
      notes: json['notes'],
      checkInTime:
          json['checkInTime'] != null ? parseDate(json['checkInTime']) : null,
      latitude: latitude,
      longitude: longitude,
      imageUrl: json['imageUrl'],
      client: Client.fromJson(json['client']),
      checkoutTime:
          json['checkoutTime'] != null ? parseDate(json['checkoutTime']) : null,
      checkoutLatitude: checkoutLatitude,
      checkoutLongitude: checkoutLongitude,
      showUpdateLocation:
          json['showUpdateLocation'] ?? true, // Parse the new flag
      routeId: routeId, // Add routeId
      routeName: json['routeName'], // Add routeName
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'time': time,
      'salesRepId': salesRepId,
      'status': status,
      'notes': notes,
      'checkInTime': checkInTime?.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'imageUrl': imageUrl,
      'client': client.toJson(),
      'checkoutTime': checkoutTime?.toIso8601String(),
      'checkoutLatitude': checkoutLatitude,
      'checkoutLongitude': checkoutLongitude,
      'showUpdateLocation': showUpdateLocation, // Include the new flag
      'routeId': routeId, // Add routeId
      'routeName': routeName, // Add routeName
    };
  }

  String get clientName => client.name ?? 'Unknown Client';
}
