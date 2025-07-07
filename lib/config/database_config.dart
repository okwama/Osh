class DatabaseConfig {
  // ⚠️ SECURITY WARNING: For production, use environment variables or secure storage
  // Current implementation exposes credentials in code - NOT RECOMMENDED for production

  // Database Settings - Use environment variables in production
  static const String host = '102.218.215.35';
  static const String user = 'citlogis_bryan';
  static const String password = '@bo9511221.qwerty';
  static const String database = 'citlogis_ws';
  static const int port = 3306;

  // Connection settings
  static const int maxRetries = 3;
  static const Duration connectionTimeout = Duration(seconds: 15);
  static const Duration queryTimeout = Duration(seconds: 15);
  static const Duration retryDelay = Duration(seconds: 2);

  // Security check - returns false if using hardcoded credentials
  static bool get isSecure {
    // TODO: Implement proper environment variable checking
    // For now, always returns false to indicate insecure configuration
    print(
        '⚠️ WARNING: Using hardcoded database credentials. For production, use environment variables.');
    return false;
  }
}
