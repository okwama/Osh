import 'package:flutter/foundation.dart';

/// Centralized error logging system with emojis for easy identification
class ErrorLogger {
  static final ErrorLogger _instance = ErrorLogger._internal();
  factory ErrorLogger() => _instance;
  ErrorLogger._internal();

  /// Log errors with consistent format and emojis
  static void logError(String errorType, dynamic error, {String? context}) {
    final timestamp = DateTime.now().toIso8601String();
    final contextStr = context != null ? ' [$context]' : '';
    final errorMessage = error.toString();
    final stackTrace = error is Error ? error.stackTrace : null;

    final logMessage = '''
🔴 ERROR $errorType$contextStr
⏰ Time: $timestamp
❌ Error: $errorMessage
${stackTrace != null ? '📚 Stack Trace:\n$stackTrace' : ''}
''';

    if (kDebugMode) {
      print(logMessage);
    } else {
      // In production, you might want to send this to a logging service
      // like Firebase Crashlytics, Sentry, or your own logging server
      _sendToLoggingService(logMessage);
    }
  }

  /// Log warnings with consistent format
  static void logWarning(String warningType, String message,
      {String? context}) {
    final timestamp = DateTime.now().toIso8601String();
    final contextStr = context != null ? ' [$context]' : '';

    final logMessage = '''
🟡 WARNING $warningType$contextStr
⏰ Time: $timestamp
⚠️ Message: $message
''';

    if (kDebugMode) {
      print(logMessage);
    } else {
      _sendToLoggingService(logMessage);
    }
  }

  /// Log info messages with consistent format
  static void logInfo(String infoType, String message, {String? context}) {
    final timestamp = DateTime.now().toIso8601String();
    final contextStr = context != null ? ' [$context]' : '';

    final logMessage = '''
🔵 INFO $infoType$contextStr
⏰ Time: $timestamp
ℹ️ Message: $message
''';

    if (kDebugMode) {
      print(logMessage);
    } else {
      _sendToLoggingService(logMessage);
    }
  }

  /// Log success messages with consistent format
  static void logSuccess(String successType, String message,
      {String? context}) {
    final timestamp = DateTime.now().toIso8601String();
    final contextStr = context != null ? ' [$context]' : '';

    final logMessage = '''
🟢 SUCCESS $successType$contextStr
⏰ Time: $timestamp
✅ Message: $message
''';

    if (kDebugMode) {
      print(logMessage);
    } else {
      _sendToLoggingService(logMessage);
    }
  }

  /// Log debug messages (only in debug mode)
  static void logDebug(String debugType, String message, {String? context}) {
    if (!kDebugMode) return;

    final timestamp = DateTime.now().toIso8601String();
    final contextStr = context != null ? ' [$context]' : '';

    final logMessage = '''
🔍 DEBUG $debugType$contextStr
⏰ Time: $timestamp
🔍 Message: $message
''';

    print(logMessage);
  }

  /// Log performance metrics
  static void logPerformance(String operation, Duration duration,
      {String? context}) {
    final timestamp = DateTime.now().toIso8601String();
    final contextStr = context != null ? ' [$context]' : '';
    final durationMs = duration.inMilliseconds;

    final logMessage = '''
⚡ PERFORMANCE $operation$contextStr
⏰ Time: $timestamp
⏱️ Duration: ${durationMs}ms
''';

    if (kDebugMode) {
      print(logMessage);
    } else {
      _sendToLoggingService(logMessage);
    }
  }

  /// Log API calls
  static void logApiCall(String endpoint, String method,
      {String? requestData, String? responseData, String? context}) {
    final timestamp = DateTime.now().toIso8601String();
    final contextStr = context != null ? ' [$context]' : '';

    final logMessage = '''
🌐 API CALL $method $endpoint$contextStr
⏰ Time: $timestamp
📤 Request: ${requestData ?? 'N/A'}
📥 Response: ${responseData ?? 'N/A'}
''';

    if (kDebugMode) {
      print(logMessage);
    } else {
      _sendToLoggingService(logMessage);
    }
  }

  /// Log database operations
  static void logDatabaseOperation(String operation, String table,
      {String? query, String? context}) {
    final timestamp = DateTime.now().toIso8601String();
    final contextStr = context != null ? ' [$context]' : '';

    final logMessage = '''
🗄️ DATABASE $operation on $table$contextStr
⏰ Time: $timestamp
🔍 Query: ${query ?? 'N/A'}
''';

    if (kDebugMode) {
      print(logMessage);
    } else {
      _sendToLoggingService(logMessage);
    }
  }

  /// Log user actions
  static void logUserAction(String action,
      {String? userId, String? details, String? context}) {
    final timestamp = DateTime.now().toIso8601String();
    final contextStr = context != null ? ' [$context]' : '';
    final userStr = userId != null ? ' (User: $userId)' : '';

    final logMessage = '''
👤 USER ACTION $action$userStr$contextStr
⏰ Time: $timestamp
📝 Details: ${details ?? 'N/A'}
''';

    if (kDebugMode) {
      print(logMessage);
    } else {
      _sendToLoggingService(logMessage);
    }
  }

  /// Log session events
  static void logSessionEvent(String event,
      {String? userId, String? sessionId, String? context}) {
    final timestamp = DateTime.now().toIso8601String();
    final contextStr = context != null ? ' [$context]' : '';
    final userStr = userId != null ? ' (User: $userId)' : '';
    final sessionStr = sessionId != null ? ' (Session: $sessionId)' : '';

    final logMessage = '''
🔐 SESSION $event$userStr$sessionStr$contextStr
⏰ Time: $timestamp
''';

    if (kDebugMode) {
      print(logMessage);
    } else {
      _sendToLoggingService(logMessage);
    }
  }

  /// Log cache operations
  static void logCacheOperation(String operation, String key,
      {String? context}) {
    final timestamp = DateTime.now().toIso8601String();
    final contextStr = context != null ? ' [$context]' : '';

    final logMessage = '''
💾 CACHE $operation$contextStr
⏰ Time: $timestamp
🔑 Key: $key
''';

    if (kDebugMode) {
      print(logMessage);
    } else {
      _sendToLoggingService(logMessage);
    }
  }

  /// Log navigation events
  static void logNavigation(String from, String to, {String? context}) {
    final timestamp = DateTime.now().toIso8601String();
    final contextStr = context != null ? ' [$context]' : '';

    final logMessage = '''
🧭 NAVIGATION $from → $to$contextStr
⏰ Time: $timestamp
''';

    if (kDebugMode) {
      print(logMessage);
    } else {
      _sendToLoggingService(logMessage);
    }
  }

  /// Log state changes
  static void logStateChange(String stateType, String oldState, String newState,
      {String? context}) {
    final timestamp = DateTime.now().toIso8601String();
    final contextStr = context != null ? ' [$context]' : '';

    final logMessage = '''
🔄 STATE CHANGE $stateType$contextStr
⏰ Time: $timestamp
📤 Old: $oldState
📥 New: $newState
''';

    if (kDebugMode) {
      print(logMessage);
    } else {
      _sendToLoggingService(logMessage);
    }
  }

  /// Send logs to external logging service (placeholder for production)
  static void _sendToLoggingService(String logMessage) {
    // In production, implement your logging service here
    // Examples: Firebase Crashlytics, Sentry, LogRocket, etc.

    // For now, we'll just print in debug mode
    // You can replace this with actual logging service calls

    // Example Firebase Crashlytics:
    // FirebaseCrashlytics.instance.log(logMessage);

    // Example Sentry:
    // Sentry.addBreadcrumb(Breadcrumb(message: logMessage));

    // Example custom logging service:
    // LoggingService.send(logMessage);
  }

  /// Log critical errors that should always be reported
  static void logCriticalError(String errorType, dynamic error,
      {String? context}) {
    final timestamp = DateTime.now().toIso8601String();
    final contextStr = context != null ? ' [$context]' : '';
    final errorMessage = error.toString();
    final stackTrace = error is Error ? error.stackTrace : null;

    final logMessage = '''
🚨 CRITICAL ERROR $errorType$contextStr
⏰ Time: $timestamp
❌ Error: $errorMessage
${stackTrace != null ? '📚 Stack Trace:\n$stackTrace' : ''}
''';

    // Always log critical errors, even in production
    print(logMessage);

    // Send to logging service immediately
    _sendToLoggingService(logMessage);

    // You might also want to send notifications for critical errors
    // _sendCriticalErrorNotification(logMessage);
  }

  /// Log silent errors (for background operations that shouldn't disturb the user)
  static void logSilentError(String errorType, dynamic error,
      {String? context}) {
    final timestamp = DateTime.now().toIso8601String();
    final contextStr = context != null ? ' [$context]' : '';
    final errorMessage = error.toString();

    final logMessage = '''
🔇 SILENT ERROR $errorType$contextStr
⏰ Time: $timestamp
❌ Error: $errorMessage
''';

    if (kDebugMode) {
      print(logMessage);
    } else {
      _sendToLoggingService(logMessage);
    }
  }
}
