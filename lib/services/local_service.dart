import 'package:hive/hive.dart';
import '../models/task_model.dart';
import '../models/time_logs_model.dart';


class LocalService {
  static final taskBox = Hive.box<Task>("tasksBox");
  static final logBox = Hive.box<Time_logs>("timeLogsBox");

  //lay danh sach
  static List<Task> getTasks() {
    return taskBox.values.toList();
  }

  //them cong viec
  static Future<void> addTask(Task task) async {
    await taskBox.put(task.task_id, task);
  }

  //xoa cong viec
  static Future<void> deleteTask(String id) async {
    await taskBox.delete(id);
  }

  //cap nhat cong viec
  static Future<void> updateTask(Task task) async {
    await task.save();
  }

  // them log cho cong viec
  static Future<void> addLog(Time_logs log) async {
    await logBox.put(log.log_id, log);
  }

  //lay log theo task
  static List<Time_logs> getLogsByTask(String taskId) {
    return logBox.values.where((l) => l.task_id == taskId).toList();
  }

}