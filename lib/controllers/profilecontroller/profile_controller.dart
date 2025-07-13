import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:get_storage/get_storage.dart';
import 'package:woosh/services/auth_service.dart';
import 'package:woosh/services/core/session_service.dart';
import 'package:woosh/models/salerep/sales_rep_model.dart';

class ProfileController extends GetxController {
  final storage = GetStorage();

  Rx<XFile?> selectedImage = Rx<XFile?>(null);
  RxBool isLoading = false.obs;
  RxString userName = ''.obs;
  RxString userEmail = ''.obs;
  RxString userPhone = ''.obs;
  RxString photoUrl = ''.obs;
  RxString userRole = ''.obs;
  RxString userRegion = ''.obs;
  RxString userDepartment = ''.obs;

  // Password update fields
  final RxBool isPasswordUpdating = false.obs;
  final RxString passwordError = ''.obs;
  final RxString passwordSuccess = ''.obs;

  // Profile caching
  Map<String, dynamic>? _cachedProfile;
  DateTime? _lastProfileFetch;
  static const Duration _profileCacheValidity =
      Duration(minutes: 5); // Cache for 5 minutes

  @override
  void onInit() {
    super.onInit();
    loadUserData();
    fetchProfile();
  }

  void loadUserData() {
    final userData = storage.read('salesRep');
    if (userData != null) {
      userName.value = userData['name'] ?? '';
      userEmail.value = userData['email'] ?? '';
      userPhone.value = userData['phoneNumber'] ?? '';
      photoUrl.value = userData['photoUrl'] ?? '';
      userRole.value = userData['role'] ?? '';
      userRegion.value = userData['region'] ?? '';
      userDepartment.value = userData['department'] ?? '';
    }
  }

  Future<void> fetchProfile({bool forceRefresh = false}) async {
    try {
      // Get current user ID from storage
      final userId = storage.read('userId');
      if (userId == null) {
        throw Exception('User ID not found');
      }

      // Check if we have valid cached data
      if (!forceRefresh &&
          _cachedProfile != null &&
          _lastProfileFetch != null) {
        final timeSinceLastFetch =
            DateTime.now().difference(_lastProfileFetch!);
        if (timeSinceLastFetch < _profileCacheValidity) {
          print(
              '📋 Using cached profile data (cached ${timeSinceLastFetch.inSeconds}s ago)');
          _updateProfileFromData(_cachedProfile!);
          return;
        }
      }

      final response =
          await AuthService.instance.getProfile(int.parse(userId.toString()));

      if (response == null) {
        throw Exception('No response received from AuthService');
      }

      final userData = response['salesRep'];

      if (userData != null) {
        // Update cache
        _cachedProfile = userData;
        _lastProfileFetch = DateTime.now();

        _updateProfileFromData(userData);

        // Update storage with full user data
        storage.write('salesRep', userData);
      } else {
        throw Exception('User data is null in response');
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to fetch profile data: ${e.toString().replaceAll('Exception: ', '')}',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Get.theme.colorScheme.error.withOpacity(0.1),
        colorText: Get.theme.colorScheme.error,
      );
    }
  }

  void _updateProfileFromData(Map<String, dynamic> userData) {
    userName.value = userData['name'] ?? '';
    userEmail.value = userData['email'] ?? '';
    userPhone.value = userData['phoneNumber'] ?? '';
    photoUrl.value = userData['photoUrl'] ?? '';
    userRole.value = userData['role'] ?? '';
    userRegion.value = userData['region'] ?? '';
    userDepartment.value = userData['department'] ?? '';
  }

  /// Clear profile cache
  void clearProfileCache() {
    _cachedProfile = null;
    _lastProfileFetch = null;
  }

  /// Force refresh profile data (bypass cache)
  Future<void> refreshProfile() async {
    await fetchProfile(forceRefresh: true);
  }

  Future<void> pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null) {
        selectedImage.value = image;
        await updateProfilePhoto();
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to pick image: ${e.toString()}',
        snackPosition: SnackPosition.TOP,
      );
    }
  }

  Future<void> updateProfilePhoto() async {
    if (selectedImage.value == null) return;

    try {
      isLoading.value = true;

      // Get current user ID from storage
      final userId = storage.read('userId');
      if (userId == null) {
        throw Exception('User ID not found');
      }

      // For now, we'll use a placeholder URL since we need to implement file upload
      // In a real implementation, you would upload the file to a server and get the URL
      final photoUrl =
          'https://example.com/uploads/${DateTime.now().millisecondsSinceEpoch}.jpg';

      final updatedPhotoUrl = await AuthService.instance.updateProfilePhoto(
        int.parse(userId.toString()),
        photoUrl,
      );

      if (updatedPhotoUrl != null) {
        this.photoUrl.value = updatedPhotoUrl;
      }

      // Update storage
      final storedUser =
          storage.read('salesRep') as Map<String, dynamic>? ?? {};
      storedUser['photoUrl'] = photoUrl;
      storage.write('salesRep', storedUser);

      Get.snackbar(
        'Success',
        'Profile photo updated successfully',
        snackPosition: SnackPosition.TOP,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString().replaceAll('Exception: ', ''),
        snackPosition: SnackPosition.TOP,
        backgroundColor: Get.theme.colorScheme.error.withOpacity(0.1),
        colorText: Get.theme.colorScheme.error,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Session management methods
  Future<dynamic> getCurrentSession(int userId) async {
    return await SessionService.getCurrentSession(userId);
  }

  Future<Map<String, dynamic>> startSession(int userId) async {
    return await SessionService.startSession(userId);
  }

  Future<void> endSession(int sessionId) async {
    await SessionService.endSession(sessionId);
  }

  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      // Reset status messages
      passwordError.value = '';
      passwordSuccess.value = '';
      isPasswordUpdating.value = true;

      // Validate passwords
      if (currentPassword.isEmpty ||
          newPassword.isEmpty ||
          confirmPassword.isEmpty) {
        passwordError.value = 'All fields are required';
        return;
      }

      if (newPassword != confirmPassword) {
        passwordError.value = 'New passwords do not match';
        return;
      }

      if (newPassword.length < 8) {
        passwordError.value = 'Password must be at least 8 characters long';
        return;
      }

      // Get current user ID from storage
      final userId = storage.read('userId');
      if (userId == null) {
        passwordError.value = 'User ID not found';
        return;
      }

      // Call AuthService to update password
      final success = await AuthService.instance.changePassword(
        int.parse(userId.toString()),
        currentPassword,
        newPassword,
      );

      if (success) {
        passwordSuccess.value = 'Password updated successfully';
      } else {
        passwordError.value = 'Failed to update password';
        print('PROFILE CONTROLLER: Password update failed');
      }
    } catch (e) {
      passwordError.value = 'An error occurred: ${e.toString()}';
    } finally {
      isPasswordUpdating.value = false;
    }
  }

  /// Clear all app caches
  Future<void> clearAllCaches() async {
    try {
      // Clear image cache
      ImageCache().clear();
      ImageCache().clearLiveImages();

      // Clear session cache
      SessionService.clearCache();

      // Clear profile cache
      clearProfileCache();

      // Clear GetStorage cache
      final keys = storage.getKeys();
      for (final key in keys) {
        if (key.startsWith('cache_') ||
            key.startsWith('outlets_') ||
            key.startsWith('products_') ||
            key.startsWith('routes_') ||
            key.startsWith('notices_') ||
            key.startsWith('clients_') ||
            key.startsWith('orders_')) {
          storage.remove(key);
        }
      }

      Get.snackbar(
        'Success',
        'App cache cleared successfully',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to clear cache: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
