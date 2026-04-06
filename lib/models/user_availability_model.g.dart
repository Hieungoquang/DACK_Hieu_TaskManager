// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_availability_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserAvailabilityAdapter extends TypeAdapter<UserAvailability> {
  @override
  final int typeId = 7;

  @override
  UserAvailability read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserAvailability(
      availability_id: fields[0] as String,
      user_id: fields[1] as String,
      date: fields[2] as DateTime,
      start_time: fields[3] as String,
      end_time: fields[4] as String,
      duration_minute: fields[5] as int,
      isRecurring: fields[6] as bool,
      day_of_week: fields[7] as int,
      created_at: fields[8] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, UserAvailability obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.availability_id)
      ..writeByte(1)
      ..write(obj.user_id)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.start_time)
      ..writeByte(4)
      ..write(obj.end_time)
      ..writeByte(5)
      ..write(obj.duration_minute)
      ..writeByte(6)
      ..write(obj.isRecurring)
      ..writeByte(7)
      ..write(obj.day_of_week)
      ..writeByte(8)
      ..write(obj.created_at);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserAvailabilityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
