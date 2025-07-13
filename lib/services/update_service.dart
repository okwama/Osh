import 'dart:io';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:get_storage/get_storage.dart';
import 'package:woosh/utils/error_logger.dart';

class UpdateService {
  static final GetStorage _storage = GetStorage();

  // Version configuration
  static const String _currentVersion = '2.1.0';
  static const String _latestVersion = '2.1.0';
  static const String _updateUrl =
      'https://play.google.com/store/apps/details?id=com.woosh.app';
  static const String _remindLaterKey = 'update_remind_later';
  static const String _lastUpdateCheckKey = 'last_update_check';

  // Update features list
  static const List<String> _updateFeatures = [
    'Enhanced performance and faster loading times',
    'New dark mode theme option',
    'Improved security and privacy features',
    'Bug fixes and stability improvements',
    'Secure API integration with Vercel',
    'Better offline sync capabilities',
  ];

  /// Get current app version
  static Future<String> getCurrentVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return packageInfo.version;
    } catch (e) {
      ErrorLogger.logError('Update Service', e, context: 'getCurrentVersion');
      return _currentVersion;
    }
  }

  /// Get latest available version
  static String getLatestVersion() {
    return _latestVersion;
  }

  /// Get update features list
  static List<String> getUpdateFeatures() {
    return _updateFeatures;
  }

  /// Check if update is available
  static Future<bool> isUpdateAvailable() async {
    try {
      final currentVersion = await getCurrentVersion();
      return _compareVersions(currentVersion, _latestVersion) < 0;
    } catch (e) {
      ErrorLogger.logError('Update Service', e, context: 'isUpdateAvailable');
      return false;
    }
  }

  /// Check if user should be reminded about update
  static Future<bool> shouldShowUpdateReminder() async {
    try {
      final lastRemind = _storage.read(_remindLaterKey);
      if (lastRemind == null) return true;

      final lastRemindDate = DateTime.parse(lastRemind);
      final daysSinceRemind = DateTime.now().difference(lastRemindDate).inDays;

      // Show reminder after 7 days
      return daysSinceRemind >= 7;
    } catch (e) {
      ErrorLogger.logError('Update Service', e,
          context: 'shouldShowUpdateReminder');
      return true;
    }
  }

  /// Mark update reminder as shown
  static Future<void> markUpdateReminderShown() async {
    try {
      await _storage.write(_remindLaterKey, DateTime.now().toIso8601String());
    } catch (e) {
      ErrorLogger.logError('Update Service', e,
          context: 'markUpdateReminderShown');
    }
  }

  /// Launch app store for update
  static Future<bool> launchUpdate() async {
    try {
      final url = Uri.parse(_updateUrl);
      final canLaunch = await canLaunchUrl(url);

      if (canLaunch) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        return true;
      } else {
        ErrorLogger.logError('Update Service', 'Cannot launch update URL',
            context: 'launchUpdate');
        return false;
      }
    } catch (e) {
      ErrorLogger.logError('Update Service', e, context: 'launchUpdate');
      return false;
    }
  }

  /// Get platform-specific update URL
  static String getUpdateUrl() {
    if (Platform.isAndroid) {
      return 'https://play.google.com/store/apps/details?id=com.woosh.app';
    } else if (Platform.isIOS) {
      return 'https://apps.apple.com/app/woosh/id123456789';
    }
    return _updateUrl;
  }

  /// Compare version strings (returns -1 if v1 < v2, 0 if equal, 1 if v1 > v2)
  static int _compareVersions(String v1, String v2) {
    final parts1 = v1.split('.').map(int.parse).toList();
    final parts2 = v2.split('.').map(int.parse).toList();

    final maxLength =
        parts1.length > parts2.length ? parts1.length : parts2.length;

    for (int i = 0; i < maxLength; i++) {
      final part1 = i < parts1.length ? parts1[i] : 0;
      final part2 = i < parts2.length ? parts2[i] : 0;

      if (part1 < part2) return -1;
      if (part1 > part2) return 1;
    }

    return 0;
  }

  /// Check for updates and show dialog if needed
  static Future<void> checkForUpdates({bool forceShow = false}) async {
    try {
      final isAvailable = await isUpdateAvailable();
      final shouldRemind = await shouldShowUpdateReminder();

      if ((isAvailable && shouldRemind) || forceShow) {
        // Navigate to update page
        // This will be called from your app's main logic
        ErrorLogger.logInfo(
            'Update Service', 'Update available: $_latestVersion');
      }
    } catch (e) {
      ErrorLogger.logError('Update Service', e, context: 'checkForUpdates');
    }
  }

  /// Get update info for display
  static Map<String, dynamic> getUpdateInfo() {
    return {
      'currentVersion': _currentVersion,
      'latestVersion': _latestVersion,
      'features': _updateFeatures,
      'updateUrl': getUpdateUrl(),
      'isAvailable': _compareVersions(_currentVersion, _latestVersion) < 0,
    };
  }
}
