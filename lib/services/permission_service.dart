import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  /// Request all required permissions for the app
  Future<Map<Permission, PermissionStatus>> requestPermissions() async {
    try {
      print('🔐 Requesting runtime permissions...');

      // List of permissions to request
      final permissions = [
        Permission.camera,
        Permission.location,
        Permission.notification,
        Permission.storage,
      ];

      // Request all permissions at once - let native dialogs handle it
      final results = await permissions.request();

      print('📋 Permission request results:');
      results.forEach((permission, status) {
        print('   - ${permission.toString().split('.').last}: $status');
      });

      return results;
    } catch (e) {
      print('❌ Error requesting permissions: $e');
      return {};
    }
  }

  /// Check if a specific permission is granted
  Future<bool> isPermissionGranted(Permission permission) async {
    final status = await permission.status;
    return status.isGranted;
  }

  /// Request a specific permission
  Future<PermissionStatus> requestPermission(Permission permission) async {
    try {
      final status = await permission.request();
      print('🔐 ${permission.toString().split('.').last}: $status');
      return status;
    } catch (e) {
      print('❌ Error requesting ${permission.toString().split('.').last}: $e');
      return PermissionStatus.denied;
    }
  }

  /// Get user-friendly permission name
  String _getPermissionName(Permission permission) {
    switch (permission) {
      case Permission.camera:
        return 'Camera (for scanning products)';
      case Permission.location:
        return 'Location (for GPS tracking)';
      case Permission.notification:
        return 'Notifications (for alerts)';
      case Permission.storage:
        return 'Storage (for file uploads)';
      default:
        return permission.toString().split('.').last;
    }
  }

  /// Check if camera permission is granted
  Future<bool> get isCameraGranted => isPermissionGranted(Permission.camera);

  /// Check if location permission is granted
  Future<bool> get isLocationGranted =>
      isPermissionGranted(Permission.location);

  /// Check if notification permission is granted
  Future<bool> get isNotificationGranted =>
      isPermissionGranted(Permission.notification);

  /// Check if storage permission is granted
  Future<bool> get isStorageGranted => isPermissionGranted(Permission.storage);

  /// Get all permission statuses
  Future<Map<Permission, PermissionStatus>> getAllPermissionStatuses() async {
    final permissions = [
      Permission.camera,
      Permission.location,
      Permission.notification,
      Permission.storage,
    ];

    final statuses = await Future.wait(
      permissions.map((permission) => permission.status),
    );

    return Map.fromIterables(permissions, statuses);
  }
}
