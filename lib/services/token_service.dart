import 'package:get_storage/get_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:get/get.dart';
import 'package:woosh/pages/login/login_page.dart';
import 'auth_service.dart';

class TokenService {
  static final GetStorage _storage = GetStorage();

  /// Store tokens after login
  static Future<void> saveTokens(
      {required String accessToken, required String refreshToken}) async {
    await _storage.write('accessToken', accessToken);
    await _storage.write('refreshToken', refreshToken);
  }

  /// Get access token (refresh if expired)
  static Future<String?> getValidAccessToken() async {
    String? accessToken = _storage.read('accessToken');
    String? refreshToken = _storage.read('refreshToken');

    if (accessToken == null || JwtDecoder.isExpired(accessToken)) {
      // Try to refresh
      if (refreshToken == null) {
        await forceLogout();
        return null;
      }
      final response = await AuthService.instance.refreshToken(refreshToken);
      if (response['success'] == true) {
        accessToken = response['accessToken'];
        await _storage.write('accessToken', accessToken);
        // Optionally update refreshToken if backend rotates it
        return accessToken;
      } else {
        await forceLogout();
        return null;
      }
    }
    return accessToken;
  }

  /// Add Authorization header to requests
  static Future<Map<String, String>> getAuthHeaders() async {
    final token = await getValidAccessToken();
    if (token == null) throw Exception('Not authenticated');
    return {'Authorization': 'Bearer $token'};
  }

  /// Force logout: clear tokens and redirect to login
  static Future<void> forceLogout() async {
    await _storage.erase();
    Get.offAll(() => LoginPage());
  }

  /// Remove all tokens (manual logout)
  static Future<void> clearTokens() async {
    await _storage.remove('accessToken');
    await _storage.remove('refreshToken');
  }
}
