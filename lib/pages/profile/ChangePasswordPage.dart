import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:woosh/controllers/profile_controller.dart';
import 'package:woosh/utils/app_theme.dart';
import 'package:woosh/widgets/gradient_app_bar.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  _ChangePasswordPageState createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final ProfileController controller = Get.put(ProfileController());

  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _changePassword() async {
    // Reset error/success messages
    controller.passwordError.value = '';
    controller.passwordSuccess.value = '';

    // Validate all fields are filled
    if (_currentPasswordController.text.isEmpty ||
        _newPasswordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      Get.snackbar('Error', 'All fields are required.');
      return;
    }

    // Validate password match
    if (_newPasswordController.text != _confirmPasswordController.text) {
      Get.snackbar('Error', 'New passwords do not match.');
      return;
    }

    // Validate password strength
    if (_newPasswordController.text.length < 8) {
      Get.snackbar('Error', 'Password must be at least 8 characters long.');
      return;
    }

    try {
      // Call API to update password
      print('CHANGE PASSWORD: Attempting to change password');
      await controller.updatePassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
        confirmPassword: _confirmPasswordController.text,
      );
      print('CHANGE PASSWORD: API call completed');
      print('CHANGE PASSWORD: Success: ${controller.passwordSuccess.value}');
      print('CHANGE PASSWORD: Error: ${controller.passwordError.value}');

      // Check for success and navigate back if successful
      if (controller.passwordSuccess.value.isNotEmpty) {
        // Show success message
        Get.snackbar('Success', controller.passwordSuccess.value,
            backgroundColor: Colors.green.withOpacity(0.1),
            colorText: Colors.green[700],
            duration: const Duration(seconds: 3));

        // Delay navigation to allow user to see success message
        Future.delayed(const Duration(seconds: 1), () {
          Get.back(); // Return to previous screen
        });
      } else if (controller.passwordError.value.isNotEmpty) {
        // Show error message
        Get.snackbar('Error', controller.passwordError.value,
            backgroundColor: Colors.red.withOpacity(0.1),
            colorText: Colors.red[700],
            duration: const Duration(seconds: 3));
      } else {
        // If neither success nor error message is set
        Get.snackbar('Error', 'Unknown error occurred. Please try again.',
            backgroundColor: Colors.red.withOpacity(0.1),
            colorText: Colors.red[700]);
      }
    } catch (e) {
      print('CHANGE PASSWORD: Exception caught: $e');
      Get.snackbar('Error', 'An unexpected error occurred: $e',
          backgroundColor: Colors.red.withOpacity(0.1),
          colorText: Colors.red[700]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBackground,
      appBar: GradientAppBar(
        title: 'Change Password',
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: CreamGradientCard(
          borderWidth: 0,
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          margin: EdgeInsets.zero,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _currentPasswordController,
                obscureText: _obscureCurrentPassword,
                decoration: InputDecoration(
                  labelText: 'Current Password',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureCurrentPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureCurrentPassword = !_obscureCurrentPassword;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _newPasswordController,
                obscureText: _obscureNewPassword,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  helperText: 'Password must be at least 8 characters long',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureNewPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureNewPassword = !_obscureNewPassword;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  labelText: 'Confirm New Password',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Obx(() => SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: GoldGradientButton(
                      onPressed: controller.isPasswordUpdating.value
                          ? () {}
                          : _changePassword,
                      child: controller.isPasswordUpdating.value
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Change Password',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
