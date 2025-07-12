import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Optimistic UI handler that provides immediate feedback and handles errors silently
class OptimisticUIHandler {
  static const int maxRetries = 3;
  static const Duration baseRetryDelay = Duration(seconds: 2);
  static const Duration connectivityCheckInterval = Duration(seconds: 5);

  /// Check if device has internet connectivity
  static Future<bool> _hasConnectivity() async {
    try {
      final connectivityResults = await Connectivity().checkConnectivity();
      return !connectivityResults.contains(ConnectivityResult.none);
    } catch (e) {
      // If connectivity check fails, assume we have connection
      return true;
    }
  }

  /// Wait for connectivity to be restored before retrying
  static Future<void> _waitForConnectivity() async {
    print('🌐 Waiting for network connectivity to be restored...');

    // Listen to connectivity changes
    final completer = Completer<void>();
    late StreamSubscription<List<ConnectivityResult>> subscription;

    subscription = Connectivity().onConnectivityChanged.listen((results) {
      if (!results.contains(ConnectivityResult.none)) {
        print('🌐 Network connectivity restored: $results');
        subscription.cancel();
        completer.complete();
      }
    });

    // Also periodically check connectivity in case the stream doesn't fire
    final timer = Timer.periodic(connectivityCheckInterval, (timer) async {
      if (await _hasConnectivity()) {
        print('🌐 Network connectivity detected via periodic check');
        timer.cancel();
        subscription.cancel();
        if (!completer.isCompleted) {
          completer.complete();
        }
      }
    });

    // Wait for connectivity to be restored
    await completer.future;
    timer.cancel();
  }

  /// Show optimistic success immediately, retry in background if operation fails
  static Future<void> optimisticUpdate<T>({
    required String successMessage,
    required Future<T> Function() operation,
    required VoidCallback onOptimisticSuccess,
    VoidCallback? onFinalSuccess,
    VoidCallback? onFinalFailure,
    bool showSuccessMessage = true,
    String? loadingMessage,
  }) async {
    // 1. Show immediate optimistic success
    onOptimisticSuccess();

    if (showSuccessMessage) {
      _showOptimisticSuccess(successMessage);
    }

    // 2. Perform actual operation in background with retries
    _performWithRetries(
      operation: operation,
      onSuccess: onFinalSuccess,
      onFailure: onFinalFailure,
      loadingMessage: loadingMessage,
    );
  }

  /// Perform operation with silent background retries
  static Future<void> _performWithRetries<T>({
    required Future<T> Function() operation,
    VoidCallback? onSuccess,
    VoidCallback? onFailure,
    String? loadingMessage,
    int retryCount = 0,
  }) async {
    try {
      await operation();
      onSuccess?.call();
      print('✅ Background operation completed successfully');
    } catch (e) {
      print('🔄 Background operation failed (attempt ${retryCount + 1}): $e');

      // Check if it's a database circuit breaker issue
      if (e.toString().contains('Circuit breaker is open')) {
        print('🚨 Database circuit breaker is open - skipping retries');
        onFailure?.call();
        return;
      }

      if (retryCount < maxRetries) {
        // Check if it's a network-related error
        if (shouldRetryInBackground(e)) {
          print('🌐 Network error detected, checking connectivity...');

          // Check if we have connectivity
          final hasConnection = await _hasConnectivity();

          if (hasConnection) {
            // We have connection but operation failed - use exponential backoff
            final delay =
                Duration(seconds: baseRetryDelay.inSeconds * (retryCount + 1));
            print('🔄 Retrying in ${delay.inSeconds}s (connection available)');

            Timer(delay, () {
              _performWithRetries(
                operation: operation,
                onSuccess: onSuccess,
                onFailure: onFailure,
                loadingMessage: loadingMessage,
                retryCount: retryCount + 1,
              );
            });
          } else {
            // No connection - wait for connectivity to be restored
            print('🌐 No connectivity detected, waiting for network...');
            _waitForConnectivityAndRetry(
              operation: operation,
              onSuccess: onSuccess,
              onFailure: onFailure,
              loadingMessage: loadingMessage,
              retryCount: retryCount,
            );
          }
        } else {
          // Non-network error - use regular exponential backoff
          final delay =
              Duration(seconds: baseRetryDelay.inSeconds * (retryCount + 1));
          print('🔄 Non-network error, retrying in ${delay.inSeconds}s');

          Timer(delay, () {
            _performWithRetries(
              operation: operation,
              onSuccess: onSuccess,
              onFailure: onFailure,
              loadingMessage: loadingMessage,
              retryCount: retryCount + 1,
            );
          });
        }
      } else {
        print('❌ All retries exhausted for background operation');
        onFailure?.call();
        // Don't show error to user - operation already succeeded optimistically
      }
    }
  }

  /// Wait for connectivity and then retry the operation
  static Future<void> _waitForConnectivityAndRetry<T>({
    required Future<T> Function() operation,
    VoidCallback? onSuccess,
    VoidCallback? onFailure,
    String? loadingMessage,
    required int retryCount,
  }) async {
    try {
      // Wait for connectivity to be restored
      await _waitForConnectivity();

      // Retry the operation once connectivity is restored
      print('🔄 Connectivity restored, retrying operation...');
      await _performWithRetries(
        operation: operation,
        onSuccess: onSuccess,
        onFailure: onFailure,
        loadingMessage: loadingMessage,
        retryCount: retryCount + 1,
      );
    } catch (e) {
      print('❌ Failed to wait for connectivity: $e');
      onFailure?.call();
    }
  }

  /// Show optimistic success message
  static void _showOptimisticSuccess(String message) {
    Get.snackbar(
      'Success',
      message,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
      icon: const Icon(Icons.check_circle, color: Colors.white),
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
    );
  }

  /// Handle completion with navigation
  static Future<void> optimisticComplete({
    required String successMessage,
    required Future<void> Function() operation,
    required VoidCallback onOptimisticSuccess,
    String? navigationRoute,
    VoidCallback? onNavigate,
    VoidCallback? onFinalSuccess,
  }) async {
    // 1. Show immediate success
    onOptimisticSuccess();
    _showOptimisticSuccess(successMessage);

    // 2. Navigate immediately if specified
    if (navigationRoute != null) {
      Get.offAllNamed(navigationRoute);
    } else if (onNavigate != null) {
      onNavigate();
    }

    // 3. Perform actual operation in background
    _performWithRetries(
      operation: operation,
      onSuccess: onFinalSuccess,
      onFailure: () {
        print('❌ Background completion failed - but user already saw success');
      },
    );
  }

  /// Silent background operation (no user feedback)
  static Future<void> silentBackground<T>({
    required Future<T> Function() operation,
    VoidCallback? onSuccess,
    VoidCallback? onFailure,
    String? operationName,
  }) async {
    _performWithRetries(
      operation: operation,
      onSuccess: onSuccess,
      onFailure: onFailure,
      loadingMessage: operationName,
    );
  }

  /// Show loading state briefly then hide
  static void showBriefLoading(String message) {
    Get.snackbar(
      'Processing',
      message,
      backgroundColor: Colors.blue,
      colorText: Colors.white,
      duration: const Duration(milliseconds: 800),
      showProgressIndicator: true,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
    );
  }

  /// Update entity optimistically then sync in background
  static Future<void> optimisticEntityUpdate<T>({
    required T optimisticEntity,
    required Future<T> Function() serverUpdate,
    required Function(T) onEntityUpdate,
    String? successMessage,
  }) async {
    // 1. Update UI immediately with optimistic data
    onEntityUpdate(optimisticEntity);

    if (successMessage != null) {
      _showOptimisticSuccess(successMessage);
    }

    // 2. Sync with server in background
    _performWithRetries(
      operation: serverUpdate,
      onSuccess: () {
        print('✅ Entity synced with server successfully');
      },
      onFailure: () {
        print('❌ Entity sync failed - keeping optimistic state');
      },
    );
  }

  /// Check if error should be retried silently
  static bool shouldRetryInBackground(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('timeout') ||
        errorString.contains('connection') ||
        errorString.contains('network') ||
        errorString.contains('socket') ||
        errorString.contains('temporary');
  }

  /// Log error for debugging without showing to user
  static void logSilentError(dynamic error, {String? context}) {
    final prefix = context != null ? '[$context]' : '';
    print('🔇 Silent error $prefix: $error');
  }
}
