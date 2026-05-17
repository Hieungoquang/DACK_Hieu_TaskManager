import '../models/task_model.dart';
import '../models/time_logs_model.dart';

class PredictionService {
  /// Tính toán tỷ lệ thường xuyên trễ hạn của người dùng (Delay Rate).
  /// Dựa trên danh sách các task đã hoàn thành.
  /// Trả về hệ số từ 0.0 (không bao giờ trễ) đến 1.0 (luôn luôn trễ).
  static double calculateDelayRate(List<Task> allTasks) {
    final completedTasks = allTasks.where((t) => t.status == 'completed').toList();
    if (completedTasks.isEmpty) return 0.0; // Chưa có data để đánh giá, mặc định là tốt

    int overdueCount = 0;
    for (var task in completedTasks) {
      // Giả định updatedAt là thời điểm hoàn thành task
      if (task.updatedAt.isAfter(task.deadline)) {
        overdueCount++;
      }
    }

    return overdueCount / completedTasks.length;
  }

  /// Tính toán xác suất công việc hiện tại sẽ bị trễ hạn (Crisis Probability).
  /// Dựa trên thời gian đã trôi qua, tiến độ hiện tại và hành vi của người dùng.
  /// Trả về giá trị từ 0.0 (an toàn) đến 1.0 (nguy cơ cao/khủng hoảng).
  static double calculateCrisisProbability(
    Task task,
    double userDelayRate, {
    DateTime? projectStartDate,
    DateTime? projectEndDate,
  }) {
    if (task.status == 'completed' || task.isDeleted) return 0.0;

    final now = DateTime.now();

    // Ràng buộc thời gian dự án
    if (projectEndDate != null) {
      // 1. Nếu task chưa hoàn thành nhưng deadline vượt quá ngày kết thúc của dự án -> 100% Khủng hoảng
      if (task.deadline.isAfter(projectEndDate)) {
        return 1.0;
      }

      // 2. Nếu thời gian hiện tại đã quá hạn kết thúc dự án -> 100% Khủng hoảng
      if (now.isAfter(projectEndDate)) {
        return 1.0;
      }
    }

    // Nếu đã quá hạn task nhưng chưa hoàn thành -> 100% Khủng hoảng
    if (now.isAfter(task.deadline)) {
      return 1.0;
    }

    final totalDuration = task.deadline.difference(task.due_day).inMinutes;
    if (totalDuration <= 0) return 0.0; // Tránh lỗi chia cho 0

    final elapsed = now.difference(task.due_day).inMinutes;
    
    // Tỷ lệ thời gian đã trôi qua (0.0 -> 1.0)
    double elapsedRatio = elapsed / totalDuration;
    if (elapsedRatio < 0.0) elapsedRatio = 0.0; // Chưa đến ngày bắt đầu
    if (elapsedRatio > 1.0) elapsedRatio = 1.0;

    // Tỷ lệ hoàn thành công việc (0.0 -> 1.0)
    double progressRatio = task.progress / 100.0;

    // Tính độ rủi ro cơ bản: Thời gian trôi đi nhiều hơn tiến độ đạt được
    double baseRisk = elapsedRatio - progressRatio;

    if (baseRisk <= 0) return 0.0; // Tiến độ nhanh hơn hoặc bằng thời gian trôi qua -> an toàn

    // Khuếch đại rủi ro dựa trên "tật xấu" trễ hạn trong quá khứ của người dùng
    double amplifiedRisk = baseRisk * (1.0 + (userDelayRate * 1.5)); 

    // 3. Nếu dự án sắp hết hạn (đã trôi qua hơn 80% thời gian), tăng độ khẩn cấp
    if (projectEndDate != null) {
      final pStart = projectStartDate ?? task.due_day;
      final projectDuration = projectEndDate.difference(pStart).inMinutes;
      if (projectDuration > 0) {
        final projectElapsed = now.difference(pStart).inMinutes;
        final projectElapsedRatio = (projectElapsed / projectDuration).clamp(0.0, 1.0);
        if (projectElapsedRatio > 0.8) {
          amplifiedRisk *= 1.3;
        }
      }
    }

    return amplifiedRisk.clamp(0.0, 1.0);
  }

  /// Tính toán khung giờ vàng tập trung cá nhân.
  /// Kết hợp dữ liệu từ Time Logs (thời gian Timer) và các task đã hoàn thành.
  /// Trả về danh sách chứa tối đa 2 giờ vàng (0-23).
  static List<int> calculateGoldenHours(List<Time_logs> logs, List<Task> completedTasks) {
    if (logs.isEmpty && completedTasks.isEmpty) {
      // Mặc định gợi ý khung giờ sáng (9h) và chiều (15h)
      return [9, 15];
    }

    final hourlyScores = List<double>.filled(24, 0.0);

    // 1. Phân tích Time Logs (Timer tập trung)
    for (var log in logs) {
      final hour = log.start_time.hour;
      // Cộng số phút tập trung vào khung giờ tương ứng
      hourlyScores[hour] += log.duration_minutes.toDouble();
    }

    // 2. Phân tích thời điểm hoàn thành task
    for (var task in completedTasks) {
      final hour = task.updatedAt.hour;
      // Cộng điểm thưởng hoàn thành công việc theo mức độ ưu tiên
      double reward = 20.0; // Thấp
      if (task.priority == 3) {
        reward = 60.0; // Cao (Công việc khó hoàn thành ở giờ nào chứng tỏ giờ đó rất tập trung)
      } else if (task.priority == 2) {
        reward = 40.0; // Vừa
      }
      hourlyScores[hour] += reward;
    }

    // 3. Sắp xếp tìm ra các giờ hoạt động tốt nhất
    List<int> sortedHours = List.generate(24, (i) => i);
    sortedHours.sort((a, b) => hourlyScores[b].compareTo(hourlyScores[a]));

    List<int> results = [];
    for (int hour in sortedHours) {
      if (hourlyScores[hour] > 0) {
        results.add(hour);
      }
      if (results.length == 2) break;
    }

    // Trả về kết quả hoặc fallback nếu không có dữ liệu hoạt động
    if (results.isEmpty) {
      return [9, 15];
    }
    if (results.length == 1) {
      results.add((results[0] + 4) % 24); // Fallback giờ thứ 2 cách giờ thứ nhất 4 tiếng
    }

    return results;
  }

  /// Thống kê và phân tích xu hướng trì hoãn, trả về kết quả giúp người dùng "đối diện với sự thật".
  static ProcrastinationAnalysis analyzeProcrastination(List<Task> allActiveTasks) {
    final now = DateTime.now();
    final activeTasks = allActiveTasks.where((t) => !t.isDeleted).toList();
    if (activeTasks.isEmpty) {
      return ProcrastinationAnalysis(
        lazinessQuotient: 0.0,
        worstCategory: "Không có",
        worstCategoryOverdueRate: 0.0,
        totalOverdue: 0,
        totalPending: 0,
        roastMessage: "Tuyệt vời! Bạn chưa có công việc nào để lười cả. Hãy tạo thêm việc đi nhé!",
        categoryDelayRates: {},
        categoryOverdueCounts: {},
      );
    }

    final pendingTasks = activeTasks.where((t) => t.status != 'completed').toList();

    // 1. Thống kê theo từng danh mục
    final categoryTotals = <String, int>{};
    final categoryOverdues = <String, int>{};

    int totalOverdue = 0;

    for (var t in activeTasks) {
      final cat = t.category.isEmpty ? "Khác" : t.category;
      categoryTotals[cat] = (categoryTotals[cat] ?? 0) + 1;

      // Xác định trễ hạn
      bool isOverdue = false;
      if (t.status == 'completed') {
        if (t.updatedAt.isAfter(t.deadline)) {
          isOverdue = true;
        }
      } else {
        if (now.isAfter(t.deadline)) {
          isOverdue = true;
        }
      }

      if (isOverdue) {
        categoryOverdues[cat] = (categoryOverdues[cat] ?? 0) + 1;
        totalOverdue++;
      }
    }

    // 2. Tính tỷ lệ trễ hạn từng danh mục
    final categoryDelayRates = <String, double>{};
    String worstCategory = "Không có";
    double worstCategoryOverdueRate = 0.0;

    categoryTotals.forEach((cat, total) {
      final overdues = categoryOverdues[cat] ?? 0;
      final rate = overdues / total;
      categoryDelayRates[cat] = rate;

      if (rate > worstCategoryOverdueRate) {
        worstCategoryOverdueRate = rate;
        worstCategory = cat;
      } else if (rate == worstCategoryOverdueRate && worstCategoryOverdueRate > 0) {
        // Ưu tiên mảng có số lượng trễ hạn tuyệt đối cao hơn
        final currentWorstOverdues = categoryOverdues[worstCategory] ?? 0;
        if (overdues > currentWorstOverdues) {
          worstCategory = cat;
        }
      }
    });

    // Nếu không có việc trễ hạn nào, chọn mảng có nhiều việc đang chờ nhất
    if (worstCategory == "Không có" && pendingTasks.isNotEmpty) {
      final pendingCounts = <String, int>{};
      for (var t in pendingTasks) {
        final cat = t.category.isEmpty ? "Khác" : t.category;
        pendingCounts[cat] = (pendingCounts[cat] ?? 0) + 1;
      }
      String mostPendingCat = "Không có";
      int maxPending = 0;
      pendingCounts.forEach((cat, count) {
        if (count > maxPending) {
          maxPending = count;
          mostPendingCat = cat;
        }
      });
      worstCategory = mostPendingCat;
      worstCategoryOverdueRate = 0.0;
    }

    // 3. Công thức tính Chỉ số lười biếng (Laziness Quotient):
    // 70% dựa trên tỷ lệ trễ hạn thực tế + 30% dựa trên tỷ lệ tồn đọng
    double lazinessQuotient = 0.0;
    if (activeTasks.isNotEmpty) {
      lazinessQuotient = (0.7 * (totalOverdue / activeTasks.length)) + (0.3 * (pendingTasks.length / activeTasks.length));
    }
    lazinessQuotient = lazinessQuotient.clamp(0.0, 1.0);

    // 4. Sinh lời Roast châm biếm hài hước theo từng cấp độ
    String roastMessage = "";
    if (totalOverdue == 0 && pendingTasks.isEmpty) {
      roastMessage = "Bầu trời trong xanh không một gợn mây! Bạn đã hoàn thành xuất sắc tất cả công việc. Không có một chút lười biếng nào ở đây cả!";
    } else if (lazinessQuotient < 0.25) {
      roastMessage = "Rất đáng khen! Bạn đang kiểm soát công việc cực tốt. Chỉ có vài việc nhỏ tồn đọng, hãy duy trì phong độ đỉnh cao này nhé!";
    } else if (lazinessQuotient < 0.5) {
      roastMessage = "Cảnh báo nhẹ: Sự trì hoãn đang bắt đầu nhen nhóm. Bạn đang bỏ bê mảng '$worstCategory'. Đừng để những việc nhỏ tích tụ thành núi!";
    } else if (lazinessQuotient < 0.75) {
      roastMessage = "Hãy đối diện với thực tế đi! Bạn đang lười biếng rõ rệt ở mảng '$worstCategory' với ${(worstCategoryOverdueRate * 100).toInt()}% công việc bị trễ hạn. Bạn định trốn tránh đến bao giờ? Đứng dậy làm ngay thôi!";
    } else {
      roastMessage = "⚠️ BÁO ĐỘNG ĐỎ: Bạn đang chìm đắm trong sự trì hoãn! Chỉ số lười biếng đã lên tới ${(lazinessQuotient * 100).toInt()}%. Mảng '$worstCategory' đang hoàn toàn bị bỏ hoang. Đừng tìm lý do nữa, hãy 'đối diện với thực tế' và xử lý ngay công việc đầu tiên!";
    }

    return ProcrastinationAnalysis(
      lazinessQuotient: lazinessQuotient,
      worstCategory: worstCategory,
      worstCategoryOverdueRate: worstCategoryOverdueRate,
      totalOverdue: totalOverdue,
      totalPending: pendingTasks.length,
      roastMessage: roastMessage,
      categoryDelayRates: categoryDelayRates,
      categoryOverdueCounts: categoryOverdues,
    );
  }
}

class ProcrastinationAnalysis {
  final double lazinessQuotient; // 0.0 to 1.0 (Chỉ số lười biếng)
  final String worstCategory; // Nhóm công việc lười nhất
  final double worstCategoryOverdueRate; // Tỷ lệ trễ hạn của nhóm đó
  final int totalOverdue; // Tổng số việc trễ hạn
  final int totalPending; // Tổng số việc đang chờ/chưa làm
  final String roastMessage; // Phản hồi thực tế (Reality Check)
  final Map<String, double> categoryDelayRates; // Tỷ lệ trễ hạn từng nhóm
  final Map<String, int> categoryOverdueCounts; // Số lượng trễ hạn từng nhóm

  ProcrastinationAnalysis({
    required this.lazinessQuotient,
    required this.worstCategory,
    required this.worstCategoryOverdueRate,
    required this.totalOverdue,
    required this.totalPending,
    required this.roastMessage,
    required this.categoryDelayRates,
    required this.categoryOverdueCounts,
  });
}
