// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserAdapter extends TypeAdapter<User> {
  @override
  final int typeId = 1;

  @override
  User read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return User(
      user_id: fields[0] as String,
      username: fields[1] as String,
      email: fields[2] as String,
      phone_number: fields[3] as String,
      password_hash: fields[4] as String,
      google_id: fields[5] as String,
      avatar_url: fields[6] as String,
      full_name: fields[7] as String,
      last_sync_at: fields[8] as DateTime,
      created_at: fields[9] as DateTime,
      updated_at: fields[10] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, User obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.user_id)
      ..writeByte(1)
      ..write(obj.username)
      ..writeByte(2)
      ..write(obj.email)
      ..writeByte(3)
      ..write(obj.phone_number)
      ..writeByte(4)
      ..write(obj.password_hash)
      ..writeByte(5)
      ..write(obj.google_id)
      ..writeByte(6)
      ..write(obj.avatar_url)
      ..writeByte(7)
      ..write(obj.full_name)
      ..writeByte(8)
      ..write(obj.last_sync_at)
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
      other is UserAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
