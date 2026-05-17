// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_category_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TaskCategoryAdapter extends TypeAdapter<TaskCategory> {
  @override
  final int typeId = 8;

  @override
  TaskCategory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TaskCategory(
      id: fields[0] as String,
      name: fields[1] as String,
      colorValue: fields[2] as int,
      userId: fields[3] as String,
    );
  }

  @override
  void write(BinaryWriter writer, TaskCategory obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.colorValue)
      ..writeByte(3)
      ..write(obj.userId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskCategoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
