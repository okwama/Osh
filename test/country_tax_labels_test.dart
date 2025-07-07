import 'package:flutter_test/flutter_test.dart';
import 'package:woosh/utils/country_tax_labels.dart';

void main() {
  group('CountryTaxLabels', () {
    test('should return correct label for Kenya (countryId: 1)', () {
      expect(CountryTaxLabels.getTaxPinLabel(1), equals('KRA PIN'));
    });

    test('should return correct label for Tanzania (countryId: 2)', () {
      expect(CountryTaxLabels.getTaxPinLabel(2), equals('TIN Number'));
    });

    test('should return correct label for Nigeria (countryId: 3)', () {
      expect(CountryTaxLabels.getTaxPinLabel(3),
          equals('Tax Identification Number (TIN)'));
    });

    test('should return default label for unknown country', () {
      expect(CountryTaxLabels.getTaxPinLabel(999), equals('Tax PIN'));
    });

    test('should return default label for null countryId', () {
      expect(CountryTaxLabels.getTaxPinLabel(null), equals('Tax PIN'));
    });

    test('should return unmodifiable map for getAllLabels', () {
      final labels = CountryTaxLabels.getAllLabels();
      expect(
          () => labels[1] = 'Modified Label', throwsA(isA<UnsupportedError>()));
    });
  });
}
