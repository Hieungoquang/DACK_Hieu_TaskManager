import 'dart:async';
import '../services/sync_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:uuid/uuid.dart';
import '../models/subtask_model.dart';
import '../models/task_model.dart';
import '../models/task_category_model.dart';
import '../models/time_logs_model.dart';
import '../models/project_model.dart';
import '../models/notification_model.dart' as notif_model;
import '../models/user_model.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/local_service.dart';
import '../services/notification_service.dart';
import '../services/prediction_service.dart';

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

  List<TaskCategory> _categories = [];
  List<TaskCategory> get categories => _categories;

  User? _currentUser;
  User? get currentUser => _currentUser;

  Timer? _globalTimer;
  String? _activeTaskId;
  int _currentSeconds = 0;
  DateTime? _startTime;
  StreamSubscription<QuerySnapshot>? _notifSubscription;

  Timer? _autoStatusTimer;

  TaskProvider() {
    // Mỗi 30 giây, tự động chuyển những công việc tới giờ sang "đang làm"
    // (phòng trường hợp người dùng quên đặt trạng thái).
    _autoStatusTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      autoStartDueTasks();
    });
  }

  /// Tự động set status='in_progress' cho các task đang ở trong khung giờ
  /// thực hiện (now ∈ [due_day, deadline]) nhưng vẫn còn 'pending'.
  void autoStartDueTasks() {
    final now = DateTime.now();
    bool changed = false;
    for (var t in _tasks) {
      if (t.isDeleted) continue;
      if (t.status != 'pending') continue;
      if (now.isAfter(t.due_day) && now.isBefore(t.deadline)) {
        t.status = 'in_progress';
        t.updatedAt = now;
        t.isSynced = false;
        try {
          t.save();
        } catch (_) {}
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }

  Map<String, double> _crisisProbabilities = {};
  Map<String, double> get crisisProbabilities => _crisisProbabilities;
  final Set<String> _warnedCrisisTasks = {};

  List<Task> get crisisTasks {
    return tasks
        .where((t) =>
            _crisisProbabilities.containsKey(t.task_id) &&
            _crisisProbabilities[t.task_id]! >= 0.7)
        .toList();
  }

  List<int> getGoldenHours() {
    final completed = allTasks.where((t) => t.status == 'completed').toList();
    final logs = LocalService.logBox.values.toList();
    return PredictionService.calculateGoldenHours(logs, completed);
  }

  void _calculateCrisisProbabilities() {
    _crisisProbabilities.clear();
    double delayRate = PredictionService.calculateDelayRate(allTasks);
    for (var task in tasks) {
      if (task.status != 'completed' && !task.isDeleted) {
        final project =
            _projects.where((p) => p.project_id == task.project_id).firstOrNull;
        double prob = PredictionService.calculateCrisisProbability(
          task,
          delayRate,
          projectStartDate: project?.startDate,
          projectEndDate: project?.endDate,
        );
        if (prob > 0) {
          _crisisProbabilities[task.task_id] = prob;

          if (prob >= 0.7 && !_warnedCrisisTasks.contains(task.task_id)) {
            _warnedCrisisTasks.add(task.task_id);
            _triggerCrisisNotification(task, prob);
          }
        }
      }
    }
  }

  Future<void> _triggerCrisisNotification(Task task, double prob) async {
    final percent = (prob * 100).toInt();
    await NotificationService.showNotification(
      id: task.task_id.hashCode.abs() + 999, // Unique ID for crisis
      title: '🚨 Cảnh báo Khủng hoảng Deadline',
      body:
          'Công việc "${task.title}" có nguy cơ trễ hạn rất cao ($percent%). Hãy xử lý ngay!',
    );
  }

  String? get activeTaskId => _activeTaskId;
  int get currentSeconds => _currentSeconds;
  bool get isTracking => _activeTaskId != null;

  void loadTasks() async {
    final user = auth.FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final uid = user.uid;

    _tasks = LocalService.getTasks(uid);
    _tasks.sort((a, b) => (a.orderIndex ?? 0).compareTo(b.orderIndex ?? 0));
    _projects = LocalService.getProjects(uid);
    _categories = LocalService.getCategories(uid);

    final userBox = await Hive.openBox<User>('userBox');
    _currentUser = userBox.get(uid);

    _rescheduleAll();
    _calculateCrisisProbabilities();
    autoStartDueTasks();
    notifyListeners();

    try {
      final syncService = SyncService();

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
      _tasks.sort((a, b) => (a.orderIndex ?? 0).compareTo(b.orderIndex ?? 0));

      _startListeningToCloudNotifications(uid);

      _calculateCrisisProbabilities();
      notifyListeners();
    } catch (e) {
      debugPrint("Sync error: $e");
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
    _autoStatusTimer?.cancel();
    _globalTimer?.cancel();
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

  // --- Category Methods ---
  Future<void> addCategory(TaskCategory category) async {
    await LocalService.addCategory(category);
    _categories.add(category);
    notifyListeners();
  }

  Future<void> deleteCategory(String id) async {
    await LocalService.deleteCategory(id);
    _categories.removeWhere((c) => c.id == id);
    notifyListeners();
  }

  Future<void> updateCategory(TaskCategory category) async {
    await LocalService.updateCategory(category);
    final index = _categories.indexWhere((c) => c.id == category.id);
    if (index != -1) {
      _categories[index] = category;
    }
    notifyListeners();
  }

  Color getTaskColor(Task task) {
    // 1. Công việc thuộc dự án: Mặc định Đỏ
    if (task.project_id != null && task.project_id!.isNotEmpty)
      return Colors.red;

    // 2. Công việc thuộc nhóm cá nhân: Lấy màu của nhóm
    if (task.categoryId != null && task.categoryId!.isNotEmpty) {
      try {
        final cat = _categories.firstWhere((c) => c.id == task.categoryId);
        return Color(cat.colorValue);
      } catch (_) {}
    }

    // 3. Mặc định (GitHub Blue)
    return const Color(0xFF58A6FF);
  }

  // --- Project Methods ---
  Future<void> addProject(Project project) async {
    await LocalService.addProject(project);
    _projects.add(project);
    notifyListeners();
    _syncToCloud();
  }

  Future<void> updateProject(Project project) async {
    project.updatedAt = DateTime.now();
    await LocalService.updateProject(project);
    final index =
        _projects.indexWhere((p) => p.project_id == project.project_id);
    if (index != -1) {
      _projects[index] = project;
    }
    notifyListeners();
    _syncToCloud();
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
          _getNotificationId(task.task_id));
      await NotificationService.cancelNotification(
          _getNotificationId(task.task_id) + 1);
    }

    notifyListeners();
    _syncToCloud();
  }

  Future<void> restoreProject(String id) async {
    final index = _projects.indexWhere((p) => p.project_id == id);
    if (index == -1) return;

    final project = _projects[index];
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
    final tasksToDelete =
        _tasks.where((t) => t.project_id == id).map((t) => t.task_id).toList();
    await LocalService.deleteProject(id);
    _projects.removeWhere((p) => p.project_id == id);
    _tasks.removeWhere((t) => t.project_id == id);
    for (var taskId in tasksToDelete) {
      await LocalService.deleteSubtasksByTask(taskId);
    }
    notifyListeners();
    _syncToCloud();
  }

  Future<bool> acceptProjectInvitation(String projectId) async {
    final user = auth.FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    try {
      final docRef =
          FirebaseFirestore.instance.collection('projects').doc(projectId);
      final doc = await docRef.get();
      if (!doc.exists) return false;

      final data = doc.data() as Map<String, dynamic>;
      final memberIds = List<String>.from(data['memberIds'] ?? []);
      final memberStatuses =
          Map<String, String>.from(data['memberStatuses'] ?? {});

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
      final index =
          _projects.indexWhere((p) => p.project_id == project.project_id);
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

  // --- Task Methods ---
  Future<void> addTask(Task task) async {
    task.orderIndex = _tasks.length;
    task.isSynced = false;
    await LocalService.addTask(task);
    _tasks.add(task);
    await _scheduleTaskNotifications(task);
    _scheduleDailySummary();
    _calculateCrisisProbabilities();
    notifyListeners();
    _syncToCloud();
  }

  Future<void> _syncToCloud() async {
    try {
      final syncService = SyncService();
      await syncService.pushLocalToCloud();
      await syncService.pushProjectsToCloud();
    } catch (e) {
      debugPrint("Cloud sync error: $e");
    }
  }

  Future<void> updateTask(Task task) async {
    final wasCompleted =
        _tasks.any((t) => t.task_id == task.task_id && t.status == 'completed');
    final isCompleted = task.status == 'completed';

    task.updatedAt = DateTime.now();
    task.isSynced = false;
    await LocalService.updateTask(task);
    await _scheduleTaskNotifications(task);
    _scheduleDailySummary();
    _calculateCrisisProbabilities();

    if (!wasCompleted && isCompleted) {
      _checkAndNotifyUnlockedTasks(task.task_id, task.title);
    }

    notifyListeners();
    _syncToCloud();
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
    _scheduleDailySummary();
    _calculateCrisisProbabilities();
    notifyListeners();
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
      _calculateCrisisProbabilities();
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
    _calculateCrisisProbabilities();
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
    _calculateCrisisProbabilities();
    notifyListeners();
    _syncToCloud();
  }

  void startTimer(String taskId) {
    final task = _tasks.where((t) => t.task_id == taskId).firstOrNull;
    if (task != null && isTaskLocked(task)) return;

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

  Task? checkOverlapWithProjectTask(Task newTask) {
    final startA = newTask.due_day;
    final endA = newTask.deadline;

    for (var t in tasks) {
      if (t.project_id != null && t.task_id != newTask.task_id) {
        final startB = t.due_day;
        final endB = t.deadline;
        if (startA.isBefore(endB) && endA.isAfter(startB)) {
          return t;
        }
      }
    }
    return null;
  }

  /// Tìm task khác trong CÙNG dự án có thời gian trùng với [newTask].
  Task? checkOverlapInSameProject(Task newTask, String projectId) {
    final startA = newTask.due_day;
    final endA = newTask.deadline;
    for (var t in tasks) {
      if (t.isDeleted) continue;
      if (t.task_id == newTask.task_id) continue;
      if (t.project_id != projectId) continue;
      final startB = t.due_day;
      final endB = t.deadline;
      if (startA.isBefore(endB) && endA.isAfter(startB)) {
        return t;
      }
    }
    return null;
  }

  // --- Task Dependency & Automation Helpers ---

  bool isTaskLocked(Task task) {
    if (task.dependencyTaskId == null || task.dependencyTaskId!.isEmpty)
      return false;
    final prereq = _tasks
        .where((t) => t.task_id == task.dependencyTaskId && !t.isDeleted)
        .firstOrNull;
    if (prereq == null) return false;
    return prereq.status != 'completed';
  }

  Task? getPrerequisiteTask(Task task) {
    if (task.dependencyTaskId == null || task.dependencyTaskId!.isEmpty)
      return null;
    return _tasks
        .where((t) => t.task_id == task.dependencyTaskId && !t.isDeleted)
        .firstOrNull;
  }

  List<Task> getPrerequisiteCandidates(Task currentTask) {
    final projectTasks = tasks
        .where((t) =>
            t.project_id == currentTask.project_id &&
            t.task_id != currentTask.task_id)
        .toList();

    final validCandidates = <Task>[];
    for (var task in projectTasks) {
      if (!_isDependentOn(task, currentTask.task_id)) {
        validCandidates.add(task);
      }
    }
    return validCandidates;
  }

  bool _isDependentOn(Task task, String targetTaskId) {
    if (task.dependencyTaskId == null || task.dependencyTaskId!.isEmpty)
      return false;
    if (task.dependencyTaskId == targetTaskId) return true;
    final parent = _tasks
        .where((t) => t.task_id == task.dependencyTaskId && !t.isDeleted)
        .firstOrNull;
    if (parent == null) return false;
    return _isDependentOn(parent, targetTaskId);
  }

  void _checkAndNotifyUnlockedTasks(
      String completedTaskId, String completedTaskTitle) async {
    final unlockedTasks = tasks
        .where((t) => t.dependencyTaskId == completedTaskId && !isTaskLocked(t))
        .toList();

    for (var task in unlockedTasks) {
      final notifTitle = '🔓 Khóa chuỗi công việc được mở';
      final notifBody =
          'Công việc "${task.title}" đã được mở khóa vì "${completedTaskTitle}" đã hoàn thành!';
      await NotificationService.showNotification(
        id: task.task_id.hashCode.abs() + 2000,
        title: notifTitle,
        body: notifBody,
      );
      await _saveNotificationToDb(notifTitle, notifBody, 'task_unlocked',
          taskId: task.task_id);
    }
  }
}
