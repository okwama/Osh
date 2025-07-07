import 'dart:convert';
import 'package:get_storage/get_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

/// Service for managing JWT tokens
class TokenService {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static final _storage = GetStorage();

  /// Store access and refresh tokens
  static Future<void> storeTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(_accessTokenKey, accessToken);
    await _storage.write(_refreshTokenKey, refreshToken);
  }

  /// Get access token
  static String? getAccessToken() {
    return _storage.read(_accessTokenKey);
  }

  /// Get refresh token
  static String? getRefreshToken() {
    return _storage.read(_refreshTokenKey);
  }

  /// Check if token is expired
  static bool isTokenExpired() {
    final token = getAccessToken();
    if (token == null) return true;

    try {
      return JwtDecoder.isExpired(token);
    } catch (e) {
      return true;
    }
  }

  /// Clear all tokens
  static Future<void> clearTokens() async {
    await _storage.remove(_accessTokenKey);
    await _storage.remove(_refreshTokenKey);
  }

  /// Get token payload
  static Map<String, dynamic>? getTokenPayload() {
    final token = getAccessToken();
    if (token == null) return null;

    try {
      return JwtDecoder.decode(token);
    } catch (e) {
      return null;
    }
  }

  /// Check if user is authenticated
  static bool isAuthenticated() {
    final token = getAccessToken();
    if (token == null) return false;

    try {
      return !JwtDecoder.isExpired(token);
    } catch (e) {
      return false;
    }
  }
} 