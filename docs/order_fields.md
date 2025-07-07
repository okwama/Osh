# Order Fields Documentation

## Fields Sent from CartPage

### Create Order (New Order)
```dart
{
  'clientId': outletId,  // int - ID of the outlet/client
  'items': [            // List of order items
    {
      'productId': item.product!.id,      // int - Product ID
      'quantity': item.quantity,          // int - Quantity ordered
      'priceOptionId': item.priceOptionId, // int - Selected price option ID
      'storeId': selectedStore.value!.id  // int - Selected store ID
    }
  ],
  'imageFile': selectedImage.value,       // File? - Optional attached image
  'comment': comment                      // String? - Optional order comment/notes
}
```

### Update Order (Existing Order)
```dart
{
  'orderId': orderId,   // int - ID of existing order
  'orderItems': [       // List of order items
    {
      'productId': item.product!.id,      // int - Product ID
      'quantity': item.quantity,          // int - Quantity ordered
      'priceOptionId': item.priceOptionId, // int - Selected price option ID
      'storeId': selectedStore.value!.id  // int - Selected store ID
    }
  ],
  'comment': comment    // String? - Optional order comment/notes
}
```

## Validation Checks
1. Store must be selected
2. Cart must not be empty
3. Each item must have:
   - Valid product
   - Quantity > 0
   - Selected price option
   - Sufficient stock in selected store

## Response Handling
- Success: Returns `OrderModel`
- Outstanding Balance: Returns Map with `hasOutstandingBalance: true` and dialog details
- Error: Throws exception with error message 