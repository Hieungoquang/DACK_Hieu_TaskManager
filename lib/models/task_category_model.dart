import 'package:hive/hive.dart';

part 'task_category_model.g.dart';

@HiveType(typeId: 8)
class TaskCategory extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  int colorValue;

  @HiveField(3)
  String userId;

  TaskCategory({
    required this.id,
    required this.name,
    required this.colorValue,
    required this.userId,
  });
}
