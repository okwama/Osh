import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:woosh/utils/error_logger.dart';

/// Centralized error handling system for the app
class ErrorHandler {
  static final ErrorHandler _instance = ErrorHandler._internal();
  factory ErrorHandler() => _instance;
  ErrorHandler._internal();

  /// Handle database connection errors
  static void handleDatabaseError(dynamic error, {String? context}) {
    ErrorLogger.logError('Database Error', error, context: context);

    String userMessage =
        'Unable to connect to database. Please check your internet connection and try again.';

    if (error.toString().contains('timeout')) {
      userMessage = 'Request timed out. Please try again.';
    } else if (error.toString().contains('connection')) {
      userMessage =
          'Network connection issue. Please check your internet connection.';
    } else if (error.toString().contains('permission')) {
      userMessage = 'Access denied. Please contact your administrator.';
    }

    _showErrorSnackbar(userMessage);
  }

  /// Handle authentication errors
  static void handleAuthError(dynamic error, {String? context}) {
    ErrorLogger.logError('Authentication Error', error, context: context);

    String userMessage = 'Authentication failed. Please try logging in again.';

    if (error.toString().contains('invalid_credentials')) {
      userMessage = 'Invalid username or password. Please try again.';
    } else if (error.toString().contains('session_expired')) {
      userMessage = 'Your session has expired. Please log in again.';
    } else if (error.toString().contains('account_locked')) {
      userMessage = 'Account is locked. Please contact your administrator.';
    } else if (error.toString().contains('insufficient_permissions')) {
      userMessage = 'You don\'t have permission to perform this action.';
    }

    _showErrorSnackbar(userMessage);
  }

  /// Handle network errors
  static void handleNetworkError(dynamic error, {String? context}) {
    ErrorLogger.logError('Network Error', error, context: context);

    String userMessage =
        'Network error occurred. Please check your connection and try again.';

    if (error.toString().contains('timeout')) {
      userMessage = 'Request timed out. Please try again.';
    } else if (error.toString().contains('no_internet')) {
      userMessage =
          'No internet connection. Please check your network settings.';
    } else if (error.toString().contains('server_error')) {
      userMessage =
          'Server is temporarily unavailable. Please try again later.';
    }

    _showErrorSnackbar(userMessage);
  }

  /// Handle validation errors
  static void handleValidationError(dynamic error, {String? context}) {
    ErrorLogger.logError('Validation Error', error, context: context);

    String userMessage = 'Please check your input and try again.';

    if (error.toString().contains('required')) {
      userMessage = 'Please fill in all required fields.';
    } else if (error.toString().contains('invalid_format')) {
      userMessage = 'Invalid format. Please check your input.';
    } else if (error.toString().contains('too_short')) {
      userMessage = 'Input is too short. Please provide more information.';
    } else if (error.toString().contains('too_long')) {
      userMessage = 'Input is too long. Please shorten your input.';
    }

    _showErrorSnackbar(userMessage);
  }

  /// Handle file operation errors
  static void handleFileError(dynamic error, {String? context}) {
    ErrorLogger.logError('File Error', error, context: context);

    String userMessage = 'File operation failed. Please try again.';

    if (error.toString().contains('permission')) {
      userMessage = 'Permission denied. Please check file permissions.';
    } else if (error.toString().contains('not_found')) {
      userMessage = 'File not found. Please check the file path.';
    } else if (error.toString().contains('corrupted')) {
      userMessage =
          'File appears to be corrupted. Please try a different file.';
    } else if (error.toString().contains('too_large')) {
      userMessage = 'File is too large. Please choose a smaller file.';
    }

    _showErrorSnackbar(userMessage);
  }

  /// Handle image processing errors
  static void handleImageError(dynamic error, {String? context}) {
    ErrorLogger.logError('Image Error', error, context: context);

    String userMessage = 'Image processing failed. Please try again.';

    if (error.toString().contains('unsupported_format')) {
      userMessage = 'Unsupported image format. Please use JPG, PNG, or GIF.';
    } else if (error.toString().contains('corrupted')) {
      userMessage =
          'Image file appears to be corrupted. Please try a different image.';
    } else if (error.toString().contains('too_large')) {
      userMessage = 'Image is too large. Please choose a smaller image.';
    }

    _showErrorSnackbar(userMessage);
  }

  /// Handle session errors
  static void handleSessionError(dynamic error, {String? context}) {
    ErrorLogger.logError('Session Error', error, context: context);

    String userMessage = 'Session error occurred. Please try again.';

    if (error.toString().contains('expired')) {
      userMessage = 'Session has expired. Please log in again.';
    } else if (error.toString().contains('invalid')) {
      userMessage = 'Invalid session. Please log in again.';
    } else if (error.toString().contains('conflict')) {
      userMessage = 'Another session is active. Please end it first.';
    }

    _showErrorSnackbar(userMessage);
  }

  /// Handle general errors with custom message
  static void handleGeneralError(dynamic error,
      {String? context, String? customMessage}) {
    ErrorLogger.logError('General Error', error, context: context);

    String userMessage =
        customMessage ?? 'An unexpected error occurred. Please try again.';
    _showErrorSnackbar(userMessage);
  }

  /// Handle silent errors (log only, no user notification)
  static void handleSilentError(dynamic error, {String? context}) {
    ErrorLogger.logError('Silent Error', error, context: context);
    // No user notification for silent errors
  }

  /// Show error dialog with retry option
  static Future<bool> showErrorDialog({
    required String title,
    required String message,
    String? retryText,
    String? cancelText,
  }) async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(cancelText ?? 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(retryText ?? 'Retry'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  /// Show error snackbar
  static void _showErrorSnackbar(String message) {
    if (Get.isSnackbarOpen) {
      Get.closeCurrentSnackbar();
    }

    Get.snackbar(
      'Error',
      message,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      duration: const Duration(seconds: 4),
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(8),
      borderRadius: 8,
      icon: const Icon(Icons.error_outline, color: Colors.white),
    );
  }

  /// Show success snackbar
  static void showSuccessSnackbar(String message) {
    if (Get.isSnackbarOpen) {
      Get.closeCurrentSnackbar();
    }

    Get.snackbar(
      'Success',
      message,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(8),
      borderRadius: 8,
      icon: const Icon(Icons.check_circle, color: Colors.white),
    );
  }

  /// Show warning snackbar
  static void showWarningSnackbar(String message) {
    if (Get.isSnackbarOpen) {
      Get.closeCurrentSnackbar();
    }

    Get.snackbar(
      'Warning',
      message,
      backgroundColor: Colors.orange,
      colorText: Colors.white,
      duration: const Duration(seconds: 4),
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(8),
      borderRadius: 8,
      icon: const Icon(Icons.warning_amber, color: Colors.white),
    );
  }

  /// Show info snackbar
  static void showInfoSnackbar(String message) {
    if (Get.isSnackbarOpen) {
      Get.closeCurrentSnackbar();
    }

    Get.snackbar(
      'Info',
      message,
      backgroundColor: Colors.blue,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(8),
      borderRadius: 8,
      icon: const Icon(Icons.info_outline, color: Colors.white),
    );
  }

  /// Handle async operations with error handling
  static Future<T?> handleAsyncOperation<T>({
    required Future<T> Function() operation,
    String? errorContext,
    String? customErrorMessage,
    bool showError = true,
  }) async {
    try {
      return await operation();
    } catch (error) {
      if (showError) {
        handleGeneralError(error,
            context: errorContext, customMessage: customErrorMessage);
      } else {
        handleSilentError(error, context: errorContext);
      }
      return null;
    }
  }

  /// Handle async operations with specific error types
  static Future<T?> handleAsyncOperationWithType<T>({
    required Future<T> Function() operation,
    required void Function(dynamic error) errorHandler,
    String? errorContext,
  }) async {
    try {
      return await operation();
    } catch (error) {
      errorHandler(error);
      ErrorLogger.logError('Async Operation Error', error,
          context: errorContext);
      return null;
    }
  }
}
