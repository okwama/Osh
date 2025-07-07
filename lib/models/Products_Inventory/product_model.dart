import 'price_option_model.dart';
import 'store_quantity_model.dart';

class ProductModel {
  final int id;
  final String name;
  final int categoryId;
  final String category;
  final double unitCost;
  final String? description;
  final int? currentStock;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? clientId;
  final String? image;
  final double? unitCostNgn;
  final double? unitCostTzs;
  final int? packSize; // Added missing property
  final List<PriceOptionModel> priceOptions; // Added missing property
  final List<StoreQuantityModel> storeQuantities; // Added missing property

  ProductModel({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.category,
    required this.unitCost,
    this.description,
    this.currentStock,
    required this.createdAt,
    required this.updatedAt,
    this.clientId,
    this.image,
    this.unitCostNgn,
    this.unitCostTzs,
    this.packSize, // Added missing property
    this.priceOptions = const [], // Added missing property with default
    this.storeQuantities = const [], // Added missing property with default
  });

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id'] ?? 0,
      name: map['name'] ?? '',
      categoryId: map['category_id'] ?? 0,
      category: map['category'] ?? '',
      unitCost: (map['unit_cost'] ?? 0).toDouble(),
      description: map['description'],
      currentStock: map['currentStock'],
      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: _parseDateTime(map['updatedAt']),
      clientId: map['clientId'],
      image: map['image'],
      unitCostNgn: map['unit_cost_ngn'] != null
          ? (map['unit_cost_ngn']).toDouble()
          : null,
      unitCostTzs: map['unit_cost_tzs'] != null
          ? (map['unit_cost_tzs']).toDouble()
          : null,
      packSize: map['packSize'], // Added missing property
      priceOptions: map['priceOptions'] != null
          ? (map['priceOptions'] as List)
              .map((po) => PriceOptionModel.fromMap(po))
              .toList()
          : [], // Added missing property
      storeQuantities: map['storeQuantities'] != null
          ? (map['storeQuantities'] as List)
              .map((sq) => StoreQuantityModel.fromMap(sq))
              .toList()
          : [], // Added missing property
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category_id': categoryId,
      'category': category,
      'unit_cost': unitCost,
      'description': description,
      'currentStock': currentStock,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'clientId': clientId,
      'image': image,
      'unit_cost_ngn': unitCostNgn,
      'unit_cost_tzs': unitCostTzs,
      'packSize': packSize, // Added missing property
      'priceOptions': priceOptions
          .map((po) => po.toMap())
          .toList(), // Added missing property
      'storeQuantities': storeQuantities
          .map((sq) => sq.toMap())
          .toList(), // Added missing property
    };
  }

  /// Get quantity for a specific store
  int getQuantityForStore(int storeId) {
    final storeQuantity = storeQuantities.firstWhere(
      (sq) => sq.storeId == storeId,
      orElse: () => StoreQuantityModel(
        id: 0,
        productId: id,
        storeId: storeId,
        quantity: 0,
      ),
    );
    return storeQuantity.quantity;
  }

  /// Get imageUrl (alias for image property)
  String? get imageUrl => image;

  /// Get unit cost based on currency
  double getUnitCost(String currency) {
    switch (currency.toUpperCase()) {
      case 'NGN':
        return unitCostNgn ?? unitCost;
      case 'TZS':
        return unitCostTzs ?? unitCost;
      default:
        return unitCost;
    }
  }

  /// Check if product is in stock
  bool get isInStock => (currentStock ?? 0) > 0;

  /// Check if product is low stock (less than 10 units)
  bool get isLowStock => (currentStock ?? 0) < 10 && (currentStock ?? 0) > 0;

  /// Check if product is out of stock
  bool get isOutOfStock => (currentStock ?? 0) <= 0;

  /// Get stock status text
  String get stockStatusText {
    if (isOutOfStock) return 'Out of Stock';
    if (isLowStock) return 'Low Stock';
    return 'In Stock';
  }

  /// Create a copy with updated fields
  ProductModel copyWith({
    int? id,
    String? name,
    int? categoryId,
    String? category,
    double? unitCost,
    String? description,
    int? currentStock,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? clientId,
    String? image,
    double? unitCostNgn,
    double? unitCostTzs,
    int? packSize, // Added missing property
    List<PriceOptionModel>? priceOptions, // Added missing property
    List<StoreQuantityModel>? storeQuantities, // Added missing property
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      category: category ?? this.category,
      unitCost: unitCost ?? this.unitCost,
      description: description ?? this.description,
      currentStock: currentStock ?? this.currentStock,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      clientId: clientId ?? this.clientId,
      image: image ?? this.image,
      unitCostNgn: unitCostNgn ?? this.unitCostNgn,
      unitCostTzs: unitCostTzs ?? this.unitCostTzs,
      packSize: packSize ?? this.packSize, // Added missing property
      priceOptions: priceOptions ?? this.priceOptions, // Added missing property
      storeQuantities:
          storeQuantities ?? this.storeQuantities, // Added missing property
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
    return 'ProductModel(id: $id, name: $name, category: $category, unitCost: $unitCost, stock: $currentStock)';
  }
}