// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_session_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PendingSessionModelAdapter extends TypeAdapter<PendingSessionModel> {
  @override
  final int typeId = 13;

  @override
  PendingSessionModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PendingSessionModel(
      userId: fields[0] as String,
      operation: fields[1] as String,
      timestamp: fields[2] as DateTime,
      status: fields[3] as String,
      errorMessage: fields[4] as String?,
      retryCount: fields[5] as int,
    );
  }

  @override
  void write(BinaryWriter writer, PendingSessionModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.userId)
      ..writeByte(1)
      ..write(obj.operation)
      ..writeByte(2)
      ..write(obj.timestamp)
      ..writeByte(3)
      ..write(obj.status)
      ..writeByte(4)
      ..write(obj.errorMessage)
      ..writeByte(5)
      ..write(obj.retryCount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PendingSessionModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
