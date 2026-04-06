// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_schedule_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TaskScheduleAdapter extends TypeAdapter<TaskSchedule> {
  @override
  final int typeId = 5;

  @override
  TaskSchedule read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TaskSchedule(
      schedule_id: fields[0] as String,
      task_id: fields[1] as String,
      availability_id: fields[2] as String,
      start_time: fields[3] as DateTime,
      end_time: fields[4] as DateTime,
      duration_minutes: fields[5] as int,
      status: fields[6] as String,
      score_heuristic: fields[7] as int,
      is_auto_split: fields[8] as bool,
      created_at: fields[9] as DateTime,
      updated_at: fields[10] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, TaskSchedule obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.schedule_id)
      ..writeByte(1)
      ..write(obj.task_id)
      ..writeByte(2)
      ..write(obj.availability_id)
      ..writeByte(3)
      ..write(obj.start_time)
      ..writeByte(4)
      ..write(obj.end_time)
      ..writeByte(5)
      ..write(obj.duration_minutes)
      ..writeByte(6)
      ..write(obj.status)
      ..writeByte(7)
      ..write(obj.score_heuristic)
      ..writeByte(8)
      ..write(obj.is_auto_split)
      ..writeByte(9)
      ..write(obj.created_at)
      ..writeByte(10)
      ..write(obj.updated_at);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskScheduleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
