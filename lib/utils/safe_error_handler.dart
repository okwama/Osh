import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Safe error handler utility to ensure no raw errors are shown to users
class SafeErrorHandler {
  /// Get user-friendly error message
  static String getUserFriendlyMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('timeout')) {
      return 'Request timed out. Please try again.';
    }
    if (errorString.contains('connection') || errorString.contains('network')) {
      return 'Network connection error. Please check your internet connection.';
    }
    if (errorString.contains('socket')) {
      return 'Connection lost. Please try again.';
    }
    if (errorString.contains('unauthorized') || errorString.contains('401')) {
      return 'Session expired. Please log in again.';
    }
    if (errorString.contains('forbidden') || errorString.contains('403')) {
      return 'Access denied. You don\'t have permission for this action.';
    }
    if (errorString.contains('not found') || errorString.contains('404')) {
      return 'Resource not found.';
    }
    if (errorString.contains('server') || errorString.contains('5')) {
      return 'Server error. Please try again later.';
    }
    if (errorString.contains('database') || errorString.contains('mysql')) {
      return 'Database connection error. Please try again.';
    }
    if (errorString.contains('authentication') ||
        errorString.contains('auth')) {
      return 'Authentication failed. Please try again.';
    }

    return 'Something went wrong. Please try again.';
  }

  /// Sanitize error for logging (never show to users)
  static String sanitizeErrorForLogging(dynamic error) {
    final errorString = error.toString();

    // Remove sensitive information
    String sanitized = errorString
        .replaceAll(
            RegExp(r'password[=:]\s*\S+', caseSensitive: false), 'password=***')
        .replaceAll(
            RegExp(r'token[=:]\s*\S+', caseSensitive: false), 'token=***')
        .replaceAll(
            RegExp(r'phone[=:]\s*\S+', caseSensitive: false), 'phone=***')
        .replaceAll(
            RegExp(r'email[=:]\s*\S+', caseSensitive: false), 'email=***')
        .replaceAll(
            RegExp(r'user[=:]\s*\S+', caseSensitive: false), 'user=***');

    return sanitized;
  }

  /// Safe SnackBar that filters raw errors
  static void showSnackBar(
    BuildContext context,
    dynamic error, {
    Color? backgroundColor,
    Duration? duration,
    bool isSuccess = false,
  }) {
    final message = getUserFriendlyMessage(error);

    Get.snackbar(
      isSuccess ? 'Success' : 'Error',
      message,
      backgroundColor:
          backgroundColor ?? (isSuccess ? Colors.green : Colors.red),
      colorText: Colors.white,
      duration: duration ?? const Duration(seconds: 4),
      snackPosition: SnackPosition.TOP,
    );
  }

  /// Safe error handler for async operations
  static Future<T> safeAsyncOperation<T>(
    Future<T> Function() operation, {
    T? fallbackValue,
    String? customErrorMessage,
  }) async {
    try {
      return await operation();
    } catch (e) {
      final message = customErrorMessage ?? getUserFriendlyMessage(e);
      showSnackBar(Get.context!, message);

      if (fallbackValue != null) {
        return fallbackValue;
      }
      rethrow;
    }
  }

  /// Handle errors without showing to user (for background operations)
  static void handleSilentError(dynamic error, {String? context}) {
    // Only log sanitized error for debugging
    final sanitizedError = sanitizeErrorForLogging(error);
    // In production, you might send this to a logging service
    // but never expose raw errors to users
  }

  /// Validate that no raw errors are being shown
  static bool containsRawError(String message) {
    final rawErrorPatterns = [
      'exception',
      'error:',
      'failed:',
      'stack trace',
      'socketexception',
      'timeoutexception',
      'sqlexception',
    ];

    final lowerMessage = message.toLowerCase();
    return rawErrorPatterns.any((pattern) => lowerMessage.contains(pattern));
  }

  /// Ensure message is safe for user display
  static String ensureSafeMessage(String message) {
    if (containsRawError(message)) {
      return getUserFriendlyMessage(message);
    }
    return message;
  }
}

/// Extension to make error handling even easier
extension SafeErrorExtension on dynamic {
  /// Check if this is a network error
  bool get isNetworkError {
    final errorString = toString().toLowerCase();
    return errorString.contains('socket') ||
        errorString.contains('connection') ||
        errorString.contains('network') ||
        errorString.contains('timeout');
  }

  /// Check if this is a server error
  bool get isServerError {
    final errorString = toString().toLowerCase();
    return errorString.contains('500') ||
        errorString.contains('501') ||
        errorString.contains('502') ||
        errorString.contains('503') ||
        errorString.contains('504');
  }
}
