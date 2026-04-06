import 'package:hive/hive.dart';
part 'user_model.g.dart';

@HiveType(typeId: 1)
class User extends HiveObject {
  @HiveField(0)
  String user_id;
  @HiveField(1)
  String username;
  @HiveField(2)
  String email;
  @HiveField(3)
  String phone_number;
  @HiveField(4)
  String password_hash;
  @HiveField(5)
  String google_id;
  @HiveField(6)
  String avatar_url;
  @HiveField(7)
  String full_name;
  @HiveField(8)
  DateTime last_sync_at;
  @HiveField(9)
  DateTime created_at;
  @HiveField(10)
  DateTime updated_at;

  User({
    required this.user_id,
    required this.username,
    required this.email,
    required this.phone_number,
    required this.password_hash,
    required this.google_id,
    required this.avatar_url,
    required this.full_name,
    required this.last_sync_at,
    required this.created_at,
    required this.updated_at,
});

}
