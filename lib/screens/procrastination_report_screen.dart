import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../provider/task_provider.dart';
import '../provider/app_provider.dart';
import '../services/prediction_service.dart';
import '../models/task_model.dart';
import '../widgets/web_sidebar.dart';
import '../widgets/mobile_bottom_nav.dart';
import '../widgets/quick_edit_task_dialog.dart';
import 'task_detail_screen.dart';

class ProcrastinationReportScreen extends StatefulWidget {
  const ProcrastinationReportScreen({super.key});

  @override
  State<ProcrastinationReportScreen> createState() => _ProcrastinationReportScreenState();
}

class _ProcrastinationReportScreenState extends State<ProcrastinationReportScreen> {
  String? _expandedCategory;

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

    final analysis = PredictionService.analyzeProcrastination(provider.tasks);

    return Scaffold(
      backgroundColor: _bg(isDark),
      bottomNavigationBar: isWeb ? null : const MobileBottomNav(currentRoute: 'home'),
      body: Row(
        children: [
          if (isWeb) const WebSidebar(currentRoute: 'reality_check'),
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
                        if (isWeb)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 4,
                                child: Column(
                                  children: [
                                    _buildGaugeCard(isDark, analysis),
                                    const SizedBox(height: 20),
                                    _buildRoastCard(isDark, analysis),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                flex: 6,
                                child: Column(
                                  children: [
                                    _buildCategoryBreakdownCard(isDark, analysis, provider),
                                    const SizedBox(height: 20),
                                    _buildGoldenHourCard(isDark, provider),
                                  ],
                                ),
                              ),
                            ],
                          )
                        else
                          Column(
                            children: [
                              _buildGaugeCard(isDark, analysis),
                              const SizedBox(height: 20),
                              _buildRoastCard(isDark, analysis),
                              const SizedBox(height: 20),
                              _buildCategoryBreakdownCard(isDark, analysis, provider),
                              const SizedBox(height: 20),
                              _buildGoldenHourCard(isDark, provider),
                            ],
                          ),
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
        Icon(Icons.psychology_alt_rounded, color: Colors.purpleAccent, size: 28),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "REALITY CHECK",
                style: GoogleFonts.nunito(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: _txt(isDark),
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                "Báo cáo phân tích mức độ lười biếng và xu hướng trì hoãn",
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  color: _sub(isDark),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGaugeCard(bool isDark, ProcrastinationAnalysis analysis) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      decoration: BoxDecoration(
        color: _card(isDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border(isDark)),
      ),
      child: Center(
        child: ProcrastinationGauge(score: analysis.lazinessQuotient),
      ),
    );
  }

  Widget _buildRoastCard(bool isDark, ProcrastinationAnalysis analysis) {
    final color = HSLColor.fromAHSL(1.0, (1.0 - analysis.lazinessQuotient) * 120, 0.85, 0.45).toColor();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.08 : 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.4), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.smart_toy_rounded, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Text(
                "GIỌNG ĐIỆU CỦA TASKFLOW AI",
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: color,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            analysis.roastMessage,
            style: GoogleFonts.nunito(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: _txt(isDark),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdownCard(bool isDark, ProcrastinationAnalysis analysis, TaskProvider provider) {
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
            "PHÂN TÍCH THEO NHÓM",
            style: GoogleFonts.nunito(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: _sub(isDark),
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 20),
          if (analysis.categoryDelayRates.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 30),
                child: Text(
                  "Không có dữ liệu công việc hợp lệ.",
                  style: GoogleFonts.nunito(color: _sub(isDark)),
                ),
              ),
            )
          else
            ...analysis.categoryDelayRates.entries.map((entry) {
              final catName = entry.key;
              final rate = entry.value;
              final overdueCount = analysis.categoryOverdueCounts[catName] ?? 0;
              final isExpanded = _expandedCategory == catName;

              final catColor = HSLColor.fromAHSL(1.0, (1.0 - rate) * 120, 0.85, 0.45).toColor();

              return Column(
                children: [
                  InkWell(
                    onTap: () {
                      setState(() {
                        _expandedCategory = isExpanded ? null : catName;
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.label_outline, color: catColor, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                catName,
                                style: GoogleFonts.nunito(
                                  fontWeight: FontWeight.bold,
                                  color: _txt(isDark),
                                  fontSize: 14,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                overdueCount > 0 ? "$overdueCount việc trễ" : "An toàn",
                                style: GoogleFonts.nunito(
                                  fontWeight: FontWeight.bold,
                                  color: overdueCount > 0 ? Colors.redAccent : Colors.green,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                size: 18,
                                color: _sub(isDark),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: rate == 0.0 ? 0.02 : rate, // minimum sliver visibility
                              minHeight: 8,
                              backgroundColor: _border(isDark),
                              valueColor: AlwaysStoppedAnimation(catColor),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Tỷ lệ trì hoãn",
                                style: GoogleFonts.nunito(color: _sub(isDark), fontSize: 11),
                              ),
                              Text(
                                "${(rate * 100).toInt()}%",
                                style: GoogleFonts.nunito(
                                  color: catColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (isExpanded) ...[
                    const SizedBox(height: 8),
                    _buildOverdueTasksList(isDark, provider, catName),
                    const Divider(),
                  ],
                ],
              );
            }),
        ],
      ),
    );
  }

  Widget _buildOverdueTasksList(bool isDark, TaskProvider provider, String category) {
    final now = DateTime.now();
    final outstanding = provider.tasks.where((t) {
      if (t.isDeleted || t.category != category) return false;
      if (t.status == 'completed') {
        return t.updatedAt.isAfter(t.deadline);
      }
      return now.isAfter(t.deadline);
    }).toList();

    if (outstanding.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        alignment: Alignment.center,
        child: Text(
          "Không có việc trễ hạn trong mảng này!",
          style: GoogleFonts.nunito(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13),
        ),
      );
    }

    return Column(
      children: outstanding.map((task) {
        final isCompleted = task.status == 'completed';
        return Card(
          color: isDark ? const Color(0xFF0F141C) : const Color(0xFFF6F8FA),
          elevation: 0,
          margin: const EdgeInsets.symmetric(vertical: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: _border(isDark)),
          ),
          child: ListTile(
            dense: true,
            title: Text(
              task.title,
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.bold,
                color: _txt(isDark),
                decoration: isCompleted ? TextDecoration.lineThrough : null,
              ),
            ),
            subtitle: Text(
              "Hạn chót: ${DateFormat('dd/MM/yyyy HH:mm').format(task.deadline)}",
              style: GoogleFonts.nunito(color: Colors.redAccent, fontSize: 11),
            ),
            trailing: Icon(Icons.chevron_right, size: 16, color: _sub(isDark)),
            onTap: () {
              if (task.project_id != null && task.project_id!.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => TaskDetailScreen(task: task)),
                );
              } else {
                showDialog(
                  context: context,
                  builder: (_) => QuickEditTaskDialog(task: task),
                );
              }
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGoldenHourCard(bool isDark, TaskProvider provider) {
    // static helper golden hours
    final completed = provider.tasks.where((t) => t.status == 'completed').toList();
    final goldenHours = PredictionService.calculateGoldenHours([], completed);

    final hourStrings = goldenHours.map((h) => "$h:00").join(" và ");

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _card(isDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border(isDark)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: ghOrange.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.wb_sunny_rounded, color: ghOrange, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "KHUNG GIỜ TẬP TRUNG CAO ĐỘ",
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: ghOrange,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Dựa trên các hành động hoàn thành việc trong quá khứ, giờ vàng của bạn là: $hourStrings. Hãy ưu tiên xử lý các việc khó nhất vào khung giờ này nhé!",
                  style: GoogleFonts.nunito(
                    color: _txt(isDark),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ProcrastinationGauge extends StatelessWidget {
  final double score;

  const ProcrastinationGauge({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    final color = HSLColor.fromAHSL(1.0, (1.0 - score) * 120, 0.85, 0.45).toColor();

    return Column(
      children: [
        CustomPaint(
          size: const Size(200, 100),
          painter: ProcrastinationGaugePainter(score: score, color: color),
        ),
        const SizedBox(height: 16),
        Text(
          "${(score * 100).toInt()}%",
          style: GoogleFonts.nunito(
            fontSize: 42,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "CHỈ SỐ TRÌ HOÃN",
          style: GoogleFonts.nunito(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).brightness == Brightness.dark ? Colors.grey : Colors.grey[700],
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}

class ProcrastinationGaugePainter extends CustomPainter {
  final double score;
  final Color color;

  ProcrastinationGaugePainter({required this.score, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2 - 10;

    final paintBg = Paint()
      ..color = Colors.grey.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    final paintFill = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    // Draw background arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      3.14159, // 180 degrees in radians
      3.14159,
      false,
      paintBg,
    );

    // Draw filled arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      3.14159, // 180 degrees in radians
      3.14159 * score,
      false,
      paintFill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
