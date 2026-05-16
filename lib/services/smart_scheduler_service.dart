import 'dart:math';
import '../models/task_model.dart';
import '../models/user_availability_model.dart';
import '../models/task_schedule_model.dart';
import 'package:uuid/uuid.dart';

class SmartSchedulerService {
  // Trọng số cho Heuristic: Ưu tiên (40%) và Deadline (60%)
  static const int priorityWeight = 40;
  static const int deadlineWeight = 60;

  // 1. Tính điểm Heuristic Nâng cao (theo giờ)
  // Công thức: Score = (Độ ưu tiên * Weight) + (Điểm Deadline dựa trên thời gian còn lại)
  static int calculateHeuristicScore(Task task) {
    DateTime now = DateTime.now();

    // Tính khoảng cách thời gian đến deadline theo giờ
    Duration diff = task.deadline.difference(now);
    int hoursRemaining = diff.inHours;

    // Nếu đã quá hạn, cho điểm cực cao để ưu tiên xử lý ngay
    if (hoursRemaining < 0) return 300;

    // Điểm dựa trên mức độ ưu tiên (1-3) -> 40, 80, 120 điểm
    int pScore = task.priority * priorityWeight;

    // Điểm Deadline (Càng gần hạn điểm càng cao)
    int dScore = 0;
    if (hoursRemaining <= 24) {
      // Trong vòng 24h: từ 60 đến 100 điểm
      dScore = 100 - (hoursRemaining * 2);
    } else if (hoursRemaining <= 72) {
      // Trong vòng 3 ngày: từ 30 đến 60 điểm
      dScore = 60 - ((hoursRemaining - 24) ~/ 2);
    } else {
      // Trên 3 ngày: điểm thấp dần về 0
      dScore = max(0, 30 - (hoursRemaining ~/ 24));
    }

    return pScore + dScore;
  }

  // 2. Thuật toán gợi ý Advanced: Tự động chia nhỏ công việc và gợi ý dời sang ngày mai
  static Map<String, List<TaskSchedule>> suggestAdvancedSchedule({
    required List<Task> pendingTasks,
    required UserAvailability todayAvailability,
  }) {
    List<TaskSchedule> todaySchedules = [];
    List<TaskSchedule> tomorrowSuggestions = [];

    // Copy và sắp xếp theo điểm Heuristic giảm dần (Thuật toán Tham lam)
    List<Task> sortedTasks = List.from(pendingTasks);
    sortedTasks.sort((a, b) =>
        calculateHeuristicScore(b).compareTo(calculateHeuristicScore(a)));

    int remainingMinutes = todayAvailability.duration_minute;
    DateTime currentTime = todayAvailability.date;

    for (var task in sortedTasks) {
      // Tính thời gian thực tế cần làm (Dựa trên tổng thời gian và tiến độ hiện tại)
      int totalTaskMinutes = task.duration > 0 ? task.duration : 60;
      int taskRemainingMinutes =
          totalTaskMinutes - (totalTaskMinutes * task.progress ~/ 100);

      if (taskRemainingMinutes <= 0) continue;

      if (remainingMinutes <= 0) {
        // HẾT GIỜ HÔM NAY -> Tự động đưa vào danh sách dời sang ngày mai
        tomorrowSuggestions.add(_createScheduleObject(
            task, todayAvailability.availability_id, null,
            duration: taskRemainingMinutes, status: 'carry_over'));
        continue;
      }

      if (taskRemainingMinutes <= remainingMinutes) {
        // ĐỦ THỜI GIAN -> Xếp vào lịch hôm nay
        todaySchedules.add(_createScheduleObject(
            task, todayAvailability.availability_id, currentTime,
            duration: taskRemainingMinutes));
        remainingMinutes -= taskRemainingMinutes;
        currentTime = currentTime.add(Duration(minutes: taskRemainingMinutes));
      } else {
        // THIẾU THỜI GIAN -> CHIA NHỎ TỰ ĐỘNG (AUTO-SPLIT)
        // Phần 1: Làm nốt thời gian rảnh còn lại của hôm nay
        todaySchedules.add(_createScheduleObject(
            task, todayAvailability.availability_id, currentTime,
            duration: remainingMinutes, isSplit: true));

        // Phần 2: Dời phần còn thiếu sang ngày mai
        tomorrowSuggestions.add(_createScheduleObject(
            task, todayAvailability.availability_id, null,
            duration: taskRemainingMinutes - remainingMinutes,
            isSplit: true,
            status: 'carry_over'));

        remainingMinutes = 0;
      }
    }

    return {'today': todaySchedules, 'tomorrow': tomorrowSuggestions};
  }

  static TaskSchedule _createScheduleObject(
      Task task, String availId, DateTime? start,
      {int? duration, bool isSplit = false, String status = 'suggested'}) {
    // Nếu không có mốc bắt đầu (cho việc ngày mai), mặc định là 8h sáng mai
    DateTime tomorrowBase = DateTime.now().add(const Duration(days: 1));
    DateTime startTime = start ??
        DateTime(tomorrowBase.year, tomorrowBase.month, tomorrowBase.day, 8, 0);
    int dur = duration ?? 60;

    return TaskSchedule(
      schedule_id: const Uuid().v4(),
      task_id: task.task_id,
      availability_id: availId,
      start_time: startTime,
      end_time: startTime.add(Duration(minutes: dur)),
      duration_minutes: dur,
      status: status,
      score_heuristic: calculateHeuristicScore(task),
      is_auto_split: isSplit,
      created_at: DateTime.now(),
      updated_at: DateTime.now(),
    );
  }
}
