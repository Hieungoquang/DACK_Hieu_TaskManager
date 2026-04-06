import 'package:hive/hive.dart';
part 'user_availability_model.g.dart';

@HiveType(typeId: 7)
class UserAvailability extends HiveObject {
  @HiveField(0)
  String availability_id;
  @HiveField(1)
  String user_id;
  @HiveField(2)
  DateTime date;
  @HiveField(3)
  String start_time;
  @HiveField(4)
  String end_time;
  @HiveField(5)
  int duration_minute;
  @HiveField(6)
  bool isRecurring;
  @HiveField(7)
  int day_of_week;
  @HiveField(8)
  DateTime created_at;

  UserAvailability({
    required this.availability_id,
    required this.user_id,
    required this.date,
    required this.start_time,
    required this.end_time,
    required this.duration_minute,
    required this.isRecurring,
    required this.day_of_week,
    required this.created_at,
});
}