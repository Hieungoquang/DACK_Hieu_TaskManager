import 'package:hive/hive.dart';
part 'subtask_model.g.dart';

@HiveType(typeId: 2)
class Subtask extends HiveObject {
  @HiveField(0)
  String subtask_id;
  @HiveField(1)
  String task_id;
  @HiveField(2)
  String title;
  @HiveField(3)
  bool is_completed;
  @HiveField(4)
  DateTime created_at;

  Subtask({
    required this.subtask_id,
    required this.task_id,
    required this.title,
    required this.is_completed,
    required this.created_at,
});

}

