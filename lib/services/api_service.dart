import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:woosh/config/database_config.dart';
import 'package:woosh/utils/error_logger.dart';

/// API Service for communicating with Vercel serverless functions
/// This service provides a drop-in replacement for direct database calls
class ApiService {
  static const String baseUrl = DatabaseConfig.apiUrl;

  // Singleton pattern
  static ApiService? _instance;
  static ApiService get instance => _instance ??= ApiService._();
  ApiService._();

  // Authentication token
  String? _accessToken;
  String? _refreshToken;

  /// Set authentication tokens
  void setTokens(String accessToken, String refreshToken) {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
  }

  /// Clear authentication tokens
  void clearTokens() {
    _accessToken = null;
    _refreshToken = null;
  }

  /// Get headers with authentication
  Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
    };

    if (_accessToken != null) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }

    return headers;
  }

  /// Execute a SQL query via API
  /// This is a drop-in replacement for DatabaseService.query()
  Future<List<Map<String, dynamic>>> query(String sql,
      [List<Object?>? values]) async {
    try {
      ErrorLogger.logInfo('API Service', 'Executing query: $sql');

      final response = await http
          .post(
            Uri.parse('$baseUrl/query'),
            headers: _headers,
            body: json.encode({
              'sql': sql,
              'values': values ?? [],
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          // Handle both single objects and arrays
          final dynamic rawData = data['data'];
          final List<Map<String, dynamic>> results;

          if (rawData is List) {
            results = List<Map<String, dynamic>>.from(rawData);
          } else if (rawData is Map) {
            results = [Map<String, dynamic>.from(rawData)];
          } else {
            results = [];
          }

          ErrorLogger.logSuccess('API Service',
              'Query executed successfully. Rows: ${results.length}');
          return results;
        } else {
          throw Exception('API Error: ${data['error']}');
        }
      } else if (response.statusCode == 401) {
        // Token expired, try to refresh
        await _refreshAccessToken();
        // Retry the query
        return await query(sql, values);
      } else {
        throw Exception(
            'HTTP Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      ErrorLogger.logError('API Service', e, context: 'ApiService.query');
      rethrow;
    }
  }

  /// Execute a transaction via API
  Future<T> transaction<T>(Future<T> Function() operation) async {
    // For now, execute the operation directly
    // In the future, we can implement proper transaction support
    return await operation();
  }

  /// Login user and get tokens
  Future<Map<String, dynamic>> login(
      String phoneNumber, String password) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'phoneNumber': phoneNumber,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          // Store tokens
          _accessToken = data['accessToken'];
          _refreshToken = data['refreshToken'];

          ErrorLogger.logSuccess('API Service',
              'Login successful for user: ${data['salesRep']['name']}');
          return data;
        } else {
          throw Exception('Login failed: ${data['error']}');
        }
      } else {
        throw Exception(
            'HTTP Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      ErrorLogger.logError('API Service', e, context: 'ApiService.login');
      rethrow;
    }
  }

  /// Refresh access token
  Future<void> _refreshAccessToken() async {
    if (_refreshToken == null) {
      throw Exception('No refresh token available');
    }

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/refresh'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'refreshToken': _refreshToken,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          _accessToken = data['accessToken'];
          ErrorLogger.logSuccess('API Service', 'Token refreshed successfully');
        } else {
          throw Exception('Token refresh failed: ${data['error']}');
        }
      } else {
        throw Exception('Token refresh HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      ErrorLogger.logError('API Service', e,
          context: 'ApiService._refreshAccessToken');
      // Clear tokens on refresh failure
      clearTokens();
      rethrow;
    }
  }

  /// Health check
  Future<bool> isHealthy() async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/query'),
            headers: _headers,
            body: json.encode({
              'sql': 'SELECT 1 as health_check',
              'values': [],
            }),
          )
          .timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      ErrorLogger.logError('API Service', e, context: 'ApiService.isHealthy');
      return false;
    }
  }

  /// Test connection
  Future<Map<String, dynamic>> testConnection() async {
    try {
      final startTime = DateTime.now();
      final isHealthy = await this.isHealthy();
      final endTime = DateTime.now();

      return {
        'success': isHealthy,
        'responseTime': endTime.difference(startTime).inMilliseconds,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }
}
