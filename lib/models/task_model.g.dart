// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TaskAdapter extends TypeAdapter<Task> {
  @override
  final int typeId = 0;

  @override
  Task read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Task(
      task_id: fields[0] as String,
      user_id: fields[1] as String,
      title: fields[2] as String,
      description: fields[3] as String,
      due_day: fields[4] as DateTime,
      priority: fields[5] as int,
      progress: fields[6] as int,
      duration: fields[7] as int,
      deadline: fields[8] as DateTime,
      status: fields[9] as String,
      createdAt: fields[10] as DateTime,
      updatedAt: fields[11] as DateTime,
      isSynced: fields[12] as bool,
      isDeleted: fields[13] as bool,
      category: fields[14] as String,
      orderIndex: fields[15] as int,
      project_id: fields[16] as String?,
      assigneeId: fields[17] as String?,
      attachments: (fields[18] as List).cast<String>(),
      reminder: fields[19] as int,
    );
  }

  @override
  void write(BinaryWriter writer, Task obj) {
    writer
      ..writeByte(20)
      ..writeByte(0)
      ..write(obj.task_id)
      ..writeByte(1)
      ..write(obj.user_id)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.due_day)
      ..writeByte(5)
      ..write(obj.priority)
      ..writeByte(6)
      ..write(obj.progress)
      ..writeByte(7)
      ..write(obj.duration)
      ..writeByte(8)
      ..write(obj.deadline)
      ..writeByte(9)
      ..write(obj.status)
      ..writeByte(10)
      ..write(obj.createdAt)
      ..writeByte(11)
      ..write(obj.updatedAt)
      ..writeByte(12)
      ..write(obj.isSynced)
      ..writeByte(13)
      ..write(obj.isDeleted)
      ..writeByte(14)
      ..write(obj.category)
      ..writeByte(15)
      ..write(obj.orderIndex)
      ..writeByte(16)
      ..write(obj.project_id)
      ..writeByte(17)
      ..write(obj.assigneeId)
      ..writeByte(18)
      ..write(obj.attachments)
      ..writeByte(19)
      ..write(obj.reminder);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
