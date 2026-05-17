import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
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
import 'procrastination_report_screen.dart';

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
  String _taskSearchQuery = '';
  int? _selectedTaskPriority;

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
                  _buildCrisisAlerts(isDark, provider),
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
        style: GoogleFonts.nunito(
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
          style: GoogleFonts.nunito(
            fontSize: isWeb ? 34 : 26,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Hôm nay là ngày ${now.day}/${now.month}/${now.year}',
          style: GoogleFonts.nunito(fontSize: 16, color: subColor),
        ),
      ],
    );
  }

  Widget _buildCrisisAlerts(bool isDark, TaskProvider provider) {
    final crisisTasks = provider.crisisTasks;
    if (crisisTasks.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 24),
            const SizedBox(width: 8),
            Text(
              "CẢNH BÁO KHỦNG HOẢNG DEADLINE",
              style: GoogleFonts.nunito(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.redAccent,
                letterSpacing: 1.1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.redAccent.withOpacity(isDark ? 0.1 : 0.05),
            border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: crisisTasks.map((t) {
              final prob = provider.crisisProbabilities[t.task_id] ?? 0.0;
              final percent = (prob * 100).toInt();
              return ListTile(
                onTap: () => _openTask(t),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.timer_off, color: Colors.redAccent, size: 20),
                ),
                title: Text(
                  t.title,
                  style: GoogleFonts.nunito(
                    color: isDark ? ghDarkText : ghLightText,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                subtitle: Text(
                  "Nguy cơ trễ hạn: $percent%",
                  style: GoogleFonts.nunito(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                trailing: Icon(
                  Icons.chevron_right,
                  color: isDark ? ghDarkSubText : ghLightSubText,
                  size: 20,
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 30),
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
              style: GoogleFonts.nunito(
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
                    style: GoogleFonts.nunito(
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
          const SizedBox(height: 16),
          _buildRealityCheckBanner(isDark),
        ],
      ],
    );
  }

  Widget _buildRealityCheckBanner(bool isDark) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProcrastinationReportScreen()),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF3B154C), const Color(0xFF1F0B2D)]
                : [const Color(0xFFF2E6FF), const Color(0xFFE5CCFF)],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? const Color(0xFF6B2D8C) : const Color(0xFFCC99FF),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.purple.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.psychology_alt_rounded, color: Colors.purpleAccent, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "REALITY CHECK 🧐",
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.purpleAccent : const Color(0xFF6B2D8C),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Xem phân tích xu hướng trì hoãn và phản hồi thực tế từ AI Coach.",
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark ? ghDarkText : ghLightText,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: isDark ? Colors.purpleAccent : const Color(0xFF6B2D8C),
              size: 14,
            ),
          ],
        ),
      ),
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
            style: GoogleFonts.nunito(
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
                style: GoogleFonts.nunito(
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
    final textColor = isDark ? ghDarkText : ghLightText;
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
        _buildSectionHeader("NHIỆM VỤ", null, isDark),
        const SizedBox(height: 16),
        _buildSearchAndFilterTasks(isDark, textColor, isDark ? ghDarkSubText : ghLightSubText),
        const SizedBox(height: 16),
        _buildRecentTasksList(isDark, provider, borderColor),
      ],
    );
  }

  Widget _buildSearchAndFilterTasks(bool isDark, Color textColor, Color labelColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Thanh tìm kiếm
        Container(
          height: 46,
          decoration: BoxDecoration(
            color: isDark ? ghDarkCard : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isDark ? ghDarkBorder : ghLightBorder),
          ),
          child: TextField(
            onChanged: (val) => setState(() => _taskSearchQuery = val),
            style: GoogleFonts.nunito(color: textColor, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              hintText: "Tìm kiếm nhiệm vụ...",
              hintStyle: GoogleFonts.nunito(color: labelColor.withOpacity(0.5), fontWeight: FontWeight.bold),
              prefixIcon: Icon(Icons.search, color: labelColor),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Phân loại ưu tiên
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _priorityChip("Tất cả", null, isDark),
              const SizedBox(width: 8),
              _priorityChip("Cao", 3, isDark, color: Colors.redAccent),
              const SizedBox(width: 8),
              _priorityChip("Vừa", 2, isDark, color: ghOrange),
              const SizedBox(width: 8),
              _priorityChip("Thấp", 1, isDark, color: ghBlue),
            ],
          ),
        ),
      ],
    );
  }

  Widget _priorityChip(String label, int? value, bool isDark, {Color? color}) {
    final isSelected = _selectedTaskPriority == value;
    final baseColor = color ?? (isDark ? ghDarkText : ghLightText);
    return GestureDetector(
      onTap: () => setState(() => _selectedTaskPriority = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? baseColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? baseColor : (isDark ? ghDarkBorder : ghLightBorder),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.nunito(
            color: isSelected ? baseColor : (isDark ? ghDarkSubText : ghLightSubText),
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
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
        _buildMiniCalendar(isDark, borderColor, provider),
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
          style: GoogleFonts.nunito(
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
          style: GoogleFonts.nunito(
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
                  style: GoogleFonts.nunito(
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
                  style: GoogleFonts.nunito(
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
            if (p.startDate != null || p.endDate != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today_outlined, size: 11, color: isDark ? ghDarkSubText : ghLightSubText),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _getProjectTimelineShort(p),
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        color: isDark ? ghDarkSubText : ghLightSubText,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
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
    final filteredTasks = provider.tasks.where((t) {
      final matchSearch = t.title.toLowerCase().contains(_taskSearchQuery.toLowerCase());
      final matchPriority = _selectedTaskPriority == null || t.priority == _selectedTaskPriority;
      return matchSearch && matchPriority;
    }).toList();

    // Giới hạn 5 task gần nhất nếu không có tìm kiếm, ngược lại hiển thị kết quả tìm kiếm (tối đa 20)
    final isFiltering = _taskSearchQuery.isNotEmpty || _selectedTaskPriority != null;
    final tasks = isFiltering ? filteredTasks.take(20).toList() : filteredTasks.take(5).toList();
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
                bool isProject = t.project_id != null && t.project_id!.isNotEmpty;
                String groupName = t.category;
                if (isProject) {
                  try {
                    groupName = provider.projects.firstWhere((p) => p.project_id == t.project_id).name;
                  } catch (_) {
                    groupName = "Dự án";
                  }
                }

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
                    style: GoogleFonts.nunito(
                      color: isDark ? ghDarkText : ghLightText,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, size: 12, color: isDark ? ghDarkSubText : ghLightSubText),
                        const SizedBox(width: 4),
                        Text(
                          "${t.due_day.day} Thg ${t.due_day.month}, ${t.due_day.year}",
                          style: GoogleFonts.nunito(
                            color: isDark ? ghDarkSubText : ghLightSubText,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          isProject ? Icons.domain : Icons.person,
                          size: 12,
                          color: isProject ? Colors.redAccent : ghBlue,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            groupName,
                            style: GoogleFonts.nunito(
                              color: isProject ? Colors.redAccent : ghBlue,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
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

  Widget _buildMiniCalendar(bool isDark, Color borderColor, TaskProvider provider) {
    final tasksForSelectedDay = provider.tasks.where((t) => _sameDay(t.due_day, _selectedDay)).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? ghDarkCard : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "THÁNG ${_miniMonth.month}/${_miniMonth.year}",
                style: GoogleFonts.nunito(
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
          const SizedBox(height: 16),
          Divider(color: borderColor),
          const SizedBox(height: 8),
          Text(
            "CÔNG VIỆC NGÀY ${_selectedDay.day}/${_selectedDay.month}",
            style: GoogleFonts.nunito(
              fontWeight: FontWeight.bold,
              color: isDark ? ghDarkSubText : ghLightSubText,
              fontSize: 13,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          if (tasksForSelectedDay.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 16),
              child: Center(
                child: Text(
                  "Không có công việc nào",
                  style: GoogleFonts.nunito(
                    color: isDark ? ghDarkSubText : ghLightSubText,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: tasksForSelectedDay.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final t = tasksForSelectedDay[index];
                return InkWell(
                  onTap: () => _openTask(t),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 36,
                        decoration: BoxDecoration(
                          color: t.priority == 3
                              ? Colors.redAccent
                              : (t.priority == 2 ? ghOrange : ghBlue),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.title,
                              style: GoogleFonts.nunito(
                                color: isDark ? ghDarkText : ghLightText,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                decoration: t.status == 'completed' ? TextDecoration.lineThrough : null,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              t.status == 'completed' ? "Đã xong" : (t.status == 'in_progress' ? "Đang làm" : "Đang chờ"),
                              style: GoogleFonts.nunito(
                                color: isDark ? ghDarkSubText : ghLightSubText,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
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
                style: GoogleFonts.nunito(
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
            style: GoogleFonts.nunito(
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
            style: GoogleFonts.nunito(
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
              style: GoogleFonts.nunito(
                color: isDark ? ghDarkSubText : ghLightSubText,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getProjectTimelineShort(Project p) {
    final start = p.startDate;
    final end = p.endDate;
    final fmt = DateFormat('dd/MM/yyyy HH:mm');

    if (start != null && end != null) {
      return "${fmt.format(start)} - ${fmt.format(end)}";
    } else if (start != null) {
      return "Từ: ${fmt.format(start)}";
    } else if (end != null) {
      return "Đến: ${fmt.format(end)}";
    }
    return "";
  }
}
