// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_report_hive_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProductReportHiveModelAdapter
    extends TypeAdapter<ProductReportHiveModel> {
  @override
  final int typeId = 10;

  @override
  ProductReportHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProductReportHiveModel(
      journeyPlanId: fields[0] as int,
      clientId: fields[1] as int,
      clientName: fields[2] as String,
      clientAddress: fields[3] as String,
      products: (fields[4] as List).cast<ProductQuantityHiveModel>(),
      comment: fields[5] as String,
      createdAt: fields[6] as DateTime,
      isSynced: fields[7] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, ProductReportHiveModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.journeyPlanId)
      ..writeByte(1)
      ..write(obj.clientId)
      ..writeByte(2)
      ..write(obj.clientName)
      ..writeByte(3)
      ..write(obj.clientAddress)
      ..writeByte(4)
      ..write(obj.products)
      ..writeByte(5)
      ..write(obj.comment)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.isSynced);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductReportHiveModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ProductQuantityHiveModelAdapter
    extends TypeAdapter<ProductQuantityHiveModel> {
  @override
  final int typeId = 11;

  @override
  ProductQuantityHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProductQuantityHiveModel(
      productId: fields[0] as int,
      productName: fields[1] as String,
      quantity: fields[2] as int,
    );
  }

  @override
  void write(BinaryWriter writer, ProductQuantityHiveModel obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.productId)
      ..writeByte(1)
      ..write(obj.productName)
      ..writeByte(2)
      ..write(obj.quantity);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductQuantityHiveModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
