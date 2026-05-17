import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/task_model.dart';
import 'notification_service.dart';

class ProgressTrackingService {
  static Timer? _scanTimer;
  static bool _isScanning = false;

  /// Khởi chạy bộ quét kiểm tra thời gian thực.
  static void start(BuildContext context, Function() onStateChanged) {
    if (_scanTimer != null) return;
    
    // Quét lần đầu tiên ngay khi gọi start
    scanTasks(onStateChanged);
    
    _scanTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      await scanTasks(onStateChanged);
    });
  }

  /// Dừng bộ quét.
  static void stop() {
    _scanTimer?.cancel();
    _scanTimer = null;
  }

  /// Kiểm tra xem hiện tại có đang nằm trong khung giờ ngủ để đóng băng hệ thống không.
  static bool isInsideSleepWindow() {
    if (!Hive.isBoxOpen('settingsBox')) return false;
    final settingsBox = Hive.box('settingsBox');
    final isEnabled = settingsBox.get('isSleepModeEnabled', defaultValue: true);
    if (!isEnabled) return false;

    final startH = settingsBox.get('sleepStartHour', defaultValue: 22);
    final startM = settingsBox.get('sleepStartMinute', defaultValue: 0);
    final endH = settingsBox.get('sleepEndHour', defaultValue: 6);
    final endM = settingsBox.get('sleepEndMinute', defaultValue: 0);

    final now = DateTime.now();
    final currentMin = now.hour * 60 + now.minute;
    final startMin = startH * 60 + startM;
    final endMin = endH * 60 + endM;

    if (startMin < endMin) {
      // Khung giờ ngủ trong cùng một ngày, ví dụ: 13:00 đến 15:00
      return currentMin >= startMin && currentMin < endMin;
    } else {
      // Khung giờ ngủ overnight, ví dụ: 22:00 tối hôm trước đến 06:00 sáng hôm sau
      return currentMin >= startMin || currentMin < endMin;
    }
  }

  /// Thực hiện quét danh sách công việc và cập nhật trạng thái tự động.
  static Future<void> scanTasks(Function() onStateChanged) async {
    if (_isScanning) return;
    _isScanning = true;

    try {
      final now = DateTime.now();

      // Kiểm tra xem có đang ở trong chế độ đóng băng giấc ngủ (Sleep Mode Freeze) không
      if (isInsideSleepWindow()) {
        final settingsBox = Hive.box('settingsBox');
        int silenced = settingsBox.get('silencedAlarmsCount', defaultValue: 0);
        bool hasChanges = false;

        if (Hive.isBoxOpen('tasksBox')) {
          final taskBox = Hive.box<Task>('tasksBox');
          final activeTasks = taskBox.values
              .where((t) => !t.isDeleted && t.status != 'completed')
              .toList();

          for (var task in activeTasks) {
            // Nếu có nhiệm vụ sắp bắt đầu hoặc trễ hạn trùng khớp phút hiện tại, ta tắt thông báo nhắc nhở và đếm làm "silenced alarm"
            if (task.due_day.hour == now.hour && task.due_day.minute == now.minute) {
              final idBase = task.task_id.hashCode.abs();
              await NotificationService.cancelNotification(idBase + 5000);
              silenced++;
              hasChanges = true;
            }
          }
        }

        if (hasChanges) {
          await settingsBox.put('silencedAlarmsCount', silenced);
          onStateChanged();
        }
        
        _isScanning = false;
        return; // ĐÓNG BĂNG TOÀN BỘ LOGIC QUÉT TRỄ HẠN VÀ KHÔNG CHUYỂN TRẠNG THÁI!
      }

      if (Hive.isBoxOpen('tasksBox')) {
        final taskBox = Hive.box<Task>('tasksBox');
        final tasks = taskBox.values.where((t) => !t.isDeleted).toList();

        bool hasChanges = false;
        for (var task in tasks) {
          // 1. Tự động chuyển pending sang in_progress khi tới giờ
          if (task.status == 'pending') {
            if (now.isAfter(task.due_day) && now.isBefore(task.deadline)) {
              task.status = 'in_progress';
              task.updatedAt = now;
              task.isSynced = false;
              await task.save();
              hasChanges = true;

              // Phát thông báo đẩy tức thì báo hiệu công việc bắt đầu
              await NotificationService.showNotification(
                id: task.task_id.hashCode.abs() + 5000,
                title: '🚀 Công việc đã bắt đầu!',
                body: 'Nhiệm vụ "${task.title}" của bạn đã được tự động chuyển sang "Đang thực hiện".',
              );
            }
          }
        }

        if (hasChanges) {
          onStateChanged();
        }
      }
    } catch (e) {
      debugPrint("Lỗi quét tiến trình: $e");
    } finally {
      _isScanning = false;
    }
  }
}
