class ProductReport {
  final int reportId;
  final String? productName;
  final int? productId;
  final int? quantity;
  final String? comment;
  final DateTime createdAt;

  ProductReport({
    required this.reportId,
    this.productName,
    this.productId,
    this.quantity,
    this.comment,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'reportId': reportId,
      'productName': productName,
      'productId': productId,
      'quantity': quantity,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ProductReport.fromJson(dynamic jsonData) {
    print('ProductReport.fromJson input: $jsonData (${jsonData.runtimeType})');

    // Convert dynamic Map to Map<String, dynamic>
    final map = Map<String, dynamic>.from(jsonData);

    return ProductReport(
      reportId: map['reportId'],
      productName: map['productName'],
      quantity: map['quantity'] != null
          ? int.parse(map['quantity'].toString())
          : null,
      comment: map['comment'],
      createdAt:
          map['createdAt'] != null ? DateTime.parse(map['createdAt']) : null,
    );
  }

  int get id => reportId;
}
