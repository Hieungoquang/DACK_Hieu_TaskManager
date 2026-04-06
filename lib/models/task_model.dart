import'package:hive/hive.dart';
part 'task_model.g.dart';

@HiveType(typeId: 0)
class Task extends HiveObject {
  @HiveField(0)
  String task_id;
  @HiveField(1)
  String user_id;
  @HiveField(2)
  String title;
  @HiveField(3)
  String description;
  @HiveField(4)
  DateTime due_day;
  @HiveField(5)
  int priority;
  @HiveField(6)
  int progress;
  @HiveField(7)
  int duration;
  @HiveField(8)
  DateTime deadline;
  @HiveField(9)
  String status;
  @HiveField(10)
  DateTime createdAt;
  @HiveField(11)
  DateTime updatedAt;
  @HiveField(12)
  bool isSynced;
  @HiveField(13)
  bool isDeleted;

  Task({
    required this.task_id,
    required this.user_id,
    required this.title,
    required this.description,
    required this.due_day,
    required this.priority,
    required this.progress,
    required this.duration,
    required this.deadline,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.isSynced = false,
    this.isDeleted = false,
  });
}
