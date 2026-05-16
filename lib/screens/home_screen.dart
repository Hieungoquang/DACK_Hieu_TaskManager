import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../provider/task_provider.dart';
import '../provider/app_provider.dart';
import '../models/project_model.dart';
import '../models/task_model.dart';
import '../widgets/web_sidebar.dart';
import '../widgets/mobile_bottom_nav.dart';
import '../widgets/quick_edit_task_dialog.dart';
import 'project_board_screen.dart';
import 'profile_screen.dart';
import 'add_project_screen.dart';
import 'task_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _displayName = 'Người dùng';
  DateTime _miniMonth = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  bool _isStatsExpanded = true;

  // GitHub Style Colors
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TaskProvider>(context, listen: false).loadTasks();
    });
  }

  bool _sameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    try {
      return a.year == b.year && a.month == b.month && a.day == b.day;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final isDark = appProvider.themeMode == ThemeMode.dark;
    final isWeb = MediaQuery.of(context).size.width > 900;
    final provider = context.watch<TaskProvider>();

    final bgColor = isDark ? ghDarkBg : ghLightBg;
    final textColor = isDark ? ghDarkText : ghLightText;
    final borderColor = isDark ? ghDarkBorder : ghLightBorder;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: isWeb ? null : _buildMobileAppBar(isDark, textColor),
      bottomNavigationBar: isWeb ? null : MobileBottomNav(currentRoute: 'home'),
      body: Row(
        children: [
          if (isWeb) const WebSidebar(currentRoute: 'home'),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isWeb ? 40 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildGreeting(isDark, isWeb),
                  const SizedBox(height: 30),
                  _buildStatsGrid(isDark, provider),
                  const SizedBox(height: 30),
                  if (isWeb)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: _buildMainContent(
                            isDark,
                            provider,
                            borderColor,
                          ),
                        ),
                        const SizedBox(width: 30),
                        Expanded(
                          flex: 1,
                          child: _buildSideContent(
                            isDark,
                            provider,
                            borderColor,
                          ),
                        ),
                      ],
                    )
                  else
                    Column(
                      children: [
                        _buildMainContent(isDark, provider, borderColor),
                        const SizedBox(height: 30),
                        _buildSideContent(isDark, provider, borderColor),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  AppBar _buildMobileAppBar(bool isDark, Color textColor) {
    return AppBar(
      backgroundColor: isDark ? ghDarkBg : ghLightBg,
      elevation: 0,
      title: Text(
        "TASKFLOW",
        style: TextStyle(
          color: ghGreen,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
          fontSize: 22,
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.person_outline, color: textColor, size: 26),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProfileScreen()),
          ),
        ),
      ],
    );
  }

  Widget _buildGreeting(bool isDark, bool isWeb) {
    final now = DateTime.now();
    String greet = now.hour < 12
        ? 'Chào buổi sáng'
        : now.hour < 18
            ? 'Chào buổi chiều'
            : 'Chào buổi tối';
    final textColor = isDark ? ghDarkText : ghLightText;
    final provider = context.watch<TaskProvider>();
    final displayName = provider.currentUser?.full_name ?? _displayName;
    final subColor = isDark ? ghDarkSubText : ghLightSubText;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$greet, $displayName!',
          style: TextStyle(
            fontSize: isWeb ? 34 : 26,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Hôm nay là ngày ${now.day}/${now.month}/${now.year}',
          style: TextStyle(fontSize: 16, color: subColor),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(bool isDark, TaskProvider provider) {
    final total = provider.tasks.length;
    final done = provider.tasks.where((t) => t.status == 'completed').length;
    final inProg =
        provider.tasks.where((t) => t.status == 'in_progress').length;
    final pending = provider.tasks.where((t) => t.status == 'pending').length;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "THỐNG KÊ",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? ghDarkText : ghLightText,
              ),
            ),
            InkWell(
              onTap: () => setState(() => _isStatsExpanded = !_isStatsExpanded),
              child: Row(
                children: [
                  Text(
                    _isStatsExpanded ? "Thu gọn" : "Mở rộng",
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? ghDarkSubText : ghLightSubText,
                    ),
                  ),
                  Icon(
                    _isStatsExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                    color: isDark ? ghDarkSubText : ghLightSubText,
                  ),
                ],
              ),
            ),
          ],
        ),
        if (_isStatsExpanded) ...[
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio:
                MediaQuery.of(context).size.width > 600 ? 2.0 : 1.6,
            children: [
              _buildStatCard("Tổng cộng", total, ghBlue, isDark),
              _buildStatCard("Hoàn thành", done, ghGreen, isDark),
              _buildStatCard("Đang làm", inProg, ghOrange, isDark),
              _buildStatCard("Đang chờ", pending, Colors.redAccent, isDark),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildStatCard(String label, int value, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.15),
            color.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? ghDarkSubText : ghLightSubText,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                '$value',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.circle,
                size: 12,
                color: color,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(
    bool isDark,
    TaskProvider provider,
    Color borderColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          "DỰ ÁN",
          () => showDialog(
            context: context,
            builder: (_) => const AddProjectScreen(),
          ),
          isDark,
        ),
        const SizedBox(height: 16),
        if (provider.projects.isEmpty)
          _buildEmptyState(Icons.folder_outlined, "Chưa có dự án nào", isDark)
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: provider.projects.length,
            itemBuilder: (context, index) => _buildProjectListItem(
              provider.projects[index],
              provider,
              isDark,
              borderColor,
            ),
          ),
        const SizedBox(height: 40),
        _buildSectionHeader("NHIỆM VỤ GẦN ĐÂY", null, isDark),
        const SizedBox(height: 16),
        _buildRecentTasksList(isDark, provider, borderColor),
      ],
    );
  }

  Widget _buildSideContent(
    bool isDark,
    TaskProvider provider,
    Color borderColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMiniCalendar(isDark, borderColor),
        const SizedBox(height: 30),
        _buildTaskStatsChart(isDark, provider, borderColor),
      ],
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback? onAdd, bool isDark) {
    final textColor = isDark ? ghDarkSubText : ghLightSubText;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 14,
            letterSpacing: 1.2,
          ),
        ),
        if (onAdd != null)
          IconButton(
            icon: Icon(Icons.add_circle_outline, size: 22, color: ghGreen),
            onPressed: onAdd,
          ),
      ],
    );
  }

  Widget _buildProjectListItem(
    Project p,
    TaskProvider provider,
    bool isDark,
    Color borderColor,
  ) {
    final tasks =
        provider.tasks.where((t) => t.project_id == p.project_id).toList();
    final done = tasks.where((t) => t.status == 'completed').length;
    final progress = tasks.isEmpty ? 0.0 : done / tasks.length;
    final cardColor = isDark ? ghDarkCard : Colors.white;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ProjectBoardScreen(project: p)),
        ),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: ghBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.folder_outlined, color: ghBlue, size: 24),
        ),
        title: Text(
          p.name,
          style: TextStyle(
            color: isDark ? ghDarkText : ghLightText,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  "${tasks.length} nhiệm vụ",
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? ghDarkSubText : ghLightSubText,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  "•",
                  style: TextStyle(
                    color: isDark ? ghDarkSubText : ghLightSubText,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  "${(progress * 100).toInt()}%",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: ghGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: borderColor,
                valueColor: const AlwaysStoppedAnimation(ghGreen),
                minHeight: 4,
              ),
            ),
          ],
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: isDark ? ghDarkSubText : ghLightSubText,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildRecentTasksList(
    bool isDark,
    TaskProvider provider,
    Color borderColor,
  ) {
    final tasks = provider.tasks.take(5).toList();
    final cardColor = isDark ? ghDarkCard : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: tasks.isEmpty
          ? _buildEmptyState(Icons.task_alt, "Chưa có nhiệm vụ nào", isDark)
          : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: tasks.length,
              separatorBuilder: (_, __) =>
                  Divider(color: borderColor, height: 1),
              itemBuilder: (context, index) {
                final t = tasks[index];
                return ListTile(
                  onTap: () => _openTask(t),
                  leading: Icon(
                    t.status == 'completed'
                        ? Icons.check_circle
                        : (t.status == 'in_progress'
                            ? Icons.timelapse
                            : Icons.radio_button_unchecked),
                    color: t.status == 'completed'
                        ? ghPurple
                        : (t.status == 'in_progress'
                            ? ghOrange
                            : ghDarkSubText),
                    size: 22,
                  ),
                  title: Text(
                    t.title,
                    style: TextStyle(
                      color: isDark ? ghDarkText : ghLightText,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  subtitle: Text(
                    DateFormat('dd MMM').format(t.due_day),
                    style: TextStyle(
                      color: isDark ? ghDarkSubText : ghLightSubText,
                      fontSize: 13,
                    ),
                  ),
                  trailing: Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: isDark ? ghDarkSubText : ghLightSubText,
                  ),
                );
              },
            ),
    );
  }

  void _openTask(Task task) {
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

  Widget _buildMiniCalendar(bool isDark, Color borderColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? ghDarkCard : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "THÁNG ${_miniMonth.month}/${_miniMonth.year}",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark ? ghDarkText : ghLightText,
                  fontSize: 15,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, size: 22),
                    onPressed: () => setState(
                      () => _miniMonth = DateTime(
                        _miniMonth.year,
                        _miniMonth.month - 1,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, size: 22),
                    onPressed: () => setState(
                      () => _miniMonth = DateTime(
                        _miniMonth.year,
                        _miniMonth.month + 1,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildCalendarGrid(isDark),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid(bool isDark) {
    final first = DateTime(_miniMonth.year, _miniMonth.month, 1);
    final offset = first.weekday - 1;
    final daysCount = DateUtils.getDaysInMonth(
      _miniMonth.year,
      _miniMonth.month,
    );
    final now = DateTime.now();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
      ),
      itemCount: offset + daysCount,
      itemBuilder: (context, i) {
        if (i < offset) return const SizedBox();
        final day = DateTime(_miniMonth.year, _miniMonth.month, i - offset + 1);
        final isToday = _sameDay(day, now);
        final isSelected = _sameDay(day, _selectedDay);

        return GestureDetector(
          onTap: () => setState(() => _selectedDay = day),
          child: Center(
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: isToday
                    ? ghGreen
                    : (isSelected
                        ? ghBlue.withOpacity(0.2)
                        : Colors.transparent),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                "${day.day}",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isToday
                      ? Colors.white
                      : (isSelected
                          ? ghBlue
                          : (isDark ? ghDarkSubText : ghLightSubText)),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTaskStatsChart(
    bool isDark,
    TaskProvider provider,
    Color borderColor,
  ) {
    final done = provider.tasks.where((t) => t.status == 'completed').length;
    final inProg =
        provider.tasks.where((t) => t.status == 'in_progress').length;
    final pending = provider.tasks.where((t) => t.status == 'pending').length;
    final total = done + inProg + pending;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? ghDarkCard : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "HOẠT ĐỘNG",
            style: TextStyle(
              color: isDark ? ghDarkSubText : ghLightSubText,
              fontWeight: FontWeight.bold,
              fontSize: 14,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 24),
          if (total == 0)
            _buildEmptyState(Icons.bar_chart, "Chưa có dữ liệu", isDark)
          else
            Row(
              children: [
                SizedBox(
                  width: 100,
                  height: 100,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 3,
                      centerSpaceRadius: 25,
                      sections: [
                        if (done > 0)
                          PieChartSectionData(
                            value: done.toDouble(),
                            color: ghGreen,
                            radius: 20,
                            title: '',
                          ),
                        if (inProg > 0)
                          PieChartSectionData(
                            value: inProg.toDouble(),
                            color: ghOrange,
                            radius: 20,
                            title: '',
                          ),
                        if (pending > 0)
                          PieChartSectionData(
                            value: pending.toDouble(),
                            color: Colors.redAccent,
                            radius: 20,
                            title: '',
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    children: [
                      _buildChartLegend("Xong", ghGreen, isDark),
                      _buildChartLegend("Đang làm", ghOrange, isDark),
                      _buildChartLegend("Chờ", Colors.redAccent, isDark),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildChartLegend(String label, Color color, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? ghDarkSubText : ghLightSubText,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String message, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            Icon(
              icon,
              size: 48,
              color: isDark
                  ? ghDarkSubText.withOpacity(0.2)
                  : ghLightSubText.withOpacity(0.2),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              style: TextStyle(
                color: isDark ? ghDarkSubText : ghLightSubText,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
