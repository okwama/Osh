import 'package:hive/hive.dart';

part 'product_report_hive_model.g.dart';

@HiveType(
    typeId: 10) // Make sure this ID is unique and not used by other Hive models
class ProductReportHiveModel extends HiveObject {
  @HiveField(0)
  final int journeyPlanId;

  @HiveField(1)
  final int clientId;

  @HiveField(2)
  final String clientName;

  @HiveField(3)
  final String clientAddress;

  @HiveField(4)
  final List<ProductQuantityHiveModel> products;

  @HiveField(5)
  final String comment;

  @HiveField(6)
  final DateTime createdAt;

  @HiveField(7)
  final bool isSynced;

  ProductReportHiveModel({
    required this.journeyPlanId,
    required this.clientId,
    required this.clientName,
    required this.clientAddress,
    required this.products,
    this.comment = '',
    required this.createdAt,
    this.isSynced = false,
  });
}

@HiveType(typeId: 11) // Make sure this ID is unique
class ProductQuantityHiveModel extends HiveObject {
  @HiveField(0)
  final int productId;

  @HiveField(1)
  final String productName;

  @HiveField(2)
  final int quantity;

  ProductQuantityHiveModel({
    required this.productId,
    required this.productName,
    required this.quantity,
  });
}
