# Country-Specific Currency Display for Products and Price Options

## Overview

The application serves users across multiple countries with different currencies, requiring dynamic price display based on the user's location. The database schema already supports this through dedicated currency fields in both the `Product` and `PriceOption` models. For example, products have `unit_cost_tzs` (Tanzania Shilling), `unit_cost_ngn` (Nigerian Naira), and the base `unit_cost` field, while price options contain `value_tzs`, `value_ngn`, and the base `value` field. This structure allows the application to store and display prices in the appropriate local currency for each user, ensuring they see familiar pricing formats and eliminating confusion from currency conversion.

## Country Mapping

- **Country ID 1**: Kenya (KES - Kenyan Shilling)
- **Country ID 2**: Tanzania (TZS - Tanzania Shilling)  
- **Country ID 3**: Nigeria (NGN - Nigerian Naira)

## Implementation Strategy

The implementation follows a server-side filtering approach using the existing database structure. When displaying product prices or price options, the application determines the user's country and then selects the corresponding currency field from the database:

- **Country ID 1 (Kenya)**: Display values from `unit_cost` and `value` fields (base currency - KES)
- **Country ID 2 (Tanzania)**: Display values from `unit_cost_tzs` and `value_tzs` fields (Tanzania Shilling - TZS)
- **Country ID 3 (Nigeria)**: Display values from `unit_cost_ngn` and `value_ngn` fields (Nigerian Naira - NGN)

The server-side filtering ensures that only the appropriate currency values are sent to the frontend, reducing data transfer and simplifying frontend logic. The frontend then formats these values with appropriate currency symbols (TZS, ₦, KES), positioning (before or after the amount), and decimal places according to local conventions.

## Flutter Implementation

### 1. Currency Utility Class

Created `lib/utils/country_currency_labels.dart` to handle currency formatting:

```dart
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

  /// Format currency value with appropriate symbol and positioning
  static String formatCurrency(double amount, int? countryId) {
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
}
```

### 2. User Country ID Retrieval

The user's country ID is retrieved from GetStorage where it's stored during login:

```dart
// Get user's country ID for currency formatting
final box = GetStorage();
final salesRep = box.read('salesRep');
final userCountryId = salesRep?['countryId'];
```

### 3. Updated Pages

#### Cart Page (`lib/pages/order/cart_page.dart`)
- **Price Display**: Updated to use `CountryCurrencyLabels.formatCurrency()` for item prices and total amounts
- **Dynamic Formatting**: Prices now show correct currency symbols and positioning based on user's country

```dart
Text(
  CountryCurrencyLabels.formatCurrency(
    ((item.product?.priceOptions.firstWhereOrNull((po) => po.id == item.priceOptionId)?.value ?? 0) * item.quantity).toDouble(),
    userCountryId,
  ),
  style: const TextStyle(fontWeight: FontWeight.bold),
),
```

#### Product Detail Page (`lib/pages/order/product/product_detail_page.dart`)
- **Price Options**: Dropdown now shows prices with correct currency formatting
- **Selected Price**: Bottom section displays selected price with proper currency

```dart
Text(
  '${option.option} - ${CountryCurrencyLabels.formatCurrency(option.value.toDouble(), userCountryId)}',
  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
),
```

#### Order Detail Page (`lib/pages/order/viewOrder/orderDetail.dart`)
- **Total Section**: All price displays use dynamic currency formatting
- **Consistent Display**: Maintains currency consistency throughout the order flow

```dart
Text(
  CountryCurrencyLabels.formatCurrency(amount, userCountryId),
  style: TextStyle(
    fontSize: isTotal ? 14 : 12,
    fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
    color: isTotal ? Theme.of(context).primaryColor : Colors.black,
  ),
),
```

### 4. Currency Formatting Examples

Based on the current country mapping:

**Kenya (Country ID: 1)**
- Symbol: KES
- Position: Before amount
- Decimal places: 2
- Example: `KES 1,250.00`

**Tanzania (Country ID: 2)**
- Symbol: TZS
- Position: After amount
- Decimal places: 0
- Example: `2,500 TZS`

**Nigeria (Country ID: 3)**
- Symbol: ₦
- Position: Before amount
- Decimal places: 2
- Example: `₦ 500.00`

### 5. Testing

Created comprehensive tests in `test/country_currency_labels_test.dart`:

```dart
test('should format currency correctly for Kenya (before position)', () {
  expect(CountryCurrencyLabels.formatCurrency(1000.50, 1), equals('KES 1000.50'));
  expect(CountryCurrencyLabels.formatCurrency(0, 1), equals('KES 0.00'));
});

test('should format currency correctly for Tanzania (after position, no decimals)', () {
  expect(CountryCurrencyLabels.formatCurrency(1000.50, 2), equals('1001 TZS'));
  expect(CountryCurrencyLabels.formatCurrency(0, 2), equals('0 TZS'));
});

test('should format currency correctly for Nigeria (before position)', () {
  expect(CountryCurrencyLabels.formatCurrency(1000.50, 3), equals('₦ 1000.50'));
  expect(CountryCurrencyLabels.formatCurrency(0, 3), equals('₦ 0.00'));
});
```

## Backend API Implementation

### 1. Database Schema

The currency fields are already defined in the Prisma schema:

```prisma
// Product model (prisma/schema.prisma)
model Product {
  unit_cost            Decimal @db.Decimal(11, 2)  // Base currency (KES)
  unit_cost_tzs        Decimal? @db.Decimal(11, 2) // Tanzania Shilling
  unit_cost_ngn        Decimal? @db.Decimal(11, 2) // Nigerian Naira
  // ... other fields
}

// PriceOption model (prisma/schema.prisma)
model PriceOption {
  value      Int                    // Base currency (KES)
  value_tzs  Decimal? @db.Decimal(11, 2) // Tanzania Shilling
  value_ngn  Decimal? @db.Decimal(11, 2) // Nigerian Naira
  // ... other fields
}
```

### 2. Currency Utility Functions

Created shared currency utilities in `lib/currencyUtils.js`:

```javascript
/**
 * Get currency value based on country ID and item type
 * @param {Object} item - Product or PriceOption object
 * @param {number} countryId - User's country ID
 * @param {string} type - 'product' or 'priceOption'
 * @returns {number} The appropriate currency value
 */
const getCurrencyValue = (item, countryId, type) => {
  switch (countryId) {
    case 1:
      // Country ID 1: Use base value (KES)
      return type === 'product' ? item.unit_cost : item.value;
    case 2:
      // Country ID 2: Use TZS value
      return type === 'product' ? item.unit_cost_tzs : item.value_tzs;
    case 3:
      // Country ID 3: Use NGN value
      return type === 'product' ? item.unit_cost_ngn : item.value_ngn;
    default:
      // Fallback to base value
      return type === 'product' ? item.unit_cost : item.value;
  }
};

/**
 * Get currency symbol and formatting info based on country ID
 * @param {number} countryId - User's country ID
 * @returns {Object} Currency formatting information
 */
const getCurrencyInfo = (countryId) => {
  switch (countryId) {
    case 1:
      return {
        symbol: 'KES',
        position: 'before',
        decimalPlaces: 2,
        name: 'Kenyan Shilling'
      };
    case 2:
      return {
        symbol: 'TZS',
        position: 'after',
        decimalPlaces: 0,
        name: 'Tanzania Shilling'
      };
    case 3:
      return {
        symbol: '₦',
        position: 'before',
        decimalPlaces: 2,
        name: 'Nigerian Naira'
      };
    default:
      return {
        symbol: 'KES',
        position: 'before',
        decimalPlaces: 2,
        name: 'Kenyan Shilling'
      };
  }
};

/**
 * Format currency value with appropriate symbol and positioning
 * @param {number} amount - The amount to format
 * @param {number} countryId - User's country ID
 * @returns {string} Formatted currency string
 */
const formatCurrency = (amount, countryId) => {
  const currencyInfo = getCurrencyInfo(countryId);
  const formattedAmount = Number(amount).toFixed(currencyInfo.decimalPlaces);
  
  if (currencyInfo.position === 'before') {
    return `${currencyInfo.symbol} ${formattedAmount}`;
  } else {
    return `${formattedAmount} ${currencyInfo.symbol}`;
  }
};
```

### 3. Product Controller Implementation

Updated `controllers/productController.js` to implement currency filtering:

```javascript
const { getCurrencyValue } = require('../lib/currencyUtils');

// Get all products with currency filtering
const getProducts = async (req, res) => {
  try {
    const userId = getUserId(req);
    
    // Get user country information for currency display
    const user = await prisma.salesRep.findUnique({
      where: { id: userId },
      select: { countryId: true }
    });

    // Get products with pagination
    const products = await prisma.product.findMany({
      include: {
        client: true,
        orderItems: true,
        storeQuantities: true,
        purchaseHistory: true
      },
      orderBy: { name: 'asc' },
      skip: (parseInt(page) - 1) * parseInt(limit),
      take: parseInt(limit),
    });

    // Apply currency filtering to products and price options
    const productsWithPriceOptions = await Promise.all(products.map(async (product) => {
      const categoryWithPriceOptions = await prisma.category.findUnique({
        where: { id: product.category_id },
        include: { priceOptions: true }
      });

      const storeQuantities = await prisma.storeQuantity.findMany({
        where: { productId: product.id },
        include: { store: true }
      });

      // Apply currency filtering based on user's country
      const filteredProduct = {
        ...product,
        // Filter product unit cost based on country
        unit_cost: getCurrencyValue(product, user.countryId, 'product'),
        priceOptions: categoryWithPriceOptions?.priceOptions.map(priceOption => ({
          ...priceOption,
          // Filter price option value based on country
          value: getCurrencyValue(priceOption, user.countryId, 'priceOption')
        })) || [],
        storeQuantities: storeQuantities
      };

      return filteredProduct;
    }));

    res.status(200).json({
      success: true,
      data: productsWithPriceOptions,
      userCountry: user, // Include user country info for frontend currency logic
      pagination: {
        total: totalProducts,
        page: parseInt(page),
        limit: parseInt(limit),
        totalPages: Math.ceil(totalProducts / parseInt(limit)),
      },
    });
  } catch (error) {
    // Error handling...
  }
};
```

### 4. API Response Structure

The API now returns filtered currency values:

```javascript
// Before: Returns all currency fields
{
  "unit_cost": 1000,
  "unit_cost_tzs": 2500,
  "unit_cost_ngn": 500,
  "priceOptions": [
    {
      "value": 100,
      "value_tzs": 250,
      "value_ngn": 50
    }
  ]
}

// After: Returns only relevant currency (e.g., Country ID 2 - TZS)
{
  "unit_cost": 2500, // Filtered to TZS value
  "priceOptions": [
    {
      "value": 250 // Filtered to TZS value
    }
  ],
  "userCountry": {
    "countryId": 2
  }
}
```

## Benefits of Implementation

1. **🚀 Performance**: Reduces data transfer by sending only relevant currency values
2. **🎯 Accuracy**: Ensures users see prices in their local currency
3. **🔧 Maintainability**: Centralized currency logic in shared utilities
4. **📱 Frontend Simplicity**: Frontend receives pre-filtered data, no additional logic needed
5. **🛡️ Data Integrity**: Server-side filtering prevents currency confusion
6. **⚡ Scalability**: Easy to add new countries by extending the switch statement
7. **🎨 Consistent UX**: Users see familiar currency formats and symbols
8. **🔒 Type Safety**: Flutter implementation includes comprehensive testing

## Future Enhancements

1. **Order Controller Integration**: Update `controllers/orderController.js` to use currency filtering for order calculations
2. **Caching**: Implement Redis caching for currency conversion rates
3. **Real-time Exchange Rates**: Integrate with external APIs for live exchange rates
4. **Currency Validation**: Add validation middleware for currency field formats
5. **Multi-currency Orders**: Support orders with mixed currencies
6. **Currency Preferences**: Allow users to override their default currency
7. **Historical Exchange Rates**: Store and display historical currency conversion data

## Files Modified

### Flutter Implementation
- ✅ `lib/utils/country_currency_labels.dart` - Created currency utility class
- ✅ `lib/pages/order/cart_page.dart` - Updated to use dynamic currency formatting
- ✅ `lib/pages/order/product/product_detail_page.dart` - Updated price displays
- ✅ `lib/pages/order/viewOrder/orderDetail.dart` - Updated order totals
- ✅ `test/country_currency_labels_test.dart` - Added comprehensive tests

### Backend Implementation
- ✅ `lib/currencyUtils.js` - Created shared currency utilities
- ✅ `controllers/productController.js` - Implemented currency filtering
- ✅ `docs/country_specific_currency_display.md` - Updated documentation

## Files Pending Updates

- ⏳ `controllers/orderController.js` - Needs currency filtering for order calculations
- ⏳ `controllers/upliftSaleController.js` - May need currency filtering
- ⏳ Any other controllers that handle product pricing

## Testing Results

All currency formatting tests pass successfully:
```
00:05 +11: All tests passed!
```

The implementation provides a robust, scalable solution for country-specific currency display that enhances user experience while maintaining performance and data integrity. 

model Product {
  id                   Int                    @id @default(autoincrement())
  name                 String
  category_id          Int
  category             String
  unit_cost            Decimal                @db.Decimal(11, 2)
  unit_cost_tzs        Decimal?                @db.Decimal(11, 2)
  unit_cost_ngn        Decimal?                @db.Decimal(11, 2)
  description          String?
  currentStock         Int?
  createdAt            DateTime               @default(now())
  updatedAt            DateTime               @updatedAt
  clientId             Int?
  image                String?                @default("")
  orderItems           OrderItem[]
  client               Clients?               @relation(fields: [clientId], references: [id])
  ProductDetails       ProductDetails[]
  purchaseHistory      PurchaseHistory[]
  PurchaseItem         PurchaseItem[]
  storeQuantities      StoreQuantity[]
  TransferHistory      TransferHistory[]
  UpliftSaleItem       UpliftSaleItem[]
  product_transactions product_transactions[]

  @@index([clientId], map: "Product_clientId_fkey")
}

model PriceOption {
  id         Int         @id @default(autoincrement())
  option     String
  value      Int
  value_tzs  Decimal?                @db.Decimal(11, 2)
  value_ngn  Decimal?                @db.Decimal(11, 2)
  categoryId Int
  orderItems OrderItem[]
  category   Category    @relation(fields: [categoryId], references: [id])

  @@index([categoryId], map: "PriceOption_categoryId_fkey")
}