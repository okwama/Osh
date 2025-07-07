class PriceOptionModel {
  final int id;
  final String option;
  final int value;
  final int categoryId;
  final double? valueNgn;
  final double? valueTzs;

  PriceOptionModel({
    required this.id,
    required this.option,
    required this.value,
    required this.categoryId,
    this.valueNgn,
    this.valueTzs,
  });

  factory PriceOptionModel.fromMap(Map<String, dynamic> map) {
    return PriceOptionModel(
      id: map['id'] ?? 0,
      option: map['option'] ?? '',
      value: map['value'] ?? 0,
      categoryId: map['categoryId'] ?? 0,
      valueNgn: map['value_ngn'] != null ? (map['value_ngn']).toDouble() : null,
      valueTzs: map['value_tzs'] != null ? (map['value_tzs']).toDouble() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'option': option,
      'value': value,
      'categoryId': categoryId,
      'value_ngn': valueNgn,
      'value_tzs': valueTzs,
    };
  }

  /// Get value based on currency
  double getValue(String currency) {
    switch (currency.toUpperCase()) {
      case 'NGN':
        return valueNgn ?? value.toDouble();
      case 'TZS':
        return valueTzs ?? value.toDouble();
      default:
        return value.toDouble();
    }
  }

  /// Create a copy with updated fields
  PriceOptionModel copyWith({
    int? id,
    String? option,
    int? value,
    int? categoryId,
    double? valueNgn,
    double? valueTzs,
  }) {
    return PriceOptionModel(
      id: id ?? this.id,
      option: option ?? this.option,
      value: value ?? this.value,
      categoryId: categoryId ?? this.categoryId,
      valueNgn: valueNgn ?? this.valueNgn,
      valueTzs: valueTzs ?? this.valueTzs,
    );
  }

  @override
  String toString() {
    return 'PriceOptionModel(id: $id, option: $option, value: $value, categoryId: $categoryId)';
  }
}
