import 'package:get/get.dart';
import 'package:woosh/models/client_model.dart';
import 'package:woosh/models/Products_Inventory/product_model.dart';
import 'package:woosh/models/outlet_model.dart';
import 'package:dio/dio.dart';
import 'package:woosh/services/core/uplift_sale_service.dart' hide Client;

class UpliftSaleItem {
  final int id;
  final int upliftSaleId;
  final int productId;
  final int quantity;
  final double unitPrice;
  final double total;
  final DateTime createdAt;
  final ProductModel? product;

  UpliftSaleItem({
    required this.id,
    required this.upliftSaleId,
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    required this.total,
    required this.createdAt,
    this.product,
  });

  factory UpliftSaleItem.fromJson(Map<String, dynamic> json) {
    return UpliftSaleItem(
      id: json['id'] as int? ?? 0,
      upliftSaleId: json['upliftSaleId'] as int? ?? 0,
      productId: json['productId'] as int? ?? 0,
      quantity: json['quantity'] as int? ?? 0,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0.0,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      product: json['product'] != null
          ? ProductModel.fromMap(json['product'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'total': total,
    };
  }
}

class UpliftSale {
  final int id;
  final int clientId;
  final int userId;
  final String status;
  final double totalAmount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<UpliftSaleItem> items;
  final Client? client;

  UpliftSale({
    required this.id,
    required this.clientId,
    required this.userId,
    required this.status,
    required this.totalAmount,
    required this.createdAt,
    required this.updatedAt,
    required this.items,
    this.client,
  });

  factory UpliftSale.fromJson(Map<String, dynamic> json) {
    return UpliftSale(
      id: json['id'] as int? ?? 0,
      clientId: json['clientId'] as int? ?? 0,
      userId: json['userId'] as int? ?? 0,
      status: json['status'] as String? ?? 'pending',
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
          DateTime.now(),
      items: (json['items'] as List<dynamic>?)
              ?.map((item) =>
                  UpliftSaleItem.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      client: json['client'] != null
          ? Client.fromJson(json['client'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'clientId': clientId,
      'userId': userId,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }
}
