class CountryCurrencyLabels {
  /// Maps country IDs to their corresponding currency information
  static const Map<int, Map<String, dynamic>> _currencyInfo = {
    1: {
      'symbol': 'KES',
      'position': 'before',
      'decimalPlaces': 2,
      'name': 'Kenyan Shilling'
    },
    2: {
      'symbol': 'TZS',
      'position': 'after',
      'decimalPlaces': 0,
      'name': 'Tanzania Shilling'
    },
    3: {
      'symbol': '₦',
      'position': 'before',
      'decimalPlaces': 2,
      'name': 'Nigerian Naira'
    }
  };

  /// Default currency when country is not found
  static const Map<String, dynamic> _defaultCurrency = {
    'symbol': 'KES',
    'position': 'before',
    'decimalPlaces': 2,
    'name': 'Kenyan Shilling'
  };

  /// Format currency value with appropriate symbol and positioning
  static String formatCurrency(double? amount, int? countryId) {
    // Handle null amount
    if (amount == null) {
      return '${getCurrencyInfo(countryId)['symbol']} 0.00';
    }

    final currency = getCurrencyInfo(countryId);
    final formattedAmount = amount.toStringAsFixed(currency['decimalPlaces']);

    if (currency['position'] == 'before') {
      return '${currency['symbol']} $formattedAmount';
    } else {
      return '$formattedAmount ${currency['symbol']}';
    }
  }

  /// Get currency information for a given country ID
  static Map<String, dynamic> getCurrencyInfo(int? countryId) {
    if (countryId == null) return _defaultCurrency;
    return _currencyInfo[countryId] ?? _defaultCurrency;
  }

  /// Get currency symbol for a given country ID
  static String getCurrencySymbol(int? countryId) {
    return getCurrencyInfo(countryId)['symbol'];
  }

  /// Get currency name for a given country ID
  static String getCurrencyName(int? countryId) {
    return getCurrencyInfo(countryId)['name'];
  }

  /// Get all available currency information
  static Map<int, Map<String, dynamic>> getAllCurrencies() {
    return Map.unmodifiable(_currencyInfo);
  }
}
