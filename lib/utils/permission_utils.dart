import 'package:permission_handler/permission_handler.dart';
import 'package:woosh/services/permission_service.dart';

/// Utility class for common permission operations
class PermissionUtils {
  static final PermissionService _permissionService = PermissionService();

  /// Check if camera permission is available before using camera features
  static Future<bool> checkCameraPermission() async {
    final isGranted = await _permissionService.isCameraGranted;
    if (!isGranted) {
      final status =
          await _permissionService.requestPermission(Permission.camera);
      return status.isGranted;
    }
    return true;
  }

  /// Check if location permission is available before using GPS features
  static Future<bool> checkLocationPermission() async {
    final isGranted = await _permissionService.isLocationGranted;
    if (!isGranted) {
      final status =
          await _permissionService.requestPermission(Permission.location);
      return status.isGranted;
    }
    return true;
  }

  /// Check if storage permission is available before file operations
  static Future<bool> checkStoragePermission() async {
    final isGranted = await _permissionService.isStorageGranted;
    if (!isGranted) {
      final status =
          await _permissionService.requestPermission(Permission.storage);
      return status.isGranted;
    }
    return true;
  }

  /// Check if notification permission is available
  static Future<bool> checkNotificationPermission() async {
    final isGranted = await _permissionService.isNotificationGranted;
    if (!isGranted) {
      final status =
          await _permissionService.requestPermission(Permission.notification);
      return status.isGranted;
    }
    return true;
  }

  /// Get a summary of all permission statuses
  static Future<Map<String, bool>> getPermissionSummary() async {
    final statuses = await _permissionService.getAllPermissionStatuses();
    return {
      'camera': statuses[Permission.camera]?.isGranted ?? false,
      'location': statuses[Permission.location]?.isGranted ?? false,
      'notification': statuses[Permission.notification]?.isGranted ?? false,
      'storage': statuses[Permission.storage]?.isGranted ?? false,
    };
  }

  /// Check if all critical permissions are granted
  static Future<bool> areAllPermissionsGranted() async {
    final summary = await getPermissionSummary();
    return summary.values.every((granted) => granted);
  }

  /// Get list of denied permissions
  static Future<List<String>> getDeniedPermissions() async {
    final summary = await getPermissionSummary();
    return summary.entries
        .where((entry) => !entry.value)
        .map((entry) => entry.key)
        .toList();
  }
}
