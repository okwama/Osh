import 'package:woosh/models/order/order_item_model.dart';

class MyOrderModel {
  final int id;
  final double totalAmount;
  final double totalCost;
  final double amountPaid;
  final double balance;
  final String comment;
  final String customerType;
  final String customerId;
  final String customerName;
  final DateTime orderDate;
  final int? riderId;
  final String? riderName;
  final int status;
  final String? approvedTime;
  final String? dispatchTime;
  final String? deliveryLocation;
  final String? completeLatitude;
  final String? completeLongitude;
  final String? completeAddress;
  final String? pickupTime;
  final String? deliveryTime;
  final String? cancelReason;
  final String? recipient;
  final int userId;
  final int clientId;
  final int countryId;
  final int regionId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String approvedBy;
  final String approvedByName;
  final int? storeId;
  final int retailManager;
  final int keyChannelManager;
  final int distributionManager;
  final String? imageUrl;
  final List<OrderItemModel>? orderItems;

  MyOrderModel({
    required this.id,
    required this.totalAmount,
    required this.totalCost,
    required this.amountPaid,
    required this.balance,
    required this.comment,
    required this.customerType,
    required this.customerId,
    required this.customerName,
    required this.orderDate,
    this.riderId,
    this.riderName,
    required this.status,
    this.approvedTime,
    this.dispatchTime,
    this.deliveryLocation,
    this.completeLatitude,
    this.completeLongitude,
    this.completeAddress,
    this.pickupTime,
    this.deliveryTime,
    this.cancelReason,
    this.recipient,
    required this.userId,
    required this.clientId,
    required this.countryId,
    required this.regionId,
    required this.createdAt,
    required this.updatedAt,
    required this.approvedBy,
    required this.approvedByName,
    this.storeId,
    required this.retailManager,
    required this.keyChannelManager,
    required this.distributionManager,
    this.imageUrl,
    this.orderItems,
  });

  factory MyOrderModel.fromMap(Map<String, dynamic> map) {
    return MyOrderModel(
      id: map['id'] ?? 0,
      totalAmount: (map['totalAmount'] ?? 0).toDouble(),
      totalCost: (map['totalCost'] ?? 0).toDouble(),
      amountPaid: (map['amountPaid'] ?? 0).toDouble(),
      balance: (map['balance'] ?? 0).toDouble(),
      comment: map['comment'] ?? '',
      customerType: map['customerType'] ?? '',
      customerId: map['customerId'] ?? '',
      customerName: map['customerName'] ?? '',
      orderDate: _parseDateTime(map['orderDate']),
      riderId: map['riderId'],
      riderName: map['riderName'],
      status: map['status'] ?? 0,
      approvedTime: map['approvedTime'],
      dispatchTime: map['dispatchTime'],
      deliveryLocation: map['deliveryLocation'],
      completeLatitude: map['complete_latitude'],
      completeLongitude: map['complete_longitude'],
      completeAddress: map['complete_address'],
      pickupTime: map['pickupTime'],
      deliveryTime: map['deliveryTime'],
      cancelReason: map['cancel_reason'],
      recipient: map['recepient'], // Note: DB has typo 'recepient'
      userId: map['userId'] ?? 0,
      clientId: map['clientId'] ?? 0,
      countryId: map['countryId'] ?? 0,
      regionId: map['regionId'] ?? 0,
      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: _parseDateTime(map['updatedAt']),
      approvedBy: map['approved_by'] ?? '',
      approvedByName: map['approved_by_name'] ?? '',
      storeId: map['storeId'],
      retailManager: map['retail_manager'] ?? 0,
      keyChannelManager: map['key_channel_manager'] ?? 0,
      distributionManager: map['distribution_manager'] ?? 0,
      imageUrl: map['imageUrl'],
      orderItems: (map['orderItems'] as List<dynamic>?)
          ?.map((item) => OrderItemModel.fromMap(item))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'totalAmount': totalAmount,
      'totalCost': totalCost,
      'amountPaid': amountPaid,
      'balance': balance,
      'comment': comment,
      'customerType': customerType,
      'customerId': customerId,
      'customerName': customerName,
      'orderDate': orderDate.toIso8601String(),
      'riderId': riderId,
      'riderName': riderName,
      'status': status,
      'approvedTime': approvedTime,
      'dispatchTime': dispatchTime,
      'deliveryLocation': deliveryLocation,
      'complete_latitude': completeLatitude,
      'complete_longitude': completeLongitude,
      'complete_address': completeAddress,
      'pickupTime': pickupTime,
      'deliveryTime': deliveryTime,
      'cancel_reason': cancelReason,
      'recepient': recipient, // Note: DB has typo 'recepient'
      'userId': userId,
      'clientId': clientId,
      'countryId': countryId,
      'regionId': regionId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'approved_by': approvedBy,
      'approved_by_name': approvedByName,
      'storeId': storeId,
      'retail_manager': retailManager,
      'key_channel_manager': keyChannelManager,
      'distribution_manager': distributionManager,
      'imageUrl': imageUrl,
      'orderItems': orderItems?.map((item) => item.toMap()).toList(),
    };
  }

  /// Get status display text
  String get statusText {
    switch (status) {
      case 0:
        return 'Pending';
      case 1:
        return 'Approved';
      case 2:
        return 'Dispatched';
      case 3:
        return 'Delivered';
      case 4:
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }

  /// Check if order is pending
  bool get isPending => status == 0;

  /// Check if order is approved
  bool get isApproved => status == 1;

  /// Check if order is dispatched
  bool get isDispatched => status == 2;

  /// Check if order is delivered
  bool get isDelivered => status == 3;

  /// Check if order is cancelled
  bool get isCancelled => status == 4;

  /// Create a copy with updated fields
  MyOrderModel copyWith({
    int? id,
    double? totalAmount,
    double? totalCost,
    double? amountPaid,
    double? balance,
    String? comment,
    String? customerType,
    String? customerId,
    String? customerName,
    DateTime? orderDate,
    int? riderId,
    String? riderName,
    int? status,
    String? approvedTime,
    String? dispatchTime,
    String? deliveryLocation,
    String? completeLatitude,
    String? completeLongitude,
    String? completeAddress,
    String? pickupTime,
    String? deliveryTime,
    String? cancelReason,
    String? recipient,
    int? userId,
    int? clientId,
    int? countryId,
    int? regionId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? approvedBy,
    String? approvedByName,
    int? storeId,
    int? retailManager,
    int? keyChannelManager,
    int? distributionManager,
    String? imageUrl,
    List<OrderItemModel>? orderItems,
  }) {
    return MyOrderModel(
      id: id ?? this.id,
      totalAmount: totalAmount ?? this.totalAmount,
      totalCost: totalCost ?? this.totalCost,
      amountPaid: amountPaid ?? this.amountPaid,
      balance: balance ?? this.balance,
      comment: comment ?? this.comment,
      customerType: customerType ?? this.customerType,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      orderDate: orderDate ?? this.orderDate,
      riderId: riderId ?? this.riderId,
      riderName: riderName ?? this.riderName,
      status: status ?? this.status,
      approvedTime: approvedTime ?? this.approvedTime,
      dispatchTime: dispatchTime ?? this.dispatchTime,
      deliveryLocation: deliveryLocation ?? this.deliveryLocation,
      completeLatitude: completeLatitude ?? this.completeLatitude,
      completeLongitude: completeLongitude ?? this.completeLongitude,
      completeAddress: completeAddress ?? this.completeAddress,
      pickupTime: pickupTime ?? this.pickupTime,
      deliveryTime: deliveryTime ?? this.deliveryTime,
      cancelReason: cancelReason ?? this.cancelReason,
      recipient: recipient ?? this.recipient,
      userId: userId ?? this.userId,
      clientId: clientId ?? this.clientId,
      countryId: countryId ?? this.countryId,
      regionId: regionId ?? this.regionId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedByName: approvedByName ?? this.approvedByName,
      storeId: storeId ?? this.storeId,
      retailManager: retailManager ?? this.retailManager,
      keyChannelManager: keyChannelManager ?? this.keyChannelManager,
      distributionManager: distributionManager ?? this.distributionManager,
      imageUrl: imageUrl ?? this.imageUrl,
      orderItems: orderItems ?? this.orderItems,
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) {
      try {
        // Handle both ISO string and MySQL datetime formats
        if (value.contains('T')) {
          return DateTime.parse(value);
        } else {
          // MySQL datetime format: YYYY-MM-DD HH:MM:SS
          return DateTime.parse(value.replaceAll(' ', 'T'));
        }
      } catch (e) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  @override
  String toString() {
    return 'MyOrderModel(id: $id, customerName: $customerName, totalAmount: $totalAmount, status: $statusText)';
  }
}