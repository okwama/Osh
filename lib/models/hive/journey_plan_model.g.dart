// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'journey_plan_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class JourneyPlanModelAdapter extends TypeAdapter<JourneyPlanModel> {
  @override
  final int typeId = 5;

  @override
  JourneyPlanModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return JourneyPlanModel(
      id: fields[0] as int,
      date: fields[1] as DateTime,
      time: fields[2] as String,
      userId: fields[3] as int?,
      clientId: fields[4] as int,
      status: fields[5] as int,
      checkInTime: fields[6] as DateTime?,
      latitude: fields[7] as double?,
      longitude: fields[8] as double?,
      imageUrl: fields[9] as String?,
      notes: fields[10] as String?,
      checkoutLatitude: fields[11] as double?,
      checkoutLongitude: fields[12] as double?,
      checkoutTime: fields[13] as DateTime?,
      showUpdateLocation: fields[14] as bool,
      routeId: fields[15] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, JourneyPlanModel obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.time)
      ..writeByte(3)
      ..write(obj.userId)
      ..writeByte(4)
      ..write(obj.clientId)
      ..writeByte(5)
      ..write(obj.status)
      ..writeByte(6)
      ..write(obj.checkInTime)
      ..writeByte(7)
      ..write(obj.latitude)
      ..writeByte(8)
      ..write(obj.longitude)
      ..writeByte(9)
      ..write(obj.imageUrl)
      ..writeByte(10)
      ..write(obj.notes)
      ..writeByte(11)
      ..write(obj.checkoutLatitude)
      ..writeByte(12)
      ..write(obj.checkoutLongitude)
      ..writeByte(13)
      ..write(obj.checkoutTime)
      ..writeByte(14)
      ..write(obj.showUpdateLocation)
      ..writeByte(15)
      ..write(obj.routeId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JourneyPlanModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
