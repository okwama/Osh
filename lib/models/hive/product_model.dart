import 'package:hive/hive.dart';
import 'package:woosh/models/Products_Inventory/product_model.dart';
import 'package:woosh/models/Products_Inventory/price_option_model.dart';
import 'package:woosh/models/Products_Inventory/store_quantity_model.dart';

// This part reference will be generated after running build_runner
part 'product_model.g.dart';

@HiveType(typeId: 2)
class ProductHiveModel extends HiveObject {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final int category_id;

  @HiveField(3)
  final String category;

  @HiveField(4)
  final String? description;

  @HiveField(5)
  final String createdAt;

  @HiveField(6)
  final String updatedAt;

  @HiveField(7)
  final String? imageUrl;

  @HiveField(8)
  final int? clientId;

  @HiveField(9)
  final int? packSize;

  // Price option fields
  @HiveField(10)
  final int? defaultPriceOptionId;

  @HiveField(11)
  final String? defaultPriceOption;

  @HiveField(12)
  final double? defaultPriceValue;

  @HiveField(13)
  final int? defaultPriceCategoryId;

  // Store quantities for stock information
  @HiveField(14)
  final List<Map<String, dynamic>> storeQuantitiesData;

  ProductHiveModel({
    required this.id,
    required this.name,
    required this.category_id,
    required this.category,
    this.description,
    required this.createdAt,
    required this.updatedAt,
    this.imageUrl,
    this.clientId,
    this.packSize,
    this.defaultPriceOptionId,
    this.defaultPriceOption,
    this.defaultPriceValue,
    this.defaultPriceCategoryId,
    this.storeQuantitiesData = const [],
  });

  // Convert from API Product model to Hive model
  static ProductHiveModel fromProduct(ProductModel product) {
    int? defaultPriceOptionId;
    String? defaultPriceOption;
    double? defaultPriceValue;
    int? defaultPriceCategoryId;

    if (product.priceOptions.isNotEmpty) {
      final firstOption = product.priceOptions.first;
      defaultPriceOptionId = firstOption.id;
      defaultPriceOption = firstOption.option;
      defaultPriceValue = firstOption.value.toDouble();
      defaultPriceCategoryId = firstOption.categoryId;
    }

    // Convert store quantities to serializable format
    final storeQuantitiesData =
        product.storeQuantities.map((sq) => sq.toMap()).toList();

    return ProductHiveModel(
      id: product.id,
      name: product.name,
      category_id: product.categoryId,
      category: product.category,
      description: product.description,
      createdAt: product.createdAt.toIso8601String(),
      updatedAt: product.updatedAt.toIso8601String(),
      imageUrl: product.image,
      clientId: product.clientId,
      packSize: product.packSize,
      defaultPriceOptionId: defaultPriceOptionId,
      defaultPriceOption: defaultPriceOption,
      defaultPriceValue: defaultPriceValue,
      defaultPriceCategoryId: defaultPriceCategoryId,
      storeQuantitiesData: storeQuantitiesData,
    );
  }

  // Convert from Hive model to API Product model
  ProductModel toProduct() {
    List<PriceOptionModel> priceOptions = [];

    // Create a price option if we have default price values
    if (defaultPriceOptionId != null &&
        defaultPriceOption != null &&
        defaultPriceValue != null) {
      priceOptions.add(PriceOptionModel(
        id: defaultPriceOptionId!,
        option: defaultPriceOption!,
        value: defaultPriceValue!.toInt(),
        categoryId: defaultPriceCategoryId ?? category_id,
      ));
    }

    return ProductModel(
      id: id,
      name: name,
      categoryId: category_id,
      category: category,
      unitCost: defaultPriceValue ?? 0.0,
      description: description,
      createdAt: DateTime.parse(createdAt),
      updatedAt: DateTime.parse(updatedAt),
      image: imageUrl,
      clientId: clientId,
      packSize: packSize,
      priceOptions: priceOptions,
      storeQuantities: storeQuantitiesData
          .map((data) => StoreQuantityModel.fromMap(data))
          .toList(),
    );
  }
}
