import 'package:woosh/services/database_service.dart';

/// Service for validating foreign key constraints before database operations
/// Prevents constraint failures and provides better error messages
class ForeignKeyValidationService {
  static final DatabaseService _db = DatabaseService.instance;

  /// Validate that a user exists in SalesRep table
  static Future<bool> validateUserId(int userId) async {
    try {
      const sql = 'SELECT COUNT(*) as count FROM SalesRep WHERE id = ? AND status = 0';
      final result = await _db.query(sql, [userId]);
      return (result.first.fields['count'] ?? 0) > 0;
    } catch (e) {
      print('❌ Error validating user ID $userId: $e');
      return false;
    }
  }

  /// Validate that a client exists in Clients table
  static Future<bool> validateClientId(int clientId) async {
    try {
      const sql = 'SELECT COUNT(*) as count FROM Clients WHERE id = ?';
      final result = await _db.query(sql, [clientId]);
      return (result.first.fields['count'] ?? 0) > 0;
    } catch (e) {
      print('❌ Error validating client ID $clientId: $e');
      return false;
    }
  }

  /// Validate that a journey plan exists
  static Future<bool> validateJourneyPlanId(int journeyPlanId) async {
    try {
      const sql = 'SELECT COUNT(*) as count FROM JourneyPlan WHERE id = ?';
      final result = await _db.query(sql, [journeyPlanId]);
      return (result.first.fields['count'] ?? 0) > 0;
    } catch (e) {
      print('❌ Error validating journey plan ID $journeyPlanId: $e');
      return false;
    }
  }

  /// Validate that a product exists
  static Future<bool> validateProductId(int productId) async {
    try {
      const sql = 'SELECT COUNT(*) as count FROM Product WHERE id = ?';
      final result = await _db.query(sql, [productId]);
      return (result.first.fields['count'] ?? 0) > 0;
    } catch (e) {
      print('❌ Error validating product ID $productId: $e');
      return false;
    }
  }

  /// Validate that a store exists
  static Future<bool> validateStoreId(int storeId) async {
    try {
      const sql = 'SELECT COUNT(*) as count FROM Stores WHERE id = ? AND status = 0';
      final result = await _db.query(sql, [storeId]);
      return (result.first.fields['count'] ?? 0) > 0;
    } catch (e) {
      print('❌ Error validating store ID $storeId: $e');
      return false;
    }
  }

  /// Validate that a route exists
  static Future<bool> validateRouteId(int routeId) async {
    try {
      const sql = 'SELECT COUNT(*) as count FROM Routes WHERE id = ?';
      final result = await _db.query(sql, [routeId]);
      return (result.first.fields['count'] ?? 0) > 0;
    } catch (e) {
      print('❌ Error validating route ID $routeId: $e');
      return false;
    }
  }

  /// Validate that a region exists
  static Future<bool> validateRegionId(int regionId) async {
    try {
      const sql = 'SELECT COUNT(*) as count FROM Regions WHERE id = ?';
      final result = await _db.query(sql, [regionId]);
      return (result.first.fields['count'] ?? 0) > 0;
    } catch (e) {
      print('❌ Error validating region ID $regionId: $e');
      return false;
    }
  }

  /// Validate that a country exists
  static Future<bool> validateCountryId(int countryId) async {
    try {
      const sql = 'SELECT COUNT(*) as count FROM Country WHERE id = ? AND status = 0';
      final result = await _db.query(sql, [countryId]);
      return (result.first.fields['count'] ?? 0) > 0;
    } catch (e) {
      print('❌ Error validating country ID $countryId: $e');
      return false;
    }
  }

  /// Validate multiple foreign keys at once
  static Future<Map<String, bool>> validateMultiple({
    int? userId,
    int? clientId,
    int? journeyPlanId,
    int? productId,
    int? storeId,
    int? routeId,
    int? regionId,
    int? countryId,
  }) async {
    final results = <String, bool>{};

    if (userId != null) {
      results['userId'] = await validateUserId(userId);
    }

    if (clientId != null) {
      results['clientId'] = await validateClientId(clientId);
    }

    if (journeyPlanId != null) {
      results['journeyPlanId'] = await validateJourneyPlanId(journeyPlanId);
    }

    if (productId != null) {
      results['productId'] = await validateProductId(productId);
    }

    if (storeId != null) {
      results['storeId'] = await validateStoreId(storeId);
    }

    if (routeId != null) {
      results['routeId'] = await validateRouteId(routeId);
    }

    if (regionId != null) {
      results['regionId'] = await validateRegionId(regionId);
    }

    if (countryId != null) {
      results['countryId'] = await validateCountryId(countryId);
    }

    return results;
  }

  /// Get validation error message for failed validations
  static String getValidationErrorMessage(Map<String, bool> validations) {
    final failedValidations = validations.entries
        .where((entry) => !entry.value)
        .map((entry) => entry.key)
        .toList();

    if (failedValidations.isEmpty) {
      return 'All validations passed';
    }

    return 'Foreign key validation failed for: ${failedValidations.join(', ')}';
  }

  /// Validate and throw exception if any validation fails
  static Future<void> validateAndThrow({
    int? userId,
    int? clientId,
    int? journeyPlanId,
    int? productId,
    int? storeId,
    int? routeId,
    int? regionId,
    int? countryId,
  }) async {
    final validations = await validateMultiple(
      userId: userId,
      clientId: clientId,
      journeyPlanId: journeyPlanId,
      productId: productId,
      storeId: storeId,
      routeId: routeId,
      regionId: regionId,
      countryId: countryId,
    );

    final failedValidations = validations.entries
        .where((entry) => !entry.value)
        .map((entry) => entry.key)
        .toList();

    if (failedValidations.isNotEmpty) {
      throw Exception(
        'Foreign key validation failed. Invalid references: ${failedValidations.join(', ')}'
      );
    }
  }

  /// Get current user ID with validation
  static Future<int?> getCurrentUserIdValidated() async {
    try {
      final userId = _db.getCurrentUserId();
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final isValid = await validateUserId(userId);
      if (!isValid) {
        throw Exception('Current user ID is invalid or user not found');
      }

      return userId;
    } catch (e) {
      print('❌ Error getting validated current user ID: $e');
      rethrow;
    }
  }
} 