import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../provider/task_provider.dart';
import '../provider/app_provider.dart';
import '../models/task_model.dart';
import '../widgets/web_sidebar.dart';

class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  final Color duoGreen = const Color(0xFF58CC02);
  final Color duoBlue = const Color(0xFF1CB0F6);
  final Color duoOrange = const Color(0xFFFF9600);
  final Color duoPurple = const Color(0xFFCE82FF);
  final Color duoText = const Color(0xFF1F1F1F);
  final Color duoSecondaryText = const Color(0xFF4B4B4B);
  final Color duoGray = const Color(0xFFE5E5E5);
  final Color duoLightGray = const Color(0xFFF7F7F7);

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final isDark = appProvider.themeMode == ThemeMode.dark;
    double width = MediaQuery.of(context).size.width;
    bool isWeb = width > 900;

    final scaffoldBg = isDark ? const Color(0xFF121212) : Colors.white;
    final textColor = isDark ? Colors.white : duoText;
    final labelColor =
        isDark ? Colors.white.withOpacity(0.7) : duoSecondaryText;
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderColor = isDark ? const Color(0xFF37464F) : duoGray;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: isWeb
          ? null
          : AppBar(
              backgroundColor: scaffoldBg,
              elevation: 0,
              centerTitle: true,
              title: Text(
                "HIỆU SUẤT CÔNG VIỆC",
                style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    letterSpacing: 1.5),
              ),
              leading: IconButton(
                icon:
                    Icon(Icons.arrow_back_ios_new, color: labelColor, size: 22),
                onPressed: () => Navigator.pop(context),
              ),
            ),
      body: Row(
        children: [
          if (isWeb) const WebSidebar(currentRoute: 'report'),
          Expanded(
            child: Consumer<TaskProvider>(
              builder: (context, provider, child) {
                final tasks = provider.tasks;
                final total = tasks.length;
                final completed = tasks.where((t) => t.progress == 100).length;
                final inProgress = tasks
                    .where((t) => t.progress > 0 && t.progress < 100)
                    .length;
                final pending = tasks.where((t) => t.progress == 0).length;
                final double avgProgress = total == 0
                    ? 0
                    : tasks.fold(0.0, (sum, t) => sum + t.progress) / total;

                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          if (isWeb) ...[
                            Text("HIỆU SUẤT CÔNG VIỆC",
                                style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    color: textColor)),
                            const SizedBox(height: 30),
                          ],
                          _buildDuoCard(
                            isDark,
                            borderColor,
                            cardBg,
                            child: Column(
                              children: [
                                _buildSectionHeader(
                                    "KẾT QUẢ TỔNG QUAN", labelColor),
                                const SizedBox(height: 20),
                                Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: SizedBox(
                                        height: 180,
                                        child: total == 0
                                            ? _buildEmptyState(labelColor)
                                            : PieChart(
                                                PieChartData(
                                                  sectionsSpace: 4,
                                                  centerSpaceRadius: 40,
                                                  sections: [
                                                    _buildPieSection(
                                                        completed.toDouble(),
                                                        duoGreen,
                                                        "Xong"),
                                                    _buildPieSection(
                                                        inProgress.toDouble(),
                                                        duoOrange,
                                                        "Làm"),
                                                    _buildPieSection(
                                                        pending.toDouble(),
                                                        duoBlue,
                                                        "Chờ"),
                                                  ],
                                                ),
                                              ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          _buildLegendItem(duoGreen,
                                              "Hoàn thành", labelColor),
                                          _buildLegendItem(duoOrange,
                                              "Đang làm", labelColor),
                                          _buildLegendItem(
                                              duoBlue, "Chưa làm", labelColor),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 40),
                                Text("${avgProgress.toInt()}%",
                                    style: TextStyle(
                                        fontSize: 48,
                                        fontWeight: FontWeight.w900,
                                        color: duoGreen)),
                                Text("TIẾN ĐỘ TRUNG BÌNH",
                                    style: TextStyle(
                                        color: labelColor,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 11)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 30),
                          _buildSectionHeader(
                              "NHIỆM VỤ THEO PHÂN LOẠI", labelColor,
                              alignLeft: true),
                          const SizedBox(height: 15),
                          _buildDuoCard(
                            isDark,
                            borderColor,
                            cardBg,
                            child: SizedBox(
                                height: 220,
                                child: _buildCategoryBarChart(
                                    tasks, isDark, borderColor, labelColor)),
                          ),
                          const SizedBox(height: 30),
                          _buildDuoMessage(
                              avgProgress, isDark, borderColor, textColor),
                          const SizedBox(height: 30),
                          _buildSectionHeader("PHÂN TÍCH ƯU TIÊN", labelColor,
                              alignLeft: true),
                          const SizedBox(height: 15),
                          _buildPrioritySection(tasks, isDark, borderColor,
                              cardBg, textColor, labelColor),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color,
      {bool alignLeft = false}) {
    return Align(
      alignment: alignLeft ? Alignment.centerLeft : Alignment.center,
      child: Text(title,
          style: TextStyle(
              fontWeight: FontWeight.w900,
              color: color,
              fontSize: 13,
              letterSpacing: 1.2)),
    );
  }

  Widget _buildEmptyState(Color color) {
    return Center(
        child: Text("\nCHƯA CÓ DỮ LIỆU",
            textAlign: TextAlign.center,
            style: TextStyle(color: color, fontWeight: FontWeight.w900)));
  }

  Widget _buildLegendItem(Color color, String label, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(label,
              style: TextStyle(
                  color: textColor, fontWeight: FontWeight.w900, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildDuoCard(bool isDark, Color borderColor, Color cardBg,
      {required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border(
          top: BorderSide(color: borderColor, width: 2),
          left: BorderSide(color: borderColor, width: 2),
          right: BorderSide(color: borderColor, width: 2),
          bottom: BorderSide(color: borderColor, width: 6),
        ),
      ),
      child: child,
    );
  }

  Widget _buildCategoryBarChart(
      List<Task> tasks, bool isDark, Color borderColor, Color labelColor) {
    final categories = ["CÔNG VIỆC", "CÁ NHÂN", "HỌC TẬP", "KHÁC"];
    final counts = categories
        .map((cat) => tasks
            .where((t) => t.category.toUpperCase() == cat)
            .length
            .toDouble())
        .toList();
    double maxVal = counts.isEmpty ? 5 : counts.reduce((a, b) => a > b ? a : b);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: (maxVal + 1).clamp(5, 100),
        titlesData: FlTitlesData(
          leftTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value < 0 || value >= categories.length)
                  return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(categories[value.toInt()].substring(0, 4),
                      style: TextStyle(
                          color: labelColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 10)),
                );
              },
            ),
          ),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(counts.length, (i) {
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: counts[i],
                color: [duoBlue, duoPurple, duoOrange, duoGreen][i % 4],
                width: 22,
                borderRadius: BorderRadius.circular(6),
                backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: (maxVal + 1).clamp(5, 100),
                    color: isDark ? Colors.white10 : duoLightGray),
              ),
            ],
          );
        }),
      ),
    );
  }

  PieChartSectionData _buildPieSection(
      double value, Color color, String title) {
    return PieChartSectionData(
      value: value,
      color: color,
      title: value > 0 ? '${value.toInt()}' : '',
      radius: 50,
      titleStyle: const TextStyle(
          color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14),
    );
  }

  Widget _buildDuoMessage(
      double progress, bool isDark, Color borderColor, Color textColor) {
    String msg = progress > 70
        ? "Siêu quá! Bạn đang xử lý công việc rất mượt mà đó!"
        : "Cú Duo đang quan sát... Đừng để các nhiệm vụ bị quá hạn nhé!";
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
          color: isDark ? const Color(0xFF202F36) : duoLightGray,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: borderColor, width: 2)),
      child: Row(
        children: [
          const Text("🦉", style: TextStyle(fontSize: 40)),
          const SizedBox(width: 15),
          Expanded(
              child: Text(msg,
                  style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 14))),
        ],
      ),
    );
  }

  Widget _buildPrioritySection(List<Task> tasks, bool isDark, Color borderColor,
      Color cardBg, Color textColor, Color labelColor) {
    return Column(
      children: [
        _buildDuoPriorityCard(
            "MỨC ĐỘ CAO",
            tasks.where((t) => t.priority == 3).toList(),
            Colors.redAccent,
            isDark,
            borderColor,
            cardBg,
            textColor,
            labelColor),
        _buildDuoPriorityCard(
            "TRUNG BÌNH",
            tasks.where((t) => t.priority == 2).toList(),
            duoOrange,
            isDark,
            borderColor,
            cardBg,
            textColor,
            labelColor),
        _buildDuoPriorityCard(
            "MỨC ĐỘ THẤP",
            tasks.where((t) => t.priority == 1).toList(),
            duoBlue,
            isDark,
            borderColor,
            cardBg,
            textColor,
            labelColor),
      ],
    );
  }

  Widget _buildDuoPriorityCard(
      String label,
      List<Task> filteredTasks,
      Color color,
      bool isDark,
      Color borderColor,
      Color cardBg,
      Color textColor,
      Color labelColor) {
    int completed = filteredTasks.where((t) => t.progress == 100).length;
    double percent =
        filteredTasks.isEmpty ? 0 : (completed / filteredTasks.length);
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border(
          top: BorderSide(color: borderColor, width: 2),
          left: BorderSide(color: borderColor, width: 2),
          right: BorderSide(color: borderColor, width: 2),
          bottom: BorderSide(color: borderColor, width: 4),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.w900, fontSize: 12)),
              Text("${filteredTasks.length} VIỆC",
                  style: TextStyle(
                      color: labelColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 11)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                  value: percent,
                  minHeight: 10,
                  backgroundColor:
                      isDark ? Colors.white10 : duoGray.withOpacity(0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(color))),
          const SizedBox(height: 8),
          Align(
              alignment: Alignment.centerRight,
              child: Text("ĐÃ XONG $completed/${filteredTasks.length}",
                  style: TextStyle(
                      fontSize: 10,
                      color: labelColor,
                      fontWeight: FontWeight.w900))),
        ],
      ),
    );
  }
}
