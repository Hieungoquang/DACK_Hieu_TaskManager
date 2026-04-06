// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'time_logs_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TimelogsAdapter extends TypeAdapter<Time_logs> {
  @override
  final int typeId = 4;

  @override
  Time_logs read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Time_logs(
      log_id: fields[0] as String,
      task_id: fields[1] as String,
      start_time: fields[2] as DateTime,
      end_time: fields[3] as DateTime,
      duration_minutes: fields[4] as int,
      notes: fields[5] as String,
      created_at: fields[6] as DateTime,
      updated_at: fields[7] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Time_logs obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.log_id)
      ..writeByte(1)
      ..write(obj.task_id)
      ..writeByte(2)
      ..write(obj.start_time)
      ..writeByte(3)
      ..write(obj.end_time)
      ..writeByte(4)
      ..write(obj.duration_minutes)
      ..writeByte(5)
      ..write(obj.notes)
      ..writeByte(6)
      ..write(obj.created_at)
      ..writeByte(7)
      ..write(obj.updated_at);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimelogsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
