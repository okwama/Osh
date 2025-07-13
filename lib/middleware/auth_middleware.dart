import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:woosh/controllers/auth/auth_controller.dart';
import 'package:woosh/pages/login/login_page.dart';

/// Middleware to protect routes that require authentication
class AuthMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    // Get the auth controller
    final authController = Get.find<AuthController>();

    // Check if user is logged in
    if (!authController.isLoggedIn.value) {
      print('🔒 AuthMiddleware: User not authenticated, redirecting to login');

      // Show a snackbar to inform the user
      Get.snackbar(
        'Authentication Required',
        'Please log in to access this page',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );

      // Redirect to login page
      return const RouteSettings(name: '/login');
    }

    // User is authenticated, allow access
    print('✅ AuthMiddleware: User authenticated, allowing access to $route');
    return null;
  }

  @override
  void onPageDispose() {
    // Cleanup if needed
    super.onPageDispose();
  }
}

/// Middleware for routes that should only be accessible when NOT logged in
class GuestMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    // Get the auth controller
    final authController = Get.find<AuthController>();

    // Check if user is logged in
    if (authController.isLoggedIn.value) {
      print(
          '🔒 GuestMiddleware: User already authenticated, redirecting to home');

      // Redirect to home page
      return const RouteSettings(name: '/home');
    }

    // User is not authenticated, allow access to guest pages
    print(
        '✅ GuestMiddleware: User not authenticated, allowing access to $route');
    return null;
  }
}
