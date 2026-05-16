import 'dart:async';
import '../services/sync_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:uuid/uuid.dart';
import '../models/subtask_model.dart';
import '../models/task_model.dart';
import '../models/time_logs_model.dart';
import '../models/project_model.dart';
import '../models/notification_model.dart' as notif_model;
import '../models/user_model.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/local_service.dart';
import '../services/notification_service.dart';

class TaskProvider extends ChangeNotifier {
  List<Task> _tasks = [];
  List<Task> get tasks => _tasks.where((t) => !t.isDeleted).toList();
  List<Task> get allTasks => _tasks;
  List<Task> get deletedTasks => _tasks.where((t) => t.isDeleted).toList();

  List<Project> _projects = [];
  List<Project> get projects => _projects.where((p) => !p.isDeleted).toList();
  List<Project> get allProjects => _projects;
  List<Project> get deletedProjects =>
      _projects.where((p) => p.isDeleted).toList();

  User? _currentUser;
  User? get currentUser => _currentUser;

  Timer? _globalTimer;
  String? _activeTaskId;
  int _currentSeconds = 0;
  DateTime? _startTime;
  StreamSubscription<QuerySnapshot>? _notifSubscription;

  String? get activeTaskId => _activeTaskId;
  int get currentSeconds => _currentSeconds;
  bool get isTracking => _activeTaskId != null;

  void loadTasks() async {
    final user = auth.FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final uid = user.uid;

    _tasks = LocalService.getTasks(uid);
    _tasks.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    _projects = LocalService.getProjects(uid);

    // Load User Profile from Hive
    final userBox = await Hive.openBox<User>('userBox');
    _currentUser = userBox.get(uid);

    _rescheduleAll();
    notifyListeners();

    try {
      final syncService = SyncService();

      // Fetch User Profile from Firestore with timeout
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get()
          .timeout(const Duration(seconds: 5));
      if (userDoc.exists) {
        final data = userDoc.data()!;
        _currentUser = User(
          user_id: uid,
          username: data['username'] ?? "",
          email: data['email'] ?? "",
          phone_number: data['phone_number'] ?? "",
          password_hash: "",
          google_id: "",
          avatar_url: data['avatar_url'] ?? "",
          full_name: data['full_name'] ?? "",
          last_sync_at: DateTime.now(),
          created_at:
              (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          updated_at:
              (data['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
        await userBox.put(uid, _currentUser!);
      }

      await syncService.pullProjectsFromCloud();
      _projects = LocalService.getProjects(uid);

      await syncService.pullCloudToLocal();
      _tasks = LocalService.getTasks(uid);
      _tasks.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

      _startListeningToCloudNotifications(uid);

      notifyListeners();
    } catch (e) {
      if (e.toString().contains('unavailable') ||
          e.toString().contains('offline')) {
        debugPrint("Chế độ Offline: Sử dụng dữ liệu hiện có trên máy.");
      } else {
        debugPrint("Lỗi đồng bộ dữ liệu: $e");
      }
    }
  }

  void _rescheduleAll() {
    _scheduleDailySummary();
    for (var task in _tasks) {
      _scheduleTaskNotifications(task);
    }
  }

  bool _isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  int _getNotificationId(String taskId) => taskId.hashCode.abs();
  final int _dailySummaryId = 888888;

  Future<void> _saveNotificationToDb(
    String title,
    String body,
    String type, {
    String taskId = "",
  }) async {
    final now = DateTime.now();
    final newNotif = notif_model.Notification(
      notification_id: const Uuid().v4(),
      user_id: "current_user",
      task_id: taskId,
      title: title,
      message: body,
      type: type,
      scheduled_at: now,
      isRead: false,
      created_at: now,
      updated_at: now,
    );
    await LocalService.addNotification(newNotif);
    notifyListeners();
  }

  Future<void> _scheduleTaskNotifications(Task task) async {
    if (task.status == 'completed' || task.isDeleted) return;
    final now = DateTime.now();
    final idBase = _getNotificationId(task.task_id);
    await NotificationService.cancelNotification(idBase);
    await NotificationService.cancelNotification(idBase + 1);

    if (task.deadline == null) return;
    final remind30 = task.deadline.subtract(const Duration(minutes: 30));
    if (remind30.isAfter(now)) {
      await NotificationService.scheduleNotification(
        id: idBase,
        title: '⚠️ Sắp hết hạn!',
        body: 'Công việc "${task.title}" sẽ hết hạn sau 30 phút.',
        scheduledDate: remind30,
      );
    }

    final remind5 = task.deadline.subtract(const Duration(minutes: 5));
    if (remind5.isAfter(now)) {
      await NotificationService.scheduleNotification(
        id: idBase + 1,
        title: '🔥 Gấp: Chỉ còn 5 phút!',
        body: 'Hãy hoàn thành nhanh "${task.title}".',
        scheduledDate: remind5,
      );
    }
  }

  Future<void> notifyAISuggestion(String taskTitle) async {
    const title = '🪄 AI vừa giúp bạn';
    final body = 'Lộ trình cho "$taskTitle" đã được thêm vào danh sách!';
    await NotificationService.showNotification(
      id: DateTime.now().millisecond,
      title: title,
      body: body,
    );
    await _saveNotificationToDb(title, body, 'ai_suggestion');
  }

  void _startListeningToCloudNotifications(String uid) {
    _notifSubscription?.cancel();
    _notifSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .where(
          'created_at',
          isGreaterThan: DateTime.now()
              .subtract(const Duration(hours: 1))
              .toIso8601String(),
        )
        .snapshots()
        .listen((snapshot) async {
          for (var change in snapshot.docChanges) {
            if (change.type == DocumentChangeType.added) {
              final data = change.doc.data() as Map<String, dynamic>;
              final notifId = data['notification_id'];

              // Kiểm tra xem đã có trong Hive chưa để tránh trùng lặp
              if (!LocalService.notificationExists(notifId)) {
                final newNotif = notif_model.Notification(
                  notification_id: notifId,
                  user_id: uid,
                  task_id: data['task_id'] ?? "",
                  title: data['title'] ?? "Thông báo mới",
                  message: data['message'] ?? "",
                  type: data['type'] ?? "general",
                  scheduled_at: DateTime.parse(data['scheduled_at']),
                  isRead: false,
                  created_at: DateTime.parse(data['created_at']),
                  updated_at: DateTime.parse(data['updated_at']),
                );
                await LocalService.addNotification(newNotif);

                // Hiển thị thông báo Local
                NotificationService.showNotification(
                  id: notifId.hashCode.abs(),
                  title: newNotif.title,
                  body: newNotif.message,
                );
                notifyListeners();
              }
            }
          }
        });
  }

  Future<void> sendCloudNotification({
    required String targetUserId,
    required String title,
    required String message,
    required String type,
    String taskId = "",
  }) async {
    final now = DateTime.now();
    final notifId = const Uuid().v4();

    await FirebaseFirestore.instance
        .collection('users')
        .doc(targetUserId)
        .collection('notifications')
        .doc(notifId)
        .set({
          'notification_id': notifId,
          'user_id': targetUserId,
          'task_id': taskId,
          'title': title,
          'message': message,
          'type': type,
          'scheduled_at': now.toIso8601String(),
          'isRead': false,
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        });
  }

  @override
  void dispose() {
    _notifSubscription?.cancel();
    super.dispose();
  }

  Future<void> _scheduleDailySummary() async {
    final now = DateTime.now();
    var scheduledTime = DateTime(now.year, now.month, now.day, 20, 0);
    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    final done = _tasks.where((t) {
      return t.status == 'completed' && _isSameDay(t.updatedAt, now);
    }).length;

    final pending = _tasks.where((t) {
      return t.status != 'completed' && _isSameDay(t.due_day, now);
    }).length;

    String body = "Hôm nay bạn đã xong $done việc. ";
    body += pending > 0
        ? "Còn $pending việc chưa xong, cố lên nhé!"
        : "Bạn đã hoàn thành hết mục tiêu hôm nay!";

    await NotificationService.scheduleNotification(
      id: _dailySummaryId,
      title: '📊 Tổng kết ngày',
      body: body,
      scheduledDate: scheduledTime,
      repeatDaily: true,
    );

    if (now.hour >= 20) {
      await _saveNotificationToDb('📊 Tổng kết ngày', body, 'daily_summary');
    }
  }

  // --- Project Methods ---
  Future<void> addProject(Project project) async {
    await LocalService.addProject(project);
    _projects.add(project);
    notifyListeners();

    try {
      final syncService = SyncService();
      await syncService.pushProjectsToCloud();
    } catch (e) {
      debugPrint("Lỗi push project: \$e");
    }
  }

  Future<bool> acceptProjectInvitation(String projectId) async {
    final user = auth.FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    try {
      final docRef = FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId);
      final doc = await docRef.get();
      if (!doc.exists) return false;

      final data = doc.data() as Map<String, dynamic>;
      final memberIds = List<String>.from(data['memberIds'] ?? []);
      final memberStatuses = Map<String, String>.from(
        data['memberStatuses'] ?? {},
      );

      if (!memberIds.contains(user.uid)) {
        memberIds.add(user.uid);
      }
      memberStatuses[user.uid] = 'confirmed';

      await docRef.update({
        'memberIds': memberIds,
        'memberStatuses': memberStatuses,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      final project = Project(
        project_id: data['project_id'] ?? projectId,
        user_id: data['user_id'],
        name: data['name'] ?? 'Dự án',
        description: data['description'] ?? '',
        colorValue: data['colorValue'] ?? 0xFF1CB0F6,
        createdAt: DateTime.tryParse(data['createdAt'] ?? '') ?? DateTime.now(),
        updatedAt: DateTime.now(),
        memberIds: memberIds,
        memberStatuses: memberStatuses,
      );

      await LocalService.addProject(project);
      final index = _projects.indexWhere(
        (p) => p.project_id == project.project_id,
      );
      if (index == -1) {
        _projects.add(project);
      } else {
        _projects[index] = project;
      }
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Lỗi xác nhận lời mời project: $e");
      return false;
    }
  }

  Future<void> deleteProject(String id) async {
    final index = _projects.indexWhere((p) => p.project_id == id);
    if (index == -1) return;

    final project = _projects[index];
    project.isDeleted = true;
    project.updatedAt = DateTime.now();
    await project.save();

    for (var task in _tasks.where((t) => t.project_id == id)) {
      task.isDeleted = true;
      task.updatedAt = DateTime.now();
      await task.save();
      await NotificationService.cancelNotification(
        _getNotificationId(task.task_id),
      );
      await NotificationService.cancelNotification(
        _getNotificationId(task.task_id) + 1,
      );
    }

    notifyListeners();
    _syncToCloud();
  }

  Future<void> restoreProject(String id) async {
    final project = _projects.firstWhere(
      (p) => p.project_id == id,
      orElse: () => throw Exception('Project not found'),
    );
    project.isDeleted = false;
    project.updatedAt = DateTime.now();
    await project.save();

    for (var task in _tasks.where((t) => t.project_id == id)) {
      task.isDeleted = false;
      task.updatedAt = DateTime.now();
      await task.save();
      await _scheduleTaskNotifications(task);
    }

    notifyListeners();
    _syncToCloud();
  }

  Future<void> permanentlyDeleteProject(String id) async {
    final tasksToDelete = _tasks
        .where((t) => t.project_id == id)
        .map((t) => t.task_id)
        .toList();
    await LocalService.deleteProject(id);
    _projects.removeWhere((p) => p.project_id == id);
    _tasks.removeWhere((t) => t.project_id == id);
    for (var taskId in tasksToDelete) {
      await LocalService.deleteSubtasksByTask(taskId);
    }
    notifyListeners();
    _syncToCloud();
  }

  // --- Task Methods ---
  Future<void> addTask(Task task) async {
    task.orderIndex = _tasks.length;
    task.isSynced = false;
    await LocalService.addTask(task);
    _tasks.add(task);
    await _scheduleTaskNotifications(task);
    _scheduleDailySummary();
    notifyListeners();
    _syncToCloud();
  }

  Future<void> _syncToCloud() async {
    try {
      final syncService = SyncService();
      await syncService.pushLocalToCloud();
      await syncService.pushProjectsToCloud();
    } catch (e) {
      debugPrint("Lỗi đồng bộ Cloud: $e");
    }
  }

  Future<void> updateStatus(Task task, String newStatus) async {
    task.status = newStatus;
    task.updatedAt = DateTime.now();
    task.isSynced = false;
    if (newStatus == 'completed') {
      task.progress = 100;
      final idBase = _getNotificationId(task.task_id);
      await NotificationService.cancelNotification(idBase);
      await NotificationService.cancelNotification(idBase + 1);
    } else {
      await _scheduleTaskNotifications(task);
    }
    await LocalService.updateTask(task);
    _scheduleDailySummary();
    notifyListeners();
    _syncToCloud();
  }

  Future<void> updateTask(Task task) async {
    task.updatedAt = DateTime.now();
    task.isSynced = false;
    await LocalService.updateTask(task);
    await _scheduleTaskNotifications(task);
    _scheduleDailySummary();
    notifyListeners();
    _syncToCloud();
  }

  Future<void> updateTaskDeadline(String taskId, DateTime newDate) async {
    final index = _tasks.indexWhere((t) => t.task_id == taskId);
    if (index != -1) {
      final task = _tasks[index];
      final oldDeadline = task.deadline ?? DateTime.now();

      // Kiểm tra an toàn khi tính toán deadline
      DateTime start = DateTime(
        newDate.year,
        newDate.month,
        newDate.day,
        oldDeadline.hour,
        oldDeadline.minute,
      );
      task.deadline = start;
      task.due_day = DateTime(newDate.year, newDate.month, newDate.day);
      task.updatedAt = DateTime.now();
      task.isSynced = false;
      await LocalService.updateTask(task);
      await _scheduleTaskNotifications(task);
      _scheduleDailySummary();
      notifyListeners();
      _syncToCloud();
    }
  }

  Future<void> deleteTask(String id) async {
    final index = _tasks.indexWhere((t) => t.task_id == id);
    if (index != -1) {
      final task = _tasks[index];
      task.isDeleted = true;
      task.isSynced = false;
      task.updatedAt = DateTime.now();
      await task.save();
    }
    await NotificationService.cancelNotification(_getNotificationId(id));
    await NotificationService.cancelNotification(_getNotificationId(id) + 1);
    notifyListeners();
    _scheduleDailySummary();
    _syncToCloud();
  }

  Future<void> restoreTask(String id) async {
    final index = _tasks.indexWhere((t) => t.task_id == id);
    if (index != -1) {
      final task = _tasks[index];
      task.isDeleted = false;
      task.isSynced = false;
      task.updatedAt = DateTime.now();
      await task.save();
      await _scheduleTaskNotifications(task);
      _scheduleDailySummary();
      notifyListeners();
      _syncToCloud();
    }
  }

  Future<void> permanentlyDeleteTask(String id) async {
    final index = _tasks.indexWhere((t) => t.task_id == id);
    if (index != -1) {
      await LocalService.deleteSubtasksByTask(id);
      await LocalService.deleteTask(id);
      _tasks.removeAt(index);
    }
    await NotificationService.cancelNotification(_getNotificationId(id));
    await NotificationService.cancelNotification(_getNotificationId(id) + 1);
    _scheduleDailySummary();
    notifyListeners();
    _syncToCloud();
  }

  List<Subtask> getSubtasks(String taskId) => LocalService.getSubtasks(taskId);

  Future<void> addSubtask(String taskId, String title) async {
    final newSub = Subtask(
      subtask_id: const Uuid().v4(),
      task_id: taskId,
      title: title,
      is_completed: false,
      created_at: DateTime.now(),
    );
    await LocalService.addSubtask(newSub);
    await _calculateMainTaskProgress(taskId);
    notifyListeners();
  }

  Future<void> toggleSubtask(Subtask subtask) async {
    subtask.is_completed = !subtask.is_completed;
    await subtask.save();
    await _calculateMainTaskProgress(subtask.task_id);
    notifyListeners();
  }

  Future<void> _calculateMainTaskProgress(String taskId) async {
    final subs = LocalService.getSubtasks(taskId);
    if (subs.isEmpty) return;
    final done = subs.where((s) => s.is_completed).length;
    final int progress = ((done / subs.length) * 100).toInt();
    final index = _tasks.indexWhere((t) => t.task_id == taskId);
    if (index != -1) await updateProgress(_tasks[index], progress);
  }

  Future<void> updateProgress(Task task, int value) async {
    task.progress = value;
    task.isSynced = false;
    if (value == 100) {
      task.status = 'completed';
      task.updatedAt = DateTime.now();
    } else {
      task.status = value == 0 ? 'pending' : 'in_progress';
    }
    await LocalService.updateTask(task);
    _scheduleDailySummary();
    notifyListeners();
    _syncToCloud();
  }

  void startTimer(String taskId) {
    if (_activeTaskId != null && _activeTaskId != taskId) stopTimer();
    _activeTaskId = taskId;
    _startTime = DateTime.now();
    _currentSeconds = 0;
    _globalTimer?.cancel();
    _globalTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _currentSeconds++;
      notifyListeners();
    });
    notifyListeners();
  }

  Future<void> stopTimer() async {
    if (_activeTaskId == null) return;
    if (_currentSeconds >= 1) {
      final now = DateTime.now();
      final log = Time_logs(
        log_id: const Uuid().v4(),
        task_id: _activeTaskId!,
        start_time: _startTime!,
        end_time: now,
        duration_minutes: (_currentSeconds / 60).ceil().clamp(1, 999),
        notes: "Tập trung",
        created_at: now,
        updated_at: now,
      );
      await LocalService.addLog(log);
    }
    _globalTimer?.cancel();
    _activeTaskId = null;
    _currentSeconds = 0;
    notifyListeners();
  }

  List<Time_logs> getLogsByTask(String taskId) =>
      LocalService.getLogsByTask(taskId);
}
