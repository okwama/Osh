// import 'package:flutter/material.dart';
// import 'package:woosh/utils/error_handler.dart';
// import 'package:woosh/utils/safe_error_handler.dart';

// /// App-wide error handling wrapper
// /// Use this instead of direct ScaffoldMessenger or Get.snackbar calls
// class AppErrorHandler {
//   /// NEVER use these methods directly - they can show raw errors:
//   /// - ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())))
//   /// - Get.snackbar('Error', error.toString())
//   /// - print(error.toString()) in production

//   /// ALWAYS use these safe methods instead:

//   /// Show error message safely (filters raw errors)
//   static void showError(BuildContext context, dynamic error) {
//     SafeErrorHandler.showSnackBar(context, error);
//   }

//   /// Show success message
//   static void showSuccess(BuildContext context, String message) {
//     SafeErrorHandler.showSuccess(context, message);
//   }

//   /// Show error with Get.snackbar (filters raw errors)
//   static void showGetError(dynamic error, {VoidCallback? onRetry}) {
//     SafeErrorHandler.showGetSnackBar(error, onRetry: onRetry);
//   }

//   /// Show success with Get.snackbar
//   static void showGetSuccess(String message) {
//     SafeErrorHandler.showGetSuccess(message);
//   }

//   /// Show error dialog (filters raw errors)
//   static Future<void> showErrorDialog(
//     BuildContext context,
//     dynamic error, {
//     VoidCallback? onRetry,
//   }) {
//     return SafeErrorHandler.showErrorDialog(context, error, onRetry: onRetry);
//   }

//   /// Handle API errors globally
//   static void handleApiError(dynamic error) {
//     GlobalErrorHandler.handleApiError(error);
//   }

//   /// Log errors safely (for debugging only)
//   static void logError(dynamic error, {String? context}) {
//     GlobalErrorHandler.logError(error, context: context);
//   }
// }

// /// Extension methods for easy error handling
// extension ErrorHandlingExtension on BuildContext {
//   /// Show error safely
//   void showError(dynamic error) {
//     AppErrorHandler.showError(this, error);
//   }

//   /// Show success message
//   void showSuccess(String message) {
//     AppErrorHandler.showSuccess(this, message);
//   }

//   /// Show error dialog
//   Future<void> showErrorDialog(dynamic error, {VoidCallback? onRetry}) {
//     return AppErrorHandler.showErrorDialog(this, error, onRetry: onRetry);
//   }
// }

// /// Usage Examples:
// ///
// /// ? CORRECT - Safe error handling:
// /// ```dart
// /// try {
// ///   await someApiCall();
// ///   context.showSuccess('Operation completed successfully');
// /// } catch (e) {
// ///   context.showError(e); // This will show user-friendly message
// ///   AppErrorHandler.logError(e, context: 'SomeOperation'); // For debugging
// /// }
// /// ```
// ///
// /// ? CORRECT - With retry:
// /// ```dart
// /// try {
// ///   await someApiCall();
// /// } catch (e) {
// ///   AppErrorHandler.showGetError(e, onRetry: () => someApiCall());
// /// }
// /// ```
// ///
// /// ? WRONG - Raw error exposure:
// /// ```dart
// /// catch (e) {
// ///   ScaffoldMessenger.of(context).showSnackBar(
// ///     SnackBar(content: Text(e.toString())), // DON'T DO THIS
// ///   );
// /// }
// /// ```
// ///
// /// ? WRONG - Raw error in Get.snackbar:
// /// ```dart
// /// catch (e) {
// ///   Get.snackbar('Error', e.toString()); // DON'T DO THIS
// /// }
// /// ```
// ///
// /// ? WRONG - Raw error in dialog:
// /// ```dart
// /// catch (e) {
// ///   showDialog(
// ///     context: context,
// ///     builder: (context) => AlertDialog(
// ///       content: Text(e.toString()), // DON'T DO THIS
// ///     ),
// ///   );
// /// }
// /// ```
