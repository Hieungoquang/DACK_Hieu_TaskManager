import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../provider/task_provider.dart';
import '../provider/app_provider.dart';
import '../models/time_logs_model.dart';
import '../models/task_model.dart';
import '../widgets/web_sidebar.dart';
import '../widgets/mobile_bottom_nav.dart';

class AnalyticsDashboardScreen extends StatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  State<AnalyticsDashboardScreen> createState() => _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  static const Color ghDarkBg = Color(0xFF0D1117);
  static const Color ghDarkCard = Color(0xFF161B22);
  static const Color ghDarkBorder = Color(0xFF30363D);
  static const Color ghDarkText = Color(0xFFC9D1D9);
  static const Color ghDarkSubText = Color(0xFF8B949E);

  static const Color ghLightBg = Color(0xFFF6F8FA);
  static const Color ghLightCard = Color(0xFFFFFFFF);
  static const Color ghLightBorder = Color(0xFFD0D7DE);
  static const Color ghLightText = Color(0xFF24292F);
  static const Color ghLightSubText = Color(0xFF57606A);

  static const Color ghBlue = Color(0xFF58A6FF);
  static const Color ghGreen = Color(0xFF3FB950);
  static const Color ghOrange = Color(0xFFD29922);
  static const Color ghPurple = Color(0xFFA371F7);

  Color _bg(bool d) => d ? ghDarkBg : ghLightBg;
  Color _card(bool d) => d ? ghDarkCard : ghLightCard;
  Color _border(bool d) => d ? ghDarkBorder : ghLightBorder;
  Color _txt(bool d) => d ? ghDarkText : ghLightText;
  Color _sub(bool d) => d ? ghDarkSubText : ghLightSubText;

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final isDark = appProvider.themeMode == ThemeMode.dark;
    final provider = context.watch<TaskProvider>();
    final isWeb = MediaQuery.of(context).size.width > 900;

    // 1. Fetch data
    final tasks = provider.tasks.where((t) => !t.isDeleted).toList();
    final completedTasks = tasks.where((t) => t.status == 'completed').toList();
    
    // Nạp logs từ Hive Box trực tiếp và lọc sạch các log lỗi hoặc null
    final logsBox = Hive.box<Time_logs>('timeLogsBox');
    final timeLogs = logsBox.values.where((l) => l != null).toList()
      ..sort((a, b) {
        final aTime = a.created_at ?? DateTime.now();
        final bTime = b.created_at ?? DateTime.now();
        return bTime.compareTo(aTime);
      });

    // 2. Tính toán các chỉ số cơ bản cực kỳ an toàn
    int totalFocusMinutes = 0;
    for (var l in timeLogs) {
      final dynamic mins = l.duration_minutes;
      if (mins != null) {
        totalFocusMinutes += mins as int;
      }
    }
    double totalFocusHours = totalFocusMinutes / 60.0;

    double completionRate = tasks.isEmpty ? 0.0 : completedTasks.length / tasks.length;

    // 3. Phân bổ thời gian thực tế theo Category (Pie Chart) an toàn
    final categoryMinutes = <String, int>{};
    for (var log in timeLogs) {
      String cat = "Khác";
      try {
        final t = tasks.firstWhere((task) => task.task_id == log.task_id);
        if (t.category.isNotEmpty) cat = t.category;
      } catch (_) {}
      
      final dynamic mins = log.duration_minutes;
      final int m = (mins is int) ? mins : 0;
      categoryMinutes[cat] = (categoryMinutes[cat] ?? 0) + m;
    }

    // 4. Hiệu suất hoàn thành 7 ngày qua (Bar Chart) an toàn
    final dailyCompletedCounts = <String, int>{};
    final dateFormat = DateFormat('dd/MM');
    final today = DateTime.now();
    
    // Khởi tạo 7 ngày gần đây
    final last7Days = List.generate(7, (i) {
      return today.subtract(Duration(days: 6 - i));
    });

    for (var date in last7Days) {
      final key = dateFormat.format(date);
      dailyCompletedCounts[key] = 0;
    }

    for (var task in completedTasks) {
      final date = task.updatedAt ?? task.createdAt ?? DateTime.now();
      final key = dateFormat.format(date);
      if (dailyCompletedCounts.containsKey(key)) {
        dailyCompletedCounts[key] = (dailyCompletedCounts[key] ?? 0) + 1;
      }
    }

    return Scaffold(
      backgroundColor: _bg(isDark),
      bottomNavigationBar: isWeb ? null : const MobileBottomNav(currentRoute: 'analytics'),
      body: Row(
        children: [
          if (isWeb) const WebSidebar(currentRoute: 'analytics'),
          Expanded(
            child: SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: isWeb ? 40 : 16, vertical: 20),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1000),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(isDark, isWeb),
                        const SizedBox(height: 24),
                        _buildStatsSummaryGrid(isDark, totalFocusHours, completionRate, appProvider.silencedAlarmsCount),
                        const SizedBox(height: 24),
                        if (isWeb)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 5,
                                child: _buildTimeAllocationCard(isDark, categoryMinutes),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                flex: 5,
                                child: _buildProductivityTrendCard(isDark, dailyCompletedCounts),
                              ),
                            ],
                          )
                        else ...[
                          _buildTimeAllocationCard(isDark, categoryMinutes),
                          const SizedBox(height: 20),
                          _buildProductivityTrendCard(isDark, dailyCompletedCounts),
                        ],
                        const SizedBox(height: 24),
                        _buildSleepModeSafetyCard(isDark, appProvider),
                        const SizedBox(height: 24),
                        _buildTimeLogsList(isDark, timeLogs, tasks),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark, bool isWeb) {
    return Row(
      children: [
        if (!isWeb)
          IconButton(
            icon: Icon(Icons.arrow_back, color: _txt(isDark)),
            onPressed: () => Navigator.pop(context),
          ),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: ghPurple.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.analytics_outlined, color: ghPurple, size: 28),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "THỐNG KÊ HIỆU SUẤT",
                style: GoogleFonts.nunito(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: _txt(isDark),
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                "Phân tích sâu xu hướng phân bổ thời gian và năng suất hoạt động",
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  color: _sub(isDark),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSummaryGrid(bool isDark, double focusHours, double rate, int silencedAlarms) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final int crossCount = screenWidth > 600 ? 3 : 1;

    return GridView.count(
      crossAxisCount: crossCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: screenWidth > 600 ? 2.2 : 3.0,
      children: [
        _buildSummaryCard(
          "TẬP TRUNG TÍCH LŨY",
          "${focusHours.toStringAsFixed(1)} giờ",
          Icons.av_timer_rounded,
          ghBlue,
          isDark,
          "Tổng thời gian hoạt động thực tế",
        ),
        _buildSummaryCard(
          "TỶ LỆ HOÀN THÀNH",
          "${(rate * 100).toInt()}%",
          Icons.task_alt_rounded,
          ghGreen,
          isDark,
          "Tỷ lệ nhiệm vụ đạt 100% tiến độ",
        ),
        _buildSummaryCard(
          "BẢO VỆ GIẤC NGỦ 💤",
          "$silencedAlarms lần",
          Icons.nights_stay_rounded,
          ghOrange,
          isDark,
          "Cảnh báo tự động đóng băng giờ ngủ",
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color, bool isDark, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card(isDark),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border(isDark)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: GoogleFonts.nunito(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: _sub(isDark),
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.nunito(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: _txt(isDark),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.nunito(
                    fontSize: 11,
                    color: _sub(isDark).withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeAllocationCard(bool isDark, Map<String, int> data) {
    final list = data.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final colors = [ghBlue, ghGreen, ghOrange, ghPurple, Colors.redAccent, Colors.teal];

    final double totalMin = list.fold<int>(0, (sum, e) => sum + e.value).toDouble();

    return Container(
      padding: const EdgeInsets.all(20),
      height: 380,
      decoration: BoxDecoration(
        color: _card(isDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border(isDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "XU HƯỚNG PHÂN BỔ THỜI GIAN",
            style: GoogleFonts.nunito(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: _sub(isDark),
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 24),
          if (totalMin == 0)
            Expanded(
              child: Center(
                child: Text(
                  "Chưa có dữ liệu phân bổ. Hãy hoàn thành công việc để vẽ biểu đồ!",
                  style: GoogleFonts.nunito(color: _sub(isDark), fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            Expanded(
              child: Row(
                children: [
                  SizedBox(
                    width: 140,
                    height: 140,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 4,
                        centerSpaceRadius: 40,
                        sections: List.generate(list.length, (index) {
                          final e = list[index];
                          final color = colors[index % colors.length];
                          return PieChartSectionData(
                            color: color,
                            value: e.value.toDouble(),
                            radius: 18,
                            title: '',
                          );
                        }),
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: ListView.builder(
                      itemCount: list.length,
                      itemBuilder: (context, index) {
                        final e = list[index];
                        final color = colors[index % colors.length];
                        final double percent = (e.value / totalMin) * 100;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6.0),
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  e.key,
                                  style: GoogleFonts.nunito(
                                    color: _txt(isDark),
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                "${percent.toInt()}%",
                                style: GoogleFonts.nunito(
                                  color: color,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProductivityTrendCard(bool isDark, Map<String, int> data) {
    final list = data.entries.toList();

    int maxCount = 0;
    for (var e in list) {
      if (e.value > maxCount) maxCount = e.value;
    }
    double maxVal = maxCount == 0 ? 5 : (maxCount + 2).toDouble();

    return Container(
      padding: const EdgeInsets.all(20),
      height: 380,
      decoration: BoxDecoration(
        color: _card(isDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border(isDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "NĂNG SUẤT 7 NGÀY QUA",
            style: GoogleFonts.nunito(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: _sub(isDark),
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: BarChart(
              BarChartData(
                maxY: maxVal,
                barGroups: List.generate(list.length, (index) {
                  final e = list[index];
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: e.value.toDouble(),
                        color: ghPurple,
                        width: 14,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: maxVal,
                          color: isDark ? const Color(0xFF0D1117) : const Color(0xFFF6F8FA),
                        ),
                      ),
                    ],
                  );
                }),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, meta) {
                        final idx = val.toInt();
                        if (idx >= 0 && idx < list.length) {
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            space: 8,
                            child: Text(
                              list[idx].key,
                              style: GoogleFonts.nunito(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: _sub(isDark),
                              ),
                            ),
                          );
                        }
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: const SizedBox(),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSleepModeSafetyCard(bool isDark, AppProvider app) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _card(isDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border(isDark)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ghOrange.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.nights_stay_rounded, color: ghOrange, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "BẢO VỆ SỨC KHỎE VÀ GIẤC NGỦ",
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: ghOrange,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  app.isSleepModeEnabled
                      ? "Chế độ đóng băng giờ ngủ (Sleep Mode Freeze) đang hoạt động từ ${app.sleepStartHour.toString().padLeft(2, '0')}:00 đến ${app.sleepEndHour.toString().padLeft(2, '0')}:00."
                      : "Chế độ đóng băng giờ ngủ chưa được kích hoạt.",
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    color: _txt(isDark),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  app.isSleepModeEnabled
                      ? "Trong khung giờ này, tất cả các tác vụ trễ hạn đều được bỏ qua quét phạt lỗi và có tổng cộng ${app.silencedAlarmsCount} thông báo nhắc nhở đã được tự động đóng băng thành công để giữ cho giấc ngủ của bạn hoàn toàn yên tĩnh."
                      : "Hãy bật Sleep Mode Freeze trong phần cài đặt để hệ thống tự động tắt tiếng báo chuông nhắc nhở và ngăn ngừa các lỗi trễ hạn phát sinh trong đêm.",
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    color: _sub(isDark),
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeLogsList(bool isDark, List<Time_logs> logs, List<Task> tasks) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _card(isDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border(isDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "NHẬT KÝ THỜI GIAN THỰC HIỆN (TIME LOGS)",
            style: GoogleFonts.nunito(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: _sub(isDark),
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 16),
          if (logs.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 30.0),
              child: Center(
                child: Text(
                  "Chưa ghi nhận bất kỳ lịch sử thực hiện nào.",
                  style: GoogleFonts.nunito(color: _sub(isDark), fontSize: 13),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: logs.length > 5 ? 5 : logs.length,
              separatorBuilder: (_, __) => Divider(color: _border(isDark), height: 1),
              itemBuilder: (context, index) {
                final log = logs[index];
                
                // Lấy thông tin task
                String taskTitle = "Công việc không xác định";
                String categoryName = "Cá nhân";
                try {
                  final t = tasks.firstWhere((task) => task.task_id == log.task_id);
                  taskTitle = t.title;
                  if (t.category.isNotEmpty) categoryName = t.category;
                } catch (_) {}

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 6.0),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: ghPurple.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.timer_outlined, color: ghPurple, size: 20),
                  ),
                  title: Text(
                    taskTitle,
                    style: GoogleFonts.nunito(
                      color: _txt(isDark),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 2),
                      Text(
                        "Ghi chú: ${log.notes}",
                        style: GoogleFonts.nunito(color: _sub(isDark), fontSize: 12),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "${DateFormat('dd/MM/yyyy HH:mm').format(log.created_at)} • Nhóm: $categoryName",
                        style: GoogleFonts.nunito(color: _sub(isDark).withOpacity(0.7), fontSize: 11),
                      ),
                    ],
                  ),
                  trailing: Text(
                    "${log.duration_minutes} phút",
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      color: ghBlue,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
