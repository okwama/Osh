class VersionConfig {
  // API Configuration - Disabled since no backend API exists
  static const String versionApiUrl = ''; // Empty to disable API calls

  // App Store URLs (already configured with your actual app URLs)
  static const String androidPackageName = 'com.cit.wooshs';
  static const String iosAppId = '6745750140';
  static const String androidStoreUrl =
      'https://play.google.com/store/apps/details?id=$androidPackageName';
  static const String iosStoreUrl =
      'https://apps.apple.com/ke/app/woosh-moonsun/id$iosAppId';

  // Version Check Settings
  static const int apiTimeoutSeconds = 5;
  static const bool enableAutoCheck = true;
  static const bool enableStoreFallback = true;
  static const bool skipApiCheck = true; // Skip API check entirely

  // Update Dialog Settings
  static const bool showReleaseNotes = true;
  static const bool allowSkipUpdate = true;
}
