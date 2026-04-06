import 'package:hive/hive.dart';
part 'notification_model.g.dart';

@HiveType(typeId: 6)
class Notification extends HiveObject{
  @HiveField(0)
  String notification_id;
  @HiveField(1)
  String user_id;
  @HiveField(2)
  String task_id;
  @HiveField(3)
  String title;
  @HiveField(4)
  String message;
  @HiveField(5)
  String type;
  @HiveField(6)
  DateTime scheduled_at;
  @HiveField(7)
  bool isRead;
  @HiveField(8)
  DateTime created_at;
  @HiveField(9)
  DateTime updated_at;

  Notification({
    required this.notification_id,
    required this.user_id,
    required this.task_id,
    required this.title,
    required this.message,
    required this.type,
    required this.scheduled_at,
    required this.isRead,
    required this.created_at,
    required this.updated_at,
});
}