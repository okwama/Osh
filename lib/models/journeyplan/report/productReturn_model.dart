import 'package:woosh/models/journeyplan/report/product_return_item_model.dart';

class ProductReturn {
  final int reportId;
  final String? productName;
  final String? reason;
  final String? imageUrl;
  final int? quantity;
  final List<ProductReturnItem>? items;

  ProductReturn({
    required this.reportId,
    this.productName,
    this.reason,
    this.imageUrl,
    this.quantity,
    this.items,
  });

  Map<String, dynamic> toJson() {
    return {
      'reportId': reportId,
      'productName': productName,
      'reason': reason,
      'imageUrl': imageUrl,
      'quantity': quantity,
      'items': items?.map((item) => item.toJson()).toList(),
    };
  }

  factory ProductReturn.fromJson(Map<String, dynamic> json) {
    // Helper function to safely parse integers
    int parseInteger(dynamic value) {
      if (value is int) return value;
      if (value is String) {
        try {
          return int.parse(value);
        } catch (e) {
          return 0;
        }
      }
      return 0;
    }

    // Parse items if they exist
    List<ProductReturnItem>? parseItems(dynamic itemsJson) {
      if (itemsJson == null) return null;
      if (itemsJson is List) {
        return itemsJson
            .map((item) => ProductReturnItem.fromJson(item))
            .toList();
      }
      return null;
    }

    return ProductReturn(
      reportId: parseInteger(json['reportId']),
      productName: json['productName']?.toString(),
      reason: json['reason']?.toString(),
      imageUrl: json['imageUrl']?.toString(),
      quantity:
          json['quantity'] != null ? parseInteger(json['quantity']) : null,
      items: parseItems(json['items']),
    );
  }

  // Static method to parse the server response array
  static List<ProductReturn> fromResponse(dynamic response) {
    if (response is List) {
      return response.map((item) => ProductReturn.fromJson(item)).toList();
    } else if (response is Map<String, dynamic>) {
      return [ProductReturn.fromJson(response)];
    } else {
      throw FormatException('Invalid response format: $response');
    }
  }

  // Helper method to create the request body for API submission
  Map<String, dynamic> toRequestJson({
    required int userId,
    required int clientId,
    int? journeyPlanId,
  }) {
    return {
      'type': 'PRODUCT_RETURN',
      'journeyPlanId': journeyPlanId,
      'userId': userId,
      'clientId': clientId,
      'details': {
        'items': items?.map((item) => item.toRequestJson()).toList() ?? [],
      },
    };
  }

  @override
  String toString() {
    return 'ProductReturn{'
        'reportId: $reportId, '
        'productName: $productName, '
        'reason: $reason, '
        'imageUrl: $imageUrl, '
        'quantity: $quantity, '
        'items: ${items?.length ?? 0}'
        '}';
  }
}