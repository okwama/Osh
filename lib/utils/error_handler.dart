import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:woosh/services/token_service.dart';
import 'package:woosh/controllers/auth/auth_controller.dart';

class GlobalErrorHandler {
  // Flag to prevent multiple error dialogs
  static bool _isShowingError = false;

  /// Main error handler - filters all errors and shows user-friendly messages
  static void handleApiError(dynamic error, {bool showToast = true}) {

    // Never show raw errors to users
    final userFriendlyMessage = getUserFriendlyMessage(error);
    final errorType = _getErrorType(error);

    switch (errorType) {
      case ErrorType.authentication:
        _handleAuthError(error);
        break;
      case ErrorType.network:
        if (showToast) {
          Get.snackbar(
            'Connection Error',
            userFriendlyMessage,
            backgroundColor: Colors.orange,
            colorText: Colors.white,
            duration: const Duration(seconds: 4),
          );
        }
        break;
      case ErrorType.server:
      case ErrorType.client:
      case ErrorType.validation:
      case ErrorType.unknown:
        if (showToast) {
          _showUserFriendlyError(userFriendlyMessage);
        }
        break;
    }
  }

  /// Get user-friendly message based on error
  static String getUserFriendlyMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();

    // Timeout errors (check before network errors)
    if (_isTimeoutError(errorString)) {
      return "The request is taking too long. Please try again.";
    }

    // Validation errors (check before client errors)
    if (_isValidationError(errorString)) {
      return "Please check your input and try again.";
    }

    // Network errors
    if (_isNetworkError(errorString)) {
      return "Please check your internet connection and try again.";
    }

    // Server errors (5xx)
    if (_isServerError(errorString)) {
      return "Our servers are temporarily unavailable. Please try again later.";
    }

    // Client errors (4xx)
    if (_isClientError(errorString)) {
      if (errorString.contains('401') || errorString.contains('unauthorized')) {
        return "Your session has expired. Please log in again.";
      }
      if (errorString.contains('403') || errorString.contains('forbidden')) {
        return "You don't have permission to perform this action.";
      }
      if (errorString.contains('404') || errorString.contains('not found')) {
        return "The requested information could not be found.";
      }
      if (errorString.contains('429') || errorString.contains('rate limit')) {
        return "Too many requests. Please wait a moment and try again.";
      }
      return "There was an issue with your request. Please try again.";
    }

    // Default fallback
    return "Something went wrong. Please try again.";
  }

  /// Determine error type for handling
  static ErrorType _getErrorType(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (_isAuthError(errorString)) {
      return ErrorType.authentication;
    }
    if (_isTimeoutError(errorString)) {
      return ErrorType.network; // Treat timeouts as network errors
    }
    if (_isValidationError(errorString)) {
      return ErrorType.validation;
    }
    if (_isNetworkError(errorString)) {
      return ErrorType.network;
    }
    if (_isServerError(errorString)) {
      return ErrorType.server;
    }
    if (_isClientError(errorString)) {
      return ErrorType.client;
    }

    return ErrorType.unknown;
  }

  /// Check if error is network-related
  static bool _isNetworkError(String errorString) {
    return errorString.contains('socketexception') ||
        errorString.contains('connection timeout') ||
        errorString.contains('network error') ||
        errorString.contains('connection refused') ||
        errorString.contains('no internet') ||
        errorString.contains('xmlhttprequest error') ||
        errorString.contains('failed to connect') ||
        errorString.contains('failed to fetch') ||
        errorString.contains('clientexception') ||
        errorString.contains('connection failed');
  }

  /// Check if error is server-related (5xx)
  static bool _isServerError(String errorString) {
    return errorString.contains('500') ||
        errorString.contains('501') ||
        errorString.contains('502') ||
        errorString.contains('503') ||
        errorString.contains('504') ||
        errorString.contains('505') ||
        errorString.contains('internal server error') ||
        errorString.contains('bad gateway') ||
        errorString.contains('service unavailable') ||
        errorString.contains('gateway timeout');
  }

  /// Check if error is client-related (4xx)
  static bool _isClientError(String errorString) {
    return errorString.contains('400') ||
        errorString.contains('401') ||
        errorString.contains('403') ||
        errorString.contains('404') ||
        errorString.contains('405') ||
        errorString.contains('409') ||
        errorString.contains('422') ||
        errorString.contains('429') ||
        errorString.contains('bad request') ||
        errorString.contains('unauthorized') ||
        errorString.contains('forbidden') ||
        errorString.contains('not found') ||
        errorString.contains('conflict') ||
        errorString.contains('unprocessable') ||
        errorString.contains('rate limit');
  }

  /// Check if error is authentication-related
  static bool _isAuthError(String errorString) {
    return errorString.contains('authentication required') ||
        errorString.contains('session expired') ||
        errorString.contains('token refreshed, retry request') ||
        errorString.contains('unauthorized') ||
        errorString.contains('401');
  }

  /// Check if error is timeout-related
  static bool _isTimeoutError(String errorString) {
    return (errorString.contains('timeout') &&
            !errorString.contains('connection timeout') &&
            !errorString.contains('gateway timeout')) ||
        errorString.contains('timeoutexception') ||
        errorString.contains('operation timed out');
  }

  /// Check if error is validation-related
  static bool _isValidationError(String errorString) {
    return errorString.contains('validation') ||
        errorString.contains('invalid') ||
        errorString.contains('required') ||
        errorString.contains('422');
  }

  /// Handle authentication errors
  static void _handleAuthError(dynamic error) {
    if (error.toString().contains('Token refreshed, retry request')) {
      // Token was refreshed, this is not an error - just retry the request
      return;
    }

    // Clear tokens and redirect to login
    TokenService.clearTokens();

    // Show user-friendly message
    _showUserFriendlyError(
      'Your session has expired. Please log in again.',
      backgroundColor: Colors.orange,
      duration: const Duration(seconds: 3),
    );

    // Redirect to login
    Get.offAllNamed('/login');
  }

  /// Show user-friendly error message
  static void _showUserFriendlyError(
    String message, {
    Color backgroundColor = Colors.red,
    Duration duration = const Duration(seconds: 4),
  }) {
    if (_isShowingError) return;

    _isShowingError = true;
    Get.snackbar(
      'Error',
      message,
      backgroundColor: backgroundColor,
      colorText: Colors.white,
      duration: duration,
      onTap: (_) => _isShowingError = false,
    );

    // Reset flag after duration
    Future.delayed(duration, () {
      _isShowingError = false;
    });
  }

  /// Log errors safely (for debugging only)
  static void logError(dynamic error, {String? context}) {
    final contextStr = context != null ? ' [$context]' : '';

    // In production, you might want to send this to a logging service
    // but never expose raw errors to users
  }
}

/// Error types for categorization
enum ErrorType {
  authentication,
  network,
  server,
  client,
  validation,
  unknown,
}