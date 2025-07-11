// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProductHiveModelAdapter extends TypeAdapter<ProductHiveModel> {
  @override
  final int typeId = 2;

  @override
  ProductHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProductHiveModel(
      id: fields[0] as int,
      name: fields[1] as String,
      categoryId: fields[2] as int,
      category: fields[3] as String,
      description: fields[4] as String?,
      createdAt: fields[5] as String,
      updatedAt: fields[6] as String,
      imageUrl: fields[7] as String?,
      clientId: fields[8] as int?,
      packSize: fields[9] as int?,
      defaultPriceOptionId: fields[10] as int?,
      defaultPriceOption: fields[11] as String?,
      defaultPriceValue: fields[12] as double?,
      defaultPriceCategoryId: fields[13] as int?,
      storeQuantitiesData: (fields[14] as List)
          .map((dynamic e) => (e as Map).cast<String, dynamic>())
          .toList(),
    );
  }

  @override
  void write(BinaryWriter writer, ProductHiveModel obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.categoryId)
      ..writeByte(3)
      ..write(obj.category)
      ..writeByte(4)
      ..write(obj.description)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.updatedAt)
      ..writeByte(7)
      ..write(obj.imageUrl)
      ..writeByte(8)
      ..write(obj.clientId)
      ..writeByte(9)
      ..write(obj.packSize)
      ..writeByte(10)
      ..write(obj.defaultPriceOptionId)
      ..writeByte(11)
      ..write(obj.defaultPriceOption)
      ..writeByte(12)
      ..write(obj.defaultPriceValue)
      ..writeByte(13)
      ..write(obj.defaultPriceCategoryId)
      ..writeByte(14)
      ..write(obj.storeQuantitiesData);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductHiveModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
