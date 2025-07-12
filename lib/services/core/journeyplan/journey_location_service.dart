import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:woosh/models/journeyplan/journeyplan_model.dart';

class JourneyLocationService {
  static const double GEOFENCE_RADIUS_METERS = 20037500.0;
  static const Duration LOCATION_UPDATE_INTERVAL = Duration(seconds: 5);

  Position? _currentPosition;
  String? _currentAddress;
  bool _isFetchingLocation = false;
  bool _isWithinGeofence = false;
  double _distanceToClient = 0.0;
  StreamSubscription<Position>? _positionStreamSubscription;

  // Getters
  Position? get currentPosition => _currentPosition;
  String? get currentAddress => _currentAddress;
  bool get isFetchingLocation => _isFetchingLocation;
  bool get isWithinGeofence => _isWithinGeofence;
  double get distanceToClient => _distanceToClient;

  // Callbacks
  Function(Position?)? onPositionChanged;
  Function(String?)? onAddressChanged;
  Function(bool)? onGeofenceChanged;
  Function(double)? onDistanceChanged;

  /// Get current position with fallbacks
  Future<void> getCurrentPosition() async {
    if (_isFetchingLocation) return;

    _setFetchingLocation(true);

    try {
      // Check permissions
      final permission = await Permission.location.request();
      if (permission != PermissionStatus.granted) {
        _handleLocationError('Location permission denied');
        return;
      }

      // Check if location services are enabled
      final isLocationEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isLocationEnabled) {
        _handleLocationError('Location services are disabled');
        return;
      }

      // Get current position with timeout
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      _setCurrentPosition(position);
      await _getAddressFromLatLng(position.latitude, position.longitude);
    } catch (e) {
      print('❌ Error getting current position: $e');
      _handleLocationError('Failed to get current location');
    } finally {
      _setFetchingLocation(false);
    }
  }

  /// Start location updates
  void startLocationUpdates() {
    _positionStreamSubscription?.cancel();

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      ),
    ).listen(
      (Position position) {
        _setCurrentPosition(position);
        _getAddressFromLatLng(position.latitude, position.longitude);
      },
      onError: (error) {
        print('❌ Location stream error: $error');
      },
    );
  }

  /// Stop location updates
  void stopLocationUpdates() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
  }

  /// Get address from coordinates
  Future<void> _getAddressFromLatLng(double latitude, double longitude) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        final address = [
          placemark.street,
          placemark.subLocality,
          placemark.locality,
          placemark.administrativeArea,
        ].where((part) => part != null && part.isNotEmpty).join(', ');

        _setCurrentAddress(address.isNotEmpty ? address : 'Location found');
      } else {
        _setCurrentAddress('Location found');
      }
    } catch (e) {
      print('❌ Error getting address: $e');
      _setCurrentAddress('Location found');
    }
  }

  /// Check if user is within geofence
  Future<bool> checkGeofence(JourneyPlan journeyPlan) async {
    if (_currentPosition == null ||
        journeyPlan.client.latitude == null ||
        journeyPlan.client.longitude == null) {
      return false;
    }

    final distance = _calculateDistance(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      journeyPlan.client.latitude!,
      journeyPlan.client.longitude!,
    );

    _setDistanceToClient(distance);
    final isWithin = distance <= GEOFENCE_RADIUS_METERS;
    _setGeofenceStatus(isWithin);

    return isWithin;
  }

  /// Calculate distance using Haversine formula
  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; // Earth's radius in meters

    // Convert to radians
    double lat1Rad = lat1 * pi / 180;
    double lat2Rad = lat2 * pi / 180;
    double deltaLat = (lat2 - lat1) * pi / 180;
    double deltaLon = (lon2 - lon1) * pi / 180;

    // Haversine formula
    double a = sin(deltaLat / 2) * sin(deltaLat / 2) +
        cos(lat1Rad) * cos(lat2Rad) * sin(deltaLon / 2) * sin(deltaLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    // Calculate distance in meters
    return earthRadius * c;
  }

  /// Use check-in location from journey plan
  void useCheckInLocation(JourneyPlan journeyPlan) {
    if (journeyPlan.latitude != null && journeyPlan.longitude != null) {
      final position = Position(
        latitude: journeyPlan.latitude!,
        longitude: journeyPlan.longitude!,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        floor: null,
        isMocked: false,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      );

      _setCurrentPosition(position);
      _setCurrentAddress(
          'Location: ${journeyPlan.latitude!.toStringAsFixed(6)}, ${journeyPlan.longitude!.toStringAsFixed(6)}');

      // Try to get a more detailed address
      _getAddressFromLatLng(journeyPlan.latitude!, journeyPlan.longitude!);

      print(
          '📍 Using check-in location: Lat ${journeyPlan.latitude}, Lng ${journeyPlan.longitude}');
    } else {
      print('📍 No check-in location found, getting current position');
      getCurrentPosition();
    }
  }

  /// Handle location errors
  void _handleLocationError(String message) {
    _setCurrentAddress(message);
    print('❌ Location error: $message');
  }

  /// Set current position
  void _setCurrentPosition(Position? position) {
    _currentPosition = position;
    onPositionChanged?.call(position);
  }

  /// Set current address
  void _setCurrentAddress(String? address) {
    _currentAddress = address;
    onAddressChanged?.call(address);
  }

  /// Set fetching location status
  void _setFetchingLocation(bool fetching) {
    _isFetchingLocation = fetching;
  }

  /// Set geofence status
  void _setGeofenceStatus(bool within) {
    _isWithinGeofence = within;
    onGeofenceChanged?.call(within);
  }

  /// Set distance to client
  void _setDistanceToClient(double distance) {
    _distanceToClient = distance;
    onDistanceChanged?.call(distance);
  }

  /// Dispose resources
  void dispose() {
    stopLocationUpdates();
  }
}
