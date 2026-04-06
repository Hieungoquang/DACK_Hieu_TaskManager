import 'package:hive/hive.dart';
part 'task_schedule_model.g.dart';

@HiveType(typeId: 5)
class TaskSchedule extends HiveObject{
  @HiveField(0)
  String schedule_id;
  @HiveField(1)
  String task_id;
  @HiveField(2)
  String availability_id;
  @HiveField(3)
  DateTime start_time;
  @HiveField(4)
  DateTime end_time;
  @HiveField(5)
  int duration_minutes;
  @HiveField(6)
  String status;
  @HiveField(7)
  int score_heuristic;
  @HiveField(8)
  bool is_auto_split;
  @HiveField(9)
  DateTime created_at;
  @HiveField(10)
  DateTime updated_at;

  TaskSchedule({
    required this.schedule_id,
    required this.task_id,
    required this.availability_id,
    required this.start_time,
    required this.end_time,
    required this.duration_minutes,
    required this.status,
    required this.score_heuristic,
    required this.is_auto_split,
    required this.created_at,
    required this.updated_at,
  });
}