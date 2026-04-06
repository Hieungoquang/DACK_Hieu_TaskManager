import 'dart:math';

import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../models/time_logs_model.dart';
import '../services/local_service.dart';

class TaskProvider extends ChangeNotifier {
  List<Task> tasks = [];

  //load task
  void loadTasks() {
    tasks = LocalService.getTasks();
    notifyListeners();
  }

  //them task
  Future<void> addTask(Task task) async {
    await LocalService.addTask(task);
    loadTasks();
  }

  //xoa tast
  Future<void> deleteTask(String id) async {
    await LocalService.deleteTask(id);
    loadTasks();
  }

  //cap nhat task
  Future<void> updateTask(Task task) async {
    await LocalService.updateTask(task);
    loadTasks();
  }

  //Cap nhat tien do
  Future<void> updateProgress(Task task, int value) async{
    task.progress = value;
    await task.save();
    loadTasks();
  }

  Future<void> addLog(String taskId) async{
    DateTime now = DateTime.now();
    Time_logs log = Time_logs(
      log_id: Random().nextInt(999999).toString(),
      task_id: taskId,
      start_time: now,
      end_time: now.add(const Duration(hours:1)),
      duration_minutes: 60,
      notes: "",
      created_at: now,
      updated_at: now,
    );
    await LocalService.addLog(log);
    notifyListeners();
  }

  int getWorkedTime(String taskId){
    List<Time_logs> logs = LocalService.getLogsByTask(taskId);
    int total = 0;

    for (var log in logs){
      total += log.end_time.difference(log.start_time).inHours;
    }
    return total;
  }
}