import 'package:hive/hive.dart';

part 'project_model.g.dart';

@HiveType(typeId: 3)
class Project extends HiveObject {
  @HiveField(0)
  String project_id;

  @HiveField(1)
  String user_id;

  @HiveField(2)
  String name;

  @HiveField(3)
  String description;

  @HiveField(4)
  int colorValue;

  @HiveField(5)
  DateTime createdAt;

  @HiveField(6)
  DateTime updatedAt;

  @HiveField(7)
  List<String> memberIds; // Danh sách ID thành viên (Bạn bè)

  @HiveField(8)
  Map<String, String>? memberStatuses; // id -> 'pending' or 'confirmed'

  @HiveField(9)
  bool isDeleted;

  @HiveField(10)
  DateTime? startDate;

  @HiveField(11)
  DateTime? endDate;

  Project({
    required this.project_id,
    required this.user_id,
    required this.name,
    this.description = "",
    this.colorValue = 0xFFFF0000,
    required this.createdAt,
    required this.updatedAt,
    this.memberIds = const [],
    this.memberStatuses = const {},
    this.isDeleted = false,
    this.startDate,
    this.endDate,
  });
}
