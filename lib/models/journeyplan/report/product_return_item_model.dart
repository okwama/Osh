class ProductReturnItem {
  final int? reportId;
  final String? productName;
  final int? quantity;
  final String? reason;
  final String? imageUrl;

  ProductReturnItem({
    this.reportId,
    this.productName,
    this.quantity,
    this.reason,
    this.imageUrl,
  });

  factory ProductReturnItem.fromJson(Map<String, dynamic> json) {
    // Helper function to safely parse integers
    int? parseInteger(dynamic value) {
      if (value is int) return value;
      if (value is String) {
        try {
          return int.parse(value);
        } catch (e) {
          print('Error parsing integer: $value');
          return null;
        }
      }
      return null;
    }

    return ProductReturnItem(
      reportId:
          json['reportId'] != null ? parseInteger(json['reportId']) : null,
      productName: json['productName']?.toString(),
      quantity:
          json['quantity'] != null ? parseInteger(json['quantity']) : null,
      reason: json['reason']?.toString(),
      imageUrl: json['imageUrl']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        if (reportId != null) 'reportId': reportId,
        'productName': productName,
        'quantity': quantity,
        'reason': reason,
        'imageUrl': imageUrl,
      };

  // Helper method to create the request body for API submission
  Map<String, dynamic> toRequestJson() => {
        'productName': productName,
        'quantity': quantity,
        'reason': reason,
      };

  @override
  String toString() {
    return 'ProductReturnItem{'
        'reportId: $reportId, '
        'productName: $productName, '
        'quantity: $quantity, '
        'reason: $reason, '
        'imageUrl: $imageUrl'
        '}';
  }
}
