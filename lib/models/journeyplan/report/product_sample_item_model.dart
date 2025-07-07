class ProductSampleItem {
  final String? productName;
  final int? quantity;
  final String? reason;

  ProductSampleItem({
    this.productName,
    this.quantity,
    this.reason,
  });

  factory ProductSampleItem.fromJson(Map<String, dynamic> json) {
    return ProductSampleItem(
      productName: json['productName'],
      quantity: json['quantity'],
      reason: json['reason'],
    );
  }

  Map<String, dynamic> toJson() => {
        'productName': productName,
        'quantity': quantity,
        'reason': reason,
      };
}
