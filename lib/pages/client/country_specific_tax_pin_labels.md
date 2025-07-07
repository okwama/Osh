# Country-Specific Tax PIN Labels Implementation

## Overview

The application serves multiple countries with different tax identification systems. To provide a localized user experience, the tax PIN field label should dynamically change based on the user's country. For example, users in Tanzania see "TIN Number", users in Nigeria see "Tax Identification Number (TIN)", and users in Kenya see "KRA PIN". This approach ensures users see familiar terminology that matches their local tax system requirements.

## Implementation Strategy

The simplest and most efficient method is to implement a frontend mapping system using the existing database structure. Since the `Clients` model already contains a `countryId` field that relates to the `Country` model, we can create a simple dictionary mapping in the Flutter app that associates each country ID with its corresponding tax PIN label. This approach requires no database schema changes, no backend API modifications, and provides instant label resolution without additional network requests. The mapping can be easily maintained and extended as new countries are added to the system, making it a scalable solution that prioritizes performance and simplicity.

## Implementation Details

### Utility Class: `CountryTaxLabels`

Located at `lib/utils/country_tax_labels.dart`, this utility class provides:

- **Static mapping**: Country IDs to their corresponding tax PIN labels
- **Default fallback**: Returns "Tax PIN" for unknown countries
- **Null safety**: Handles null country IDs gracefully
- **Immutability**: Returns unmodifiable maps for security

### Current Country Mappings

```dart
static const Map<int, String> _taxPinLabels = {
  1: 'KRA PIN', // Kenya
  2: 'TIN Number', // Tanzania
  3: 'Tax Identification Number (TIN)', // Nigeria
  // Add more countries as needed
};
```

### Usage Examples

#### In Forms (Add Client Page)
```dart
TextFormField(
  controller: _kraPinController,
  decoration: InputDecoration(
    labelText: CountryTaxLabels.getTaxPinLabel(_countryId),
    border: const OutlineInputBorder(),
  ),
),
```

#### In Display Pages (Client Details)
```dart
_detailSection(
  icon: Icons.badge,
  label: CountryTaxLabels.getTaxPinLabel(widget.outlet.countryId),
  value: outlet.taxPin ?? '-',
),
```

## Testing

The implementation includes comprehensive tests in `test/country_tax_labels_test.dart` that verify:

- Correct labels for known countries
- Default label for unknown countries
- Null safety handling
- Map immutability

Run tests with: `flutter test test/country_tax_labels_test.dart`

## Adding New Countries

To add support for a new country:

1. Add the country ID and label to the `_taxPinLabels` map in `CountryTaxLabels`
2. Update the test file with the new country's test case
3. The change will automatically apply to all forms and display pages

## Benefits

- **Localized UX**: Users see familiar terminology
- **Zero backend changes**: Pure frontend implementation
- **Performance**: No additional API calls
- **Maintainable**: Easy to add new countries
- **Consistent**: Same logic across all pages 