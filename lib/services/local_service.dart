import 'package:hive/hive.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/task_model.dart';
import '../models/time_logs_model.dart';
import '../models/subtask_model.dart';
import '../models/notification_model.dart';
import '../models/project_model.dart';
import '../models/task_category_model.dart';

class LocalService {
  static final taskBox = Hive.box<Task>("tasksBox");
  static final logBox = Hive.box<Time_logs>("timeLogsBox");
  static final subtaskBox = Hive.box<Subtask>("subtasksBox");
  static final notificationBox = Hive.box<Notification>("notificationsBox");
  static final projectBox = Hive.box<Project>("projectsBox");
  static final categoryBox = Hive.box<TaskCategory>("categoriesBox");

  // --- Project ---
  static List<Project> getProjects(String uid) {
    return projectBox.values
        .where((p) => p.user_id == uid || p.memberIds.contains(uid))
        .toList();
  }

  static Future<void> addProject(Project project) async {
    await projectBox.put(project.project_id, project);
  }

  static Future<void> deleteProject(String id) async {
    await projectBox.delete(id);
    // Xóa tất cả task thuộc project này
    final tasksToDelete =
        taskBox.values.where((t) => t.project_id == id).map((t) => t.task_id);
    await taskBox.deleteAll(tasksToDelete);
  }

  static Future<void> updateProject(Project project) async {
    await project.save();
  }

  // --- Task Categories ---
  static List<TaskCategory> getCategories(String uid) {
    return categoryBox.values.where((c) => c.userId == uid).toList();
  }

  static Future<void> addCategory(TaskCategory category) async {
    await categoryBox.put(category.id, category);
  }

  static Future<void> deleteCategory(String id) async {
    await categoryBox.delete(id);
  }

  static Future<void> updateCategory(TaskCategory category) async {
    await categoryBox.put(category.id, category);
  }

  // --- Task ---
  static List<Task> getTasks(String uid) {
    final projects = getProjects(uid);
    final myProjectIds = projects.map((p) => p.project_id).toList();

    return taskBox.values.where((t) {
      // 1. Task do mình tạo
      if (t.user_id == uid) return true;
      // 2. Task được giao cho mình
      if (t.assigneeId == uid) return true;
      // 3. Task thuộc project mà mình tham gia
      if (t.project_id != null && myProjectIds.contains(t.project_id))
        return true;

      return false;
    }).toList();
  }

  static List<Task> getTasksByProject(String projectId) {
    return taskBox.values.where((t) => t.project_id == projectId).toList();
  }

  static Future<void> addTask(Task task) async {
    await taskBox.put(task.task_id, task);
  }

  static Future<void> deleteTask(String id) async {
    await taskBox.delete(id);
  }

  static Future<void> updateTask(Task task) async {
    await task.save();
  }

  // --- Log ---
  static Future<void> addLog(Time_logs log) async {
    await logBox.put(log.log_id, log);
  }

  static List<Time_logs> getLogsByTask(String taskId) {
    return logBox.values.where((l) => l.task_id == taskId).toList();
  }

  // --- Subtask ---
  static List<Subtask> getSubtasks(String taskId) {
    return subtaskBox.values.where((s) => s.task_id == taskId).toList();
  }

  static Future<void> addSubtask(Subtask subtask) async {
    await subtaskBox.put(subtask.subtask_id, subtask);
  }

  static Future<void> deleteSubtasksByTask(String taskId) async {
    final toDelete = subtaskBox.values
        .where((s) => s.task_id == taskId)
        .map((s) => s.subtask_id);
    await subtaskBox.deleteAll(toDelete);
  }

  // --- Notification ---
  static List<Notification> getNotifications() {
    return notificationBox.values.toList()
      ..sort((a, b) => b.created_at.compareTo(a.created_at));
  }

  static Future<void> addNotification(Notification notification) async {
    await notificationBox.put(notification.notification_id, notification);
  }

  static bool notificationExists(String id) {
    return notificationBox.containsKey(id);
  }

  static Future<void> clearAll() async {
    await taskBox.clear();
    await projectBox.clear();
    await logBox.clear();
    await subtaskBox.clear();
    await notificationBox.clear();
    await categoryBox.clear();
  }
}
