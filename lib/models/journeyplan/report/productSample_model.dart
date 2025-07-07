class ProductSample {
  final int reportId;
  final String? productName;
  final String? reason;
  final int? quantity;

  ProductSample({
    required this.reportId,
    this.productName,
    this.reason,
    this.quantity,
  });

  Map<String, dynamic> toJson() {
    return {
      'reportId': reportId,
      'productName': productName,
      'reason': reason,
      'quantity': quantity,
    };
  }

  factory ProductSample.fromJson(Map<String, dynamic> json) {
    return ProductSample(
      reportId: json['reportId'] ?? 0,
      productName: json['productName'],
      reason: json['reason'],
      quantity: json['quantity'],
    );
  }
}
