// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subtask_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SubtaskAdapter extends TypeAdapter<Subtask> {
  @override
  final int typeId = 2;

  @override
  Subtask read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Subtask(
      subtask_id: fields[0] as String,
      task_id: fields[1] as String,
      title: fields[2] as String,
      is_completed: fields[3] as bool,
      created_at: fields[4] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Subtask obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.subtask_id)
      ..writeByte(1)
      ..write(obj.task_id)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.is_completed)
      ..writeByte(4)
      ..write(obj.created_at);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubtaskAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
