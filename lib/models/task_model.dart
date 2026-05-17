import 'package:hive/hive.dart';
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
  String status; // 'pending', 'in_progress', 'completed'
  @HiveField(10)
  DateTime createdAt;
  @HiveField(11)
  DateTime updatedAt;
  @HiveField(12)
  bool isSynced;
  @HiveField(13)
  bool isDeleted;
  @HiveField(14)
  String category; // 'Công việc', 'Cá nhân', 'Học tập',...
  @HiveField(15)
  int orderIndex; // Thứ tự hiển thị
  @HiveField(16)
  String? project_id; // Liên kết với dự án
  @HiveField(17)
  String? assigneeId; // ID người thực hiện
  @HiveField(18)
  List<String> attachments; // Danh sách tệp đính kèm
  @HiveField(19)
  int reminder; // Thời gian thông báo trước (phút), 0 = không thông báo
  @HiveField(20)
  String? categoryId; // ID của nhóm công việc cá nhân
  @HiveField(21)
  String? dependencyTaskId; // ID của công việc tiên quyết

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
    this.category = 'Công việc',
    this.orderIndex = 0,
    this.project_id,
    this.assigneeId,
    this.attachments = const [],
    this.reminder = 0,
    this.categoryId,
    this.dependencyTaskId,
  });
}
