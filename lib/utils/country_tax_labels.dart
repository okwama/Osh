class CountryTaxLabels {
  /// Maps country IDs to their corresponding tax PIN labels
  static const Map<int, String> _taxPinLabels = {
    1: 'KRA PIN', // Kenya
    2: 'TIN Number', // Tanzania
    3: 'Tax Identification Number (TIN)', // Nigeria
    // Add more countries as needed
  };

  /// Default label when country is not found
  static const String _defaultLabel = 'Tax PIN';

  /// Get the appropriate tax PIN label for a given country ID
  static String getTaxPinLabel(int? countryId) {
    if (countryId == null) return _defaultLabel;
    return _taxPinLabels[countryId] ?? _defaultLabel;
  }

  /// Get all available country tax labels
  static Map<int, String> getAllLabels() {
    return Map.unmodifiable(_taxPinLabels);
  }
}
