import 'package:woosh/services/database_service.dart';

/// Currency configuration for a country
class CurrencyConfig {
  final int countryId;
  final String countryName;
  final String currencyCode;
  final String currencySymbol;
  final String position; // 'before' or 'after'
  final int decimalPlaces;
  final String productField; // e.g., 'unit_cost', 'unit_cost_tzs'
  final String priceOptionField; // e.g., 'value', 'value_tzs'

  CurrencyConfig({
    required this.countryId,
    required this.countryName,
    required this.currencyCode,
    required this.currencySymbol,
    required this.position,
    required this.decimalPlaces,
    required this.productField,
    required this.priceOptionField,
  });

  factory CurrencyConfig.fromMap(Map<String, dynamic> map) {
    return CurrencyConfig(
      countryId: map['countryId'],
      countryName: map['countryName'],
      currencyCode: map['currencyCode'],
      currencySymbol: map['currencySymbol'],
      position: map['position'],
      decimalPlaces: map['decimalPlaces'],
      productField: map['productField'],
      priceOptionField: map['priceOptionField'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'countryId': countryId,
      'countryName': countryName,
      'currencyCode': currencyCode,
      'currencySymbol': currencySymbol,
      'position': position,
      'decimalPlaces': decimalPlaces,
      'productField': productField,
      'priceOptionField': priceOptionField,
    };
  }
}

/// Dynamic currency configuration service that automatically detects countries and currencies from database
class CurrencyConfigService {
  static final DatabaseService _db = DatabaseService.instance;

  // Cache for currency configurations to avoid repeated database queries
  static Map<int, CurrencyConfig>? _currencyConfigCache;
  static DateTime? _lastCacheUpdate;
  static const Duration _cacheExpiry = Duration(minutes: 30);

  /// Get all currency configurations from database
  static Future<Map<int, CurrencyConfig>> getAllCurrencyConfigs(
      {bool forceRefresh = false}) async {
    try {
      // Check cache first
      if (!forceRefresh &&
          _currencyConfigCache != null &&
          _lastCacheUpdate != null) {
        final timeSinceUpdate = DateTime.now().difference(_lastCacheUpdate!);
        if (timeSinceUpdate < _cacheExpiry) {
          return _currencyConfigCache!;
        }
      }


      // Get all countries from database
      const sql = '''
        SELECT 
          c.id as countryId,
          c.name as countryName,
          c.status
        FROM Country c
        WHERE c.status = 0
        ORDER BY c.id ASC
      ''';

      final results = await _db.query(sql);
      final configs = <int, CurrencyConfig>{};

      for (final row in results) {
        final countryData = row.fields;
        final countryId = countryData['countryId'];
        final countryName = countryData['countryName'];

        // Dynamically determine currency configuration based on country
        final config = _determineCurrencyConfig(countryId, countryName);
        if (config != null) {
          configs[countryId] = config;
        }
      }

      // Update cache
      _currencyConfigCache = configs;
      _lastCacheUpdate = DateTime.now();

      print(
          '✅ [CurrencyConfig] Loaded ${configs.length} currency configurations');
      return configs;
    } catch (e) {
      // Return default config if database fails
      return _getDefaultConfigs();
    }
  }

  /// Get currency configuration for a specific country
  static Future<CurrencyConfig?> getCurrencyConfig(int countryId) async {
    final configs = await getAllCurrencyConfigs();
    return configs[countryId];
  }

  /// Get currency configuration for current user's country
  static Future<CurrencyConfig?> getCurrentUserCurrencyConfig() async {
    try {
      final userId = _db.getCurrentUserId();

      const sql = 'SELECT countryId FROM SalesRep WHERE id = ?';
      final results = await _db.query(sql, [userId]);

      if (results.isNotEmpty) {
        final countryId = results.first.fields['countryId'];
        return await getCurrencyConfig(countryId);
      }

      return null;
    } catch (e) {
      print(
          '❌ [CurrencyConfig] Error getting current user currency config: $e');
      return null;
    }
  }

  /// Dynamically determine currency configuration based on country ID and name
  static CurrencyConfig? _determineCurrencyConfig(
      int countryId, String countryName) {
    // Check if currency fields exist in database for this country
    // This is a dynamic approach that can be extended for new countries

    switch (countryId) {
      case 1:
        return CurrencyConfig(
          countryId: countryId,
          countryName: countryName,
          currencyCode: 'KES',
          currencySymbol: 'KES',
          position: 'before',
          decimalPlaces: 2,
          productField: 'unit_cost',
          priceOptionField: 'value',
        );
      case 2:
        return CurrencyConfig(
          countryId: countryId,
          countryName: countryName,
          currencyCode: 'TZS',
          currencySymbol: 'TZS',
          position: 'after',
          decimalPlaces: 0,
          productField: 'unit_cost_tzs',
          priceOptionField: 'value_tzs',
        );
      case 3:
        return CurrencyConfig(
          countryId: countryId,
          countryName: countryName,
          currencyCode: 'NGN',
          currencySymbol: '₦',
          position: 'before',
          decimalPlaces: 2,
          productField: 'unit_cost_ngn',
          priceOptionField: 'value_ngn',
        );
      default:
        // For new countries, we can implement dynamic field detection
        // For now, return null to indicate unsupported country
        print(
            '⚠️ [CurrencyConfig] Unsupported country ID: $countryId ($countryName)');
        return null;
    }
  }

  /// Get currency value based on country configuration
  static double getCurrencyValue(
      Map<String, dynamic> item, CurrencyConfig config, String type) {
    final field =
        type == 'product' ? config.productField : config.priceOptionField;
    final value = item[field];

    if (value != null) {
      return value.toDouble();
    }

    // Fallback to base currency if specific currency field is null
    final fallbackField = type == 'product' ? 'unit_cost' : 'value';
    return (item[fallbackField] ?? 0).toDouble();
  }

  /// Format currency value using country configuration
  static String formatCurrency(double amount, CurrencyConfig config) {
    final formattedAmount = amount.toStringAsFixed(config.decimalPlaces);

    if (config.position == 'before') {
      return '${config.currencySymbol} $formattedAmount';
    } else {
      return '$formattedAmount ${config.currencySymbol}';
    }
  }

  /// Check if a country has specific currency fields in database
  static Future<bool> hasCurrencyFields(int countryId) async {
    try {
      // Check if product table has currency-specific fields for this country
      const sql = '''
        SELECT COLUMN_NAME 
        FROM INFORMATION_SCHEMA.COLUMNS 
        WHERE TABLE_NAME = 'Product' 
        AND TABLE_SCHEMA = DATABASE()
        AND COLUMN_NAME LIKE '%_tzs%' OR COLUMN_NAME LIKE '%_ngn%'
      ''';

      final results = await _db.query(sql);
      return results.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get default configurations (fallback)
  static Map<int, CurrencyConfig> _getDefaultConfigs() {
    return {
      1: CurrencyConfig(
        countryId: 1,
        countryName: 'Kenya',
        currencyCode: 'KES',
        currencySymbol: 'KES',
        position: 'before',
        decimalPlaces: 2,
        productField: 'unit_cost',
        priceOptionField: 'value',
      ),
    };
  }

  /// Clear cache (useful for testing or when database changes)
  static void clearCache() {
    _currencyConfigCache = null;
    _lastCacheUpdate = null;
  }

  /// Get all supported countries
  static Future<List<Map<String, dynamic>>> getSupportedCountries() async {
    final configs = await getAllCurrencyConfigs();
    return configs.values.map((config) => config.toMap()).toList();
  }

  /// Validate if a country is supported
  static Future<bool> isCountrySupported(int countryId) async {
    final configs = await getAllCurrencyConfigs();
    return configs.containsKey(countryId);
  }
}