import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/user_availability_model.dart';
import '../models/task_schedule_model.dart';
import '../provider/task_provider.dart';
import '../services/smart_scheduler_service.dart';
import '../widgets/web_sidebar.dart';
import '../widgets/quick_edit_task_dialog.dart';
import '../widgets/app_popup.dart';
import 'task_detail_screen.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  TimeOfDay _startTime = const TimeOfDay(hour: 19, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 21, minute: 0);

  List<TaskSchedule> _todaySchedules = [];
  List<TaskSchedule> _tomorrowSuggestions = [];
  bool _hasGenerated = false;

  final Color duoGreen = const Color(0xFF58CC02);
  final Color duoGreenDark = const Color(0xFF46A302);
  final Color duoBlue = const Color(0xFF1CB0F6);
  final Color duoBlueDark = const Color(0xFF1899D6);
  final Color duoOrange = const Color(0xFFFF9600);
  final Color duoText = const Color(0xFF3C3C3C);
  final Color duoSecondaryText = const Color(0xFF777777);
  final Color duoGray = const Color(0xFFE5E5E5);

  void _generateSchedule() {
    final taskProvider = context.read<TaskProvider>();
    int duration = (_endTime.hour * 60 + _endTime.minute) -
        (_startTime.hour * 60 + _startTime.minute);

    if (duration <= 0) {
      AppPopup.error(context, "Giờ kết thúc phải sau giờ bắt đầu!");
      return;
    }

    final availability = UserAvailability(
      availability_id: const Uuid().v4(),
      user_id: "current_user",
      date: DateTime.now(),
      start_time: "${_startTime.hour}:${_startTime.minute}",
      end_time: "${_endTime.hour}:${_endTime.minute}",
      duration_minute: duration,
      isRecurring: false,
      day_of_week: DateTime.now().weekday,
      created_at: DateTime.now(),
    );

    final result = SmartSchedulerService.suggestAdvancedSchedule(
      pendingTasks: taskProvider.tasks.where((t) => t.progress < 100).toList(),
      todayAvailability: availability,
    );

    setState(() {
      _todaySchedules = result['today']!;
      _tomorrowSuggestions = result['tomorrow']!;
      _hasGenerated = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final scaffoldBg = isDark ? const Color(0xFF121212) : Colors.white;
    final textColor = isDark ? Colors.white : duoText;
    final labelColor = isDark ? Colors.white70 : duoSecondaryText;
    final borderColor = isDark ? const Color(0xFF37464F) : duoGray;
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    double width = MediaQuery.of(context).size.width;
    bool isWeb = width > 900;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: isWeb
          ? null
          : AppBar(
              elevation: 0,
              backgroundColor: scaffoldBg,
              centerTitle: true,
              title: Text(
                "LẬP LỊCH THÔNG MINH",
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  letterSpacing: 1.2,
                ),
              ),
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new,
                  color: labelColor,
                  size: 22,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
      body: Row(
        children: [
          if (isWeb) const WebSidebar(currentRoute: 'schedule'),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  children: [
                    if (isWeb) ...[
                      Padding(
                        padding: const EdgeInsets.only(
                          top: 30,
                          left: 20,
                          bottom: 20,
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "LẬP LỊCH THÔNG MINH",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: textColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                    Container(
                      margin: const EdgeInsets.all(20),
                      padding: const EdgeInsets.all(25),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(25),
                        border: Border(
                          top: BorderSide(color: borderColor, width: 2),
                          left: BorderSide(color: borderColor, width: 2),
                          right: BorderSide(color: borderColor, width: 2),
                          bottom: BorderSide(color: borderColor, width: 6),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            "BẠN RẢNH LÚC NÀO HÔM NAY?",
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: labelColor,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 25),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _timeTile(
                                context,
                                "BẮT ĐẦU",
                                _startTime,
                                (t) => setState(() => _startTime = t!),
                                isDark,
                                labelColor,
                              ),
                              Icon(Icons.fast_forward_rounded, color: duoGreen),
                              _timeTile(
                                context,
                                "KẾT THÚC",
                                _endTime,
                                (t) => setState(() => _endTime = t!),
                                isDark,
                                labelColor,
                              ),
                            ],
                          ),
                          const SizedBox(height: 30),
                          _buildDuoButton(
                            "PHÂN TÍCH LỊCH TRÌNH",
                            duoGreen,
                            duoGreenDark,
                            _generateSchedule,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: !_hasGenerated
                          ? _buildEmptyState(labelColor)
                          : ListView(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              children: [
                                if (_todaySchedules.isNotEmpty) ...[
                                  _buildSectionHeader("HÔM NAY", duoGreen),
                                  ..._todaySchedules.map(
                                    (s) => _buildScheduleItem(
                                      s,
                                      isDark,
                                      borderColor,
                                      textColor,
                                      labelColor,
                                    ),
                                  ),
                                ],
                                if (_tomorrowSuggestions.isNotEmpty) ...[
                                  const SizedBox(height: 20),
                                  _buildSectionHeader(
                                    "DỜI SANG NGÀY MAI",
                                    duoBlue,
                                  ),
                                  ..._tomorrowSuggestions.map(
                                    (s) => _buildScheduleItem(
                                      s,
                                      isDark,
                                      borderColor,
                                      textColor,
                                      labelColor,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 40),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _timeTile(
    BuildContext context,
    String label,
    TimeOfDay time,
    Function(TimeOfDay?) onSelected,
    bool isDark,
    Color labelColor,
  ) {
    return InkWell(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: time,
        );
        if (picked != null) onSelected(picked);
      },
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: labelColor,
              fontWeight: FontWeight.w900,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            time.format(context),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: duoBlue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 5, bottom: 12, top: 10),
      child: Text(
        title,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 13,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildScheduleItem(
    TaskSchedule schedule,
    bool isDark,
    Color borderColor,
    Color textColor,
    Color labelColor,
  ) {
    final task = context.read<TaskProvider>().tasks.firstWhere(
          (t) => t.task_id == schedule.task_id,
        );
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border(
          top: BorderSide(color: borderColor, width: 2),
          left: BorderSide(color: borderColor, width: 2),
          right: BorderSide(color: borderColor, width: 2),
          bottom: BorderSide(color: borderColor, width: 5),
        ),
      ),
      child: ListTile(
        onTap: () => _openTask(task),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (schedule.status == 'carry_over' ? duoOrange : duoGreen)
                .withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            schedule.status == 'carry_over' ? Icons.next_plan : Icons.bolt,
            color: schedule.status == 'carry_over' ? duoOrange : duoGreen,
            size: 20,
          ),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: textColor,
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          "${schedule.duration_minutes} PHÚT ${schedule.is_auto_split ? '(CHIA NHỎ)' : ''}",
          style: TextStyle(
            color: labelColor,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        trailing: Text(
          "${schedule.score_heuristic}đ",
          style: TextStyle(color: duoBlue, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }

  Widget _buildDuoButton(
    String text,
    Color color,
    Color shadowColor,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 55,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(color: shadowColor, offset: const Offset(0, 4)),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(Color labelColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("🦉", style: TextStyle(fontSize: 70)),
          const SizedBox(height: 15),
          Text(
            "CÚ ĐANG ĐỢI LỆNH!",
            style: TextStyle(
              color: labelColor,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  void _openTask(task) {
    if (task.project_id != null && task.project_id!.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => TaskDetailScreen(task: task)),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (_) => QuickEditTaskDialog(task: task),
    );
  }
}
