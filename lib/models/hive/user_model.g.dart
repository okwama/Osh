// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserModelAdapter extends TypeAdapter<UserModel> {
  @override
  final int typeId = 4;

  @override
  UserModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserModel(
      id: fields[0] as int,
      name: fields[1] as String,
      email: fields[2] as String,
      phoneNumber: fields[3] as String?,
      role: fields[4] as String?,
      region: fields[5] as String?,
      regionId: fields[6] as int?,
      routeId: fields[7] as int?,
      route: fields[8] as String?,
      country: (fields[9] as Map?)?.cast<String, dynamic>(),
      countryId: fields[10] as int?,
      status: fields[11] as int?,
      photoUrl: fields[12] as String?,
      department: fields[13] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, UserModel obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.email)
      ..writeByte(3)
      ..write(obj.phoneNumber)
      ..writeByte(4)
      ..write(obj.role)
      ..writeByte(5)
      ..write(obj.region)
      ..writeByte(6)
      ..write(obj.regionId)
      ..writeByte(7)
      ..write(obj.routeId)
      ..writeByte(8)
      ..write(obj.route)
      ..writeByte(9)
      ..write(obj.country)
      ..writeByte(10)
      ..write(obj.countryId)
      ..writeByte(11)
      ..write(obj.status)
      ..writeByte(12)
      ..write(obj.photoUrl)
      ..writeByte(13)
      ..write(obj.department);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
