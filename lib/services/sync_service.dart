import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/task_model.dart';
import '../models/subtask_model.dart';
import '../models/project_model.dart';
import '../models/notification_model.dart' as model;
import '../models/user_availability_model.dart';
import '../models/task_schedule_model.dart';

class SyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Đẩy dữ liệu từ Local (Hive) lên Firestore
  Future<void> pushLocalToCloud() async {
    final user = _auth.currentUser;
    if (user == null) return;

    var taskBox = Hive.box<Task>('tasksBox');
    List<Task> unsyncedTasks =
        taskBox.values.where((task) => !task.isSynced).toList();

    for (var task in unsyncedTasks) {
      // Xác định đường dẫn collection dựa trên việc task có thuộc project hay không
      DocumentReference taskDoc;
      if (task.project_id != null && task.project_id!.isNotEmpty) {
        taskDoc = _firestore
            .collection('projects')
            .doc(task.project_id)
            .collection('tasks')
            .doc(task.task_id);
      } else {
        taskDoc = _firestore
            .collection('users')
            .doc(user.uid)
            .collection('tasks')
            .doc(task.task_id);
      }

      if (task.isDeleted) {
        await taskDoc.delete();
        await task.delete();
      } else {
        var subtaskBox = Hive.box<Subtask>('subtasksBox');
        List<Map<String, dynamic>> subtasksData = subtaskBox.values
            .where((s) => s.task_id == task.task_id)
            .map(
              (s) => {
                'subtask_id': s.subtask_id,
                'title': s.title,
                'is_completed': s.is_completed,
                'created_at': s.created_at.toIso8601String(),
              },
            )
            .toList();

        await taskDoc.set({
          'task_id': task.task_id,
          'user_id': task.user_id,
          'title': task.title,
          'description': task.description,
          'priority': task.priority,
          'progress': task.progress,
          'due_day': task.due_day.toIso8601String(),
          'deadline': task.deadline.toIso8601String(),
          'duration': task.duration,
          'status': task.status,
          'category': task.category,
          'project_id': task.project_id,
          'assigneeId': task.assigneeId,
          'createdAt': task.createdAt.toIso8601String(),
          'updatedAt': task.updatedAt.toIso8601String(),
          'subtasks': subtasksData,
        });

        task.isSynced = true;
        await task.save();
      }
    }
  }

  // Tải dữ liệu từ Cloud (Firestore) về Local (Hive)
  Future<void> pullCloudToLocal() async {
    final user = _auth.currentUser;
    if (user == null) return;

    var taskBox = Hive.box<Task>('tasksBox');
    var projectBox = Hive.box<Project>('projectsBox');
    var subtaskBox = Hive.box<Subtask>('subtasksBox');

    Map<String, Task> pulledTasks = {};
    List<Map<String, dynamic>> allSubtasks = [];

    // 1. Kéo tasks cá nhân
    QuerySnapshot privateSnapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('tasks')
        .get();

    for (var doc in privateSnapshot.docs) {
      pulledTasks[doc.id] = _parseTaskFromDoc(doc, user.uid);
      _extractSubtasks(doc, allSubtasks);
    }

    // 2. Kéo tasks từ các dự án (được quản lý tập trung)
    // Lấy danh sách project user tham gia (đã được pull ở bước trước đó hoặc pull ngay tại đây)
    var ownedProjects = await _firestore
        .collection('projects')
        .where('user_id', isEqualTo: user.uid)
        .get();
    var memberProjects = await _firestore
        .collection('projects')
        .where('memberIds', arrayContains: user.uid)
        .get();

    Set<String> projectIds = {
      ...ownedProjects.docs.map((d) => d.id),
      ...memberProjects.docs.map((d) => d.id),
    };

    for (var projectId in projectIds) {
      QuerySnapshot projectTasks = await _firestore
          .collection('projects')
          .doc(projectId)
          .collection('tasks')
          .get();

      for (var doc in projectTasks.docs) {
        pulledTasks[doc.id] = _parseTaskFromDoc(doc, user.uid);
        _extractSubtasks(doc, allSubtasks);
      }
    }

    // Cập nhật vào Hive
    for (var task in pulledTasks.values) {
      await taskBox.put(task.task_id, task);
    }

    for (var s in allSubtasks) {
      final subtask = Subtask(
        subtask_id: s['subtask_id'],
        task_id: s['task_id'],
        title: s['title'],
        is_completed: s['is_completed'],
        created_at: DateTime.parse(s['created_at']),
      );
      await subtaskBox.put(subtask.subtask_id, subtask);
    }
  }

  void _extractSubtasks(
    QueryDocumentSnapshot doc,
    List<Map<String, dynamic>> targetList,
  ) {
    final data = doc.data() as Map<String, dynamic>;
    if (data.containsKey('subtasks')) {
      List<dynamic> subData = data['subtasks'];
      for (var s in subData) {
        Map<String, dynamic> subMap = Map<String, dynamic>.from(s);
        subMap['task_id'] = doc.id;
        targetList.add(subMap);
      }
    }
  }

  Task _parseTaskFromDoc(QueryDocumentSnapshot doc, String defaultUserId) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Task(
      task_id: data['task_id'] ?? doc.id,
      user_id: data['user_id'] ?? defaultUserId,
      title: data['title'] ?? 'No Title',
      description: data['description'] ?? '',
      due_day: data['due_day'] != null
          ? DateTime.parse(data['due_day'])
          : DateTime.now(),
      priority: data['priority'] ?? 0,
      progress: data['progress'] ?? 0,
      duration: data['duration'] ?? 60,
      deadline: data['deadline'] != null
          ? DateTime.parse(data['deadline'])
          : (data['due_day'] != null
              ? DateTime.parse(data['due_day'])
              : DateTime.now()),
      status: data['status'] ?? 'pending',
      category: data['category'] ?? 'Công việc',
      project_id: data['project_id'],
      createdAt: data['createdAt'] != null
          ? DateTime.parse(data['createdAt'])
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? DateTime.parse(data['updatedAt'])
          : DateTime.now(),
      isSynced: true,
    );
  }

  // Đẩy Project từ Local (Hive) lên Firestore
  Future<void> pushProjectsToCloud() async {
    final user = _auth.currentUser;
    if (user == null) return;

    var projectBox = Hive.box<Project>('projectsBox');

    for (var project in projectBox.values) {
      if (project.user_id == user.uid || project.memberIds.contains(user.uid)) {
        if (project.isDeleted) {
          await _firestore
              .collection('projects')
              .doc(project.project_id)
              .delete();
          continue;
        }

        await _firestore.collection('projects').doc(project.project_id).set({
          'project_id': project.project_id,
          'user_id': project.user_id,
          'name': project.name,
          'description': project.description,
          'colorValue': project.colorValue,
          'createdAt': project.createdAt.toIso8601String(),
          'updatedAt': project.updatedAt.toIso8601String(),
          'memberIds': project.memberIds,
          'memberStatuses': project.memberStatuses,
        });
      }
    }
  }

  // Tải Project từ Cloud (Firestore) về Local (Hive)
  Future<void> pullProjectsFromCloud() async {
    final user = _auth.currentUser;
    if (user == null) return;

    var projectBox = Hive.box<Project>('projectsBox');

    // Tìm các project do user tạo (Timeout 10s)
    var ownedProjects = await _firestore
        .collection('projects')
        .where('user_id', isEqualTo: user.uid)
        .get()
        .timeout(const Duration(seconds: 10));

    // Tìm các project mà user là thành viên
    var memberProjects = await _firestore
        .collection('projects')
        .where('memberIds', arrayContains: user.uid)
        .get()
        .timeout(const Duration(seconds: 10));

    Map<String, DocumentSnapshot> allProjectDocs = {};
    for (var doc in ownedProjects.docs) allProjectDocs[doc.id] = doc;
    for (var doc in memberProjects.docs) allProjectDocs[doc.id] = doc;

    for (var doc in allProjectDocs.values) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

      Project cloudProject = Project(
        project_id: data['project_id'],
        user_id: data['user_id'],
        name: data['name'],
        description: data['description'] ?? "",
        colorValue: data['colorValue'] ?? 0xFF1CB0F6,
        createdAt: DateTime.parse(data['createdAt']),
        updatedAt: DateTime.parse(data['updatedAt']),
        memberIds: List<String>.from(data['memberIds'] ?? []),
        memberStatuses: Map<String, String>.from(data['memberStatuses'] ?? {}),
      );

      await projectBox.put(cloudProject.project_id, cloudProject);
    }
  }

  // --- Sync cho các thực thể khác ---

  Future<void> syncNotifications() async {
    final user = _auth.currentUser;
    if (user == null) return;

    var box = Hive.box<model.Notification>('notificationsBox');

    // Đẩy thông báo local lên (thường là trạng thái isRead)
    for (var n in box.values.where((n) => n.user_id == user.uid)) {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .doc(n.notification_id)
          .set({
        'notification_id': n.notification_id,
        'user_id': n.user_id,
        'task_id': n.task_id,
        'title': n.title,
        'message': n.message,
        'type': n.type,
        'scheduled_at': n.scheduled_at.toIso8601String(),
        'isRead': n.isRead,
        'created_at': n.created_at.toIso8601String(),
        'updated_at': n.updated_at.toIso8601String(),
      });
    }

    // Tải thông báo mới từ Cloud
    var snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .get();
    for (var doc in snapshot.docs) {
      var data = doc.data();
      var notification = model.Notification(
        notification_id: data['notification_id'],
        user_id: data['user_id'],
        task_id: data['task_id'],
        title: data['title'],
        message: data['message'],
        type: data['type'],
        scheduled_at: DateTime.parse(data['scheduled_at']),
        isRead: data['isRead'],
        created_at: DateTime.parse(data['created_at']),
        updated_at: DateTime.parse(data['updated_at']),
      );
      await box.put(notification.notification_id, notification);
    }
  }

  Future<void> syncAvailability() async {
    final user = _auth.currentUser;
    if (user == null) return;

    var box = Hive.box<UserAvailability>('availabilityBox');

    // Đẩy
    for (var a in box.values.where((a) => a.user_id == user.uid)) {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('availability')
          .doc(a.availability_id)
          .set({
        'availability_id': a.availability_id,
        'user_id': a.user_id,
        'date': a.date.toIso8601String(),
        'start_time': a.start_time,
        'end_time': a.end_time,
        'duration_minute': a.duration_minute,
        'isRecurring': a.isRecurring,
        'day_of_week': a.day_of_week,
        'created_at': a.created_at.toIso8601String(),
      });
    }

    // Tải
    var snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('availability')
        .get();
    for (var doc in snapshot.docs) {
      var data = doc.data();
      var availability = UserAvailability(
        availability_id: data['availability_id'],
        user_id: data['user_id'],
        date: DateTime.parse(data['date']),
        start_time: data['start_time'],
        end_time: data['end_time'],
        duration_minute: data['duration_minute'],
        isRecurring: data['isRecurring'],
        day_of_week: data['day_of_week'],
        created_at: DateTime.parse(data['created_at']),
      );
      await box.put(availability.availability_id, availability);
    }
  }

  Future<void> syncSchedules() async {
    final user = _auth.currentUser;
    if (user == null) return;

    var box = Hive.box<TaskSchedule>('taskSchedulesBox');

    // Đẩy
    for (var s in box.values) {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('task_schedules')
          .doc(s.schedule_id)
          .set({
        'schedule_id': s.schedule_id,
        'task_id': s.task_id,
        'availability_id': s.availability_id,
        'start_time': s.start_time.toIso8601String(),
        'end_time': s.end_time.toIso8601String(),
        'duration_minutes': s.duration_minutes,
        'status': s.status,
        'score_heuristic': s.score_heuristic,
        'is_auto_split': s.is_auto_split,
        'created_at': s.created_at.toIso8601String(),
        'updated_at': s.updated_at.toIso8601String(),
      });
    }

    // Tải
    var snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('task_schedules')
        .get();
    for (var doc in snapshot.docs) {
      var data = doc.data();
      var schedule = TaskSchedule(
        schedule_id: data['schedule_id'],
        task_id: data['task_id'],
        availability_id: data['availability_id'],
        start_time: DateTime.parse(data['start_time']),
        end_time: DateTime.parse(data['end_time']),
        duration_minutes: data['duration_minutes'],
        status: data['status'],
        score_heuristic: data['score_heuristic'],
        is_auto_split: data['is_auto_split'],
        created_at: DateTime.parse(data['created_at']),
        updated_at: DateTime.parse(data['updated_at']),
      );
      await box.put(schedule.schedule_id, schedule);
    }
  }
}
