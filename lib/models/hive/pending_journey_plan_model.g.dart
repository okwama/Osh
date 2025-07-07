// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_journey_plan_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PendingJourneyPlanModelAdapter
    extends TypeAdapter<PendingJourneyPlanModel> {
  @override
  final int typeId = 8;

  @override
  PendingJourneyPlanModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PendingJourneyPlanModel(
      clientId: fields[0] as int,
      date: fields[1] as DateTime,
      notes: fields[2] as String?,
      routeId: fields[3] as int?,
      createdAt: fields[4] as DateTime,
      status: fields[5] as String,
      errorMessage: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, PendingJourneyPlanModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.clientId)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.notes)
      ..writeByte(3)
      ..write(obj.routeId)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.status)
      ..writeByte(6)
      ..write(obj.errorMessage);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PendingJourneyPlanModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
