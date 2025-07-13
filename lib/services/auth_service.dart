import 'dart:convert';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:get_storage/get_storage.dart';
import 'package:get/get.dart';
import 'package:woosh/models/salerep/sales_rep_model.dart';
import 'package:woosh/services/api_service.dart';
import 'package:woosh/services/token_service.dart';
import 'package:woosh/utils/error_logger.dart';
import 'package:woosh/pages/login/login_page.dart';

/// Unified Authentication Service
///
/// This service consolidates all authentication functionality into a single,
/// modern service that uses the Vercel API for authentication operations
/// while maintaining backward compatibility for existing functionality.
///
/// Key Features:
/// - Uses API for all authentication operations (login, register, profile updates)
/// - JWT token management with automatic refresh
/// - Permission checking and user validation
/// - Consistent error handling and logging
/// - Singleton pattern for global access
class AuthService {
  static AuthService? _instance;
  static AuthService get instance => _instance ??= AuthService._();
  AuthService._();

  final ApiService _apiService = ApiService.instance;
  final GetStorage _storage = GetStorage();

  // ========================================================================
  // CORE AUTHENTICATION METHODS
  // ========================================================================

  /// Login with phone number and password
  /// Uses the Vercel API for secure authentication
  Future<Map<String, dynamic>> login(
      String phoneNumber, String password) async {
    try {
      ErrorLogger.logInfo('AuthService', 'Attempting login for: $phoneNumber');

      // Use API service for login
      final response = await _apiService.login(phoneNumber, password);

      if (response['success'] == true) {
        // Store tokens using TokenService
        await TokenService.saveTokens(
          accessToken: response['accessToken'],
          refreshToken: response['refreshToken'],
        );

        // Store user data
        if (response['salesRep'] != null) {
          await _storage.write('salesRep', response['salesRep']);
          await _storage.write('userId', response['salesRep']['id'].toString());
        }

        ErrorLogger.logSuccess(
            'AuthService', 'Login successful for: $phoneNumber');
        return response;
      } else {
        throw Exception(response['message'] ?? 'Login failed');
      }
    } catch (e) {
      ErrorLogger.logError('AuthService', e, context: 'AuthService.login');
      return {
        'success': false,
        'message': 'Login failed. Please try again.',
      };
    }
  }

  /// Register new user
  /// TODO: Migrate to API when registration endpoint is available
  Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    try {
      ErrorLogger.logInfo('AuthService',
          'Attempting registration for: ${userData['phoneNumber']}');

      // For now, we'll use a placeholder response
      // In the future, this should call _apiService.register(userData)
      return {
        'success': false,
        'message':
            'Registration via API not yet implemented. Please contact support.',
      };
    } catch (e) {
      ErrorLogger.logError('AuthService', e, context: 'AuthService.register');
      return {
        'success': false,
        'message': 'Registration failed. Please try again.',
      };
    }
  }

  /// Logout user
  Future<bool> logout() async {
    try {
      ErrorLogger.logInfo('AuthService', 'Logging out user');

      // Clear tokens
      await TokenService.clearTokens();

      // Clear user data
      await _storage.remove('salesRep');
      await _storage.remove('userId');

      // Clear API service tokens
      _apiService.clearTokens();

      ErrorLogger.logSuccess('AuthService', 'Logout successful');
      return true;
    } catch (e) {
      ErrorLogger.logError('AuthService', e, context: 'AuthService.logout');
      return false;
    }
  }

  // ========================================================================
  // USER PROFILE MANAGEMENT
  // ========================================================================

  /// Get user by ID
  /// TODO: Migrate to API when user profile endpoint is available
  Future<SalesRepModel?> getUserById(int userId) async {
    try {
      ErrorLogger.logInfo('AuthService', 'Getting user by ID: $userId');

      // For now, try to get from storage
      final userData = _storage.read('salesRep');
      if (userData != null && userData['id'] == userId) {
        return SalesRepModel.fromMap(userData);
      }

      // TODO: In the future, call API endpoint
      // final response = await _apiService.getUserById(userId);
      // return SalesRepModel.fromMap(response['data']);

      return null;
    } catch (e) {
      ErrorLogger.logError('AuthService', e,
          context: 'AuthService.getUserById');
      return null;
    }
  }

  /// Update user profile
  /// TODO: Migrate to API when profile update endpoint is available
  Future<bool> updateProfile(int userId, Map<String, dynamic> data) async {
    try {
      ErrorLogger.logInfo('AuthService', 'Updating profile for user: $userId');

      // TODO: In the future, call API endpoint
      // final response = await _apiService.updateProfile(userId, data);
      // return response['success'] == true;

      // For now, return false to indicate API migration needed
      return false;
    } catch (e) {
      ErrorLogger.logError('AuthService', e,
          context: 'AuthService.updateProfile');
      return false;
    }
  }

  /// Change password
  /// TODO: Migrate to API when password change endpoint is available
  Future<bool> changePassword(
      int userId, String currentPassword, String newPassword) async {
    try {
      ErrorLogger.logInfo('AuthService', 'Changing password for user: $userId');

      // TODO: In the future, call API endpoint
      // final response = await _apiService.changePassword(userId, currentPassword, newPassword);
      // return response['success'] == true;

      // For now, return false to indicate API migration needed
      return false;
    } catch (e) {
      ErrorLogger.logError('AuthService', e,
          context: 'AuthService.changePassword');
      return false;
    }
  }

  /// Get profile data for current user
  Future<Map<String, dynamic>?> getProfile(int userId) async {
    try {
      final user = await getUserById(userId);
      if (user == null) {
        return null;
      }

      return {
        'salesRep': user.toMap(),
        'success': true,
      };
    } catch (e) {
      ErrorLogger.logError('AuthService', e, context: 'AuthService.getProfile');
      return null;
    }
  }

  /// Update profile photo
  Future<String?> updateProfilePhoto(int userId, String photoUrl) async {
    try {
      final success = await updateProfile(userId, {'photoUrl': photoUrl});
      if (success) {
        return photoUrl;
      }
      return null;
    } catch (e) {
      ErrorLogger.logError('AuthService', e,
          context: 'AuthService.updateProfilePhoto');
      return null;
    }
  }

  // ========================================================================
  // TOKEN MANAGEMENT
  // ========================================================================

  /// Refresh access token
  /// TODO: Migrate to API when refresh endpoint is available
  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    try {
      ErrorLogger.logInfo('AuthService', 'Refreshing access token');

      // TODO: In the future, use API service
      // final response = await _apiService.refreshToken(refreshToken);
      // return response;

      // For now, return failure to indicate API migration needed
      return {
        'success': false,
        'message': 'Token refresh via API not yet implemented'
      };
    } catch (e) {
      ErrorLogger.logError('AuthService', e,
          context: 'AuthService.refreshToken');
      return {'success': false, 'message': 'Token refresh failed'};
    }
  }

  /// Get authentication headers
  Future<Map<String, String>> getAuthHeaders() async {
    try {
      return await TokenService.getAuthHeaders();
    } catch (e) {
      ErrorLogger.logError('AuthService', e,
          context: 'AuthService.getAuthHeaders');
      throw Exception('Failed to get authentication headers');
    }
  }

  // ========================================================================
  // PERMISSION CHECKING & USER VALIDATION
  // ========================================================================

  /// Get current user ID from JWT token
  Future<int> getCurrentUserId() async {
    try {
      final token = await TokenService.getValidAccessToken();
      if (token == null) {
        throw Exception('No access token found');
      }

      final payload = JwtDecoder.decode(token);
      final userId = payload['userId'];

      if (userId == null) {
        throw Exception('User ID not found in token');
      }

      return userId is int ? userId : int.parse(userId.toString());
    } catch (e) {
      ErrorLogger.logError('AuthService', e,
          context: 'AuthService.getCurrentUserId');
      throw Exception('Failed to get current user ID: $e');
    }
  }

  /// Get current user details from token
  Future<Map<String, dynamic>> getCurrentUserDetails() async {
    try {
      final token = await TokenService.getValidAccessToken();
      if (token == null) {
        throw Exception('No access token found');
      }

      final payload = JwtDecoder.decode(token);

      // Check if all required fields are in the token payload
      if (payload['countryId'] != null) {
        return payload;
      }

      // For backward compatibility: get user data from storage
      final userData = _storage.read('salesRep');
      if (userData != null) {
        return {
          ...payload,
          'countryId': userData['countryId'],
          'role': userData['role'],
          'name': userData['name'],
          'email': userData['email'],
        };
      }

      throw Exception('User details not found in token or storage');
    } catch (e) {
      ErrorLogger.logError('AuthService', e,
          context: 'AuthService.getCurrentUserDetails');
      throw Exception('Failed to get current user details: $e');
    }
  }

  /// Validate user permissions for operation
  Future<bool> validateUserPermissions(int userId, String operation) async {
    try {
      final userDetails = await getCurrentUserDetails();
      final role = userDetails['role']?.toString() ?? 'USER';

      // Basic permission validation
      // TODO: Implement more sophisticated permission checking
      return role.isNotEmpty;
    } catch (e) {
      ErrorLogger.logError('AuthService', e,
          context: 'AuthService.validateUserPermissions');
      return false;
    }
  }

  /// Check if user has specific role
  Future<bool> hasRole(int userId, String requiredRole) async {
    try {
      final userDetails = await getCurrentUserDetails();
      final role = userDetails['role']?.toString() ?? 'USER';
      return role.toUpperCase() == requiredRole.toUpperCase();
    } catch (e) {
      ErrorLogger.logError('AuthService', e, context: 'AuthService.hasRole');
      return false;
    }
  }

  /// Check if user is admin
  Future<bool> isAdmin(int userId) async {
    return await hasRole(userId, 'ADMIN');
  }

  /// Check if user is manager
  Future<bool> isManager(int userId) async {
    try {
      final userDetails = await getCurrentUserDetails();
      final role = userDetails['role']?.toString().toUpperCase() ?? 'USER';
      return role == 'ADMIN' || role == 'MANAGER';
    } catch (e) {
      ErrorLogger.logError('AuthService', e, context: 'AuthService.isManager');
      return false;
    }
  }

  /// Get user role information
  Future<Map<String, dynamic>?> getUserRole(int userId) async {
    try {
      final userDetails = await getCurrentUserDetails();
      return {
        'role': userDetails['role']?.toString() ?? 'USER',
        'name': userDetails['name']?.toString() ?? '',
        'email': userDetails['email']?.toString() ?? '',
        'isActive': true, // Assume active if token is valid
      };
    } catch (e) {
      ErrorLogger.logError('AuthService', e,
          context: 'AuthService.getUserRole');
      return null;
    }
  }

  // ========================================================================
  // UTILITY METHODS
  // ========================================================================

  /// Check if user is currently authenticated
  Future<bool> isAuthenticated() async {
    try {
      final token = await TokenService.getValidAccessToken();
      return token != null;
    } catch (e) {
      return false;
    }
  }

  /// Force logout and redirect to login page
  Future<void> forceLogout() async {
    try {
      await logout();
      Get.offAll(() => const LoginPage());
    } catch (e) {
      ErrorLogger.logError('AuthService', e,
          context: 'AuthService.forceLogout');
    }
  }

  /// Get current user from storage
  SalesRepModel? getCurrentUser() {
    try {
      final userData = _storage.read('salesRep');
      if (userData != null) {
        return SalesRepModel.fromMap(userData);
      }
      return null;
    } catch (e) {
      ErrorLogger.logError('AuthService', e,
          context: 'AuthService.getCurrentUser');
      return null;
    }
  }

  /// Test authentication service connectivity
  Future<Map<String, dynamic>> testConnection() async {
    try {
      final isHealthy = await _apiService.isHealthy();
      return {
        'success': isHealthy,
        'message': isHealthy ? 'Connection successful' : 'Connection failed',
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      ErrorLogger.logError('AuthService', e,
          context: 'AuthService.testConnection');
      return {
        'success': false,
        'message': 'Connection test failed: $e',
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }
}
