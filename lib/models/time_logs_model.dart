import 'package:hive/hive.dart';
part 'time_logs_model.g.dart';

@HiveType(typeId: 4)
class Time_logs extends HiveObject{
  @HiveField(0)
  String log_id;
  @HiveField(1)
  String task_id;
  @HiveField(2)
  DateTime start_time;
  @HiveField(3)
  DateTime end_time;
  @HiveField(4)
  int duration_minutes;
  @HiveField(5)
  String notes;
  @HiveField(6)
  DateTime created_at;
  @HiveField(7)
  DateTime updated_at;

  Time_logs({
   required this.log_id,
   required this.task_id,
   required this.start_time,
   required this.end_time,
   required this.duration_minutes,
   required this.notes,
   required this.created_at,
   required this.updated_at,
});
}