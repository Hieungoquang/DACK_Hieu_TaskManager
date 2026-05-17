import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/project_model.dart';
import '../models/task_model.dart';
import '../provider/task_provider.dart';
import '../provider/app_provider.dart';
import '../widgets/web_sidebar.dart';
import '../widgets/mobile_bottom_nav.dart';
import 'add_task_screen.dart';
import 'task_detail_screen.dart';
import 'add_project_screen.dart';

class ProjectBoardScreen extends StatefulWidget {
  final Project project;
  const ProjectBoardScreen({super.key, required this.project});

  @override
  State<ProjectBoardScreen> createState() => _ProjectBoardScreenState();
}

class _ProjectBoardScreenState extends State<ProjectBoardScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _filterQuery = "";

  static const Color ghDarkBg = Color(0xFF0D1117);
  static const Color ghDarkCard = Color(0xFF161B22);
  static const Color ghDarkBorder = Color(0xFF30363D);
  static const Color ghDarkText = Color(0xFFC9D1D9);
  static const Color ghDarkSubText = Color(0xFF8B949E);

  static const Color ghLightBg = Color(0xFFF6F8FA);
  static const Color ghLightBorder = Color(0xFFD0D7DE);
  static const Color ghLightText = Color(0xFF24292F);
  static const Color ghLightSubText = Color(0xFF57606A);

  static const Color ghBlue = Color(0xFF58A6FF);
  static const Color ghGreen = Color(0xFF3FB950);

  void _confirmDeleteProject(bool isDark, Color textColor, Color borderColor) {
    final bgColor = isDark ? ghDarkCard : Colors.white;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: bgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "Xóa dự án?",
                style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 17, color: textColor),
              ),
            ),
          ],
        ),
        content: RichText(
          text: TextSpan(
            style: GoogleFonts.nunito(color: textColor, fontSize: 14, height: 1.6),
            children: [
              const TextSpan(text: "Dự án "),
              TextSpan(
                text: '"${widget.project.name}"',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent),
              ),
              const TextSpan(
                text: " và tất cả công việc bên trong sẽ bị chuyển vào thùng rác.\n\nBạn có chắc chắn muốn xóa?",
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              "Hủy",
              style: GoogleFonts.nunito(
                color: isDark ? ghDarkSubText : ghLightSubText,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final provider = context.read<TaskProvider>();
              await provider.deleteProject(widget.project.project_id);
              if (mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text("Xóa dự án", style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final isDark = appProvider.themeMode == ThemeMode.dark;

    final bgColor = isDark ? ghDarkBg : ghLightBg;
    final textColor = isDark ? ghDarkText : ghLightText;
    final borderColor = isDark ? ghDarkBorder : ghLightBorder;

    double screenWidth = MediaQuery.of(context).size.width;
    bool isWeb = screenWidth > 900;

    return Scaffold(
      backgroundColor: bgColor,
      bottomNavigationBar: isWeb ? null : const MobileBottomNav(currentRoute: 'home'),
      body: Row(
        children: [
          if (isWeb) const WebSidebar(currentRoute: 'home'),
          Expanded(
            child: Consumer<TaskProvider>(
              builder: (context, provider, child) {
                final projectTasks = provider.tasks
                    .where((t) => t.project_id == widget.project.project_id)
                    .where((t) => t.title.toLowerCase().contains(_filterQuery.toLowerCase()))
                    .toList();

                return Column(
                  children: [
                    _buildHeader(isDark, textColor, borderColor, isWeb),
                    _buildCrisisAlerts(projectTasks, provider, isDark, borderColor, isWeb),
                    _buildSubHeader(isDark, borderColor, textColor, isWeb),
                    Expanded(child: _buildMainView(projectTasks, isDark, borderColor, isWeb)),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showDialog(
          context: context,
          builder: (_) => AddTaskScreen(projectId: widget.project.project_id, isDialog: true),
        ),
        backgroundColor: ghGreen,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildHeader(bool isDark, Color textColor, Color borderColor, bool isWeb) {
    final subColor = isDark ? ghDarkSubText : ghLightSubText;
    return Container(
      padding: EdgeInsets.fromLTRB(isWeb ? 30 : 16, isWeb ? 24 : 16, isWeb ? 30 : 16, 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D1117) : const Color(0xFFF6F8FA),
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (!isWeb) IconButton(
                    icon: Icon(Icons.arrow_back, color: textColor),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Icon(Icons.folder_shared_rounded, color: ghBlue, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.project.name.toUpperCase(),
                      style: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.bold, color: textColor, letterSpacing: 0.5),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.settings_outlined, size: 22, color: subColor),
                    tooltip: "Chỉnh sửa dự án",
                    onPressed: () => showDialog(
                      context: context,
                      builder: (_) => AddProjectScreen(project: widget.project),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 22, color: Colors.redAccent),
                    tooltip: "Xóa dự án",
                    onPressed: () => _confirmDeleteProject(isDark, textColor, borderColor),
                  ),
                ],
              ),
              if (widget.project.startDate != null || widget.project.endDate != null) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 40),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 14, color: subColor),
                      const SizedBox(width: 6),
                      Text(
                        _getProjectTimelineString(),
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: subColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (widget.project.description.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 12, left: 40),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: borderColor.withOpacity(0.5)),
                  ),
                  child: Text(
                    widget.project.description,
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      color: subColor,
                      height: 1.6,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubHeader(bool isDark, Color borderColor, Color textColor, bool isWeb) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isWeb ? 30 : 16, vertical: 14),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: borderColor))),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDark ? ghDarkCard : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: borderColor, width: 1.2),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _filterQuery = val),
                    style: GoogleFonts.nunito(color: textColor, fontSize: 15),
                    decoration: InputDecoration(
                      hintText: "Tìm kiếm nhiệm vụ...",
                      hintStyle: GoogleFonts.nunito(color: isDark ? ghDarkSubText : ghLightSubText, fontSize: 15),
                      prefixIcon: Icon(Icons.search_rounded, size: 22, color: isDark ? ghDarkSubText : ghLightSubText),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 11),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainView(List<Task> tasks, bool isDark, Color borderColor, bool isWeb) {
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_turned_in_outlined, size: 60, color: isDark ? ghDarkSubText.withOpacity(0.3) : ghLightSubText.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text("Dự án chưa có công việc", style: GoogleFonts.nunito(color: isDark ? ghDarkSubText : ghLightSubText, fontSize: 16)),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: isWeb ? 30 : 16, vertical: 20),
      itemCount: tasks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final task = tasks[index];
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: _buildTaskItem(task, isDark, borderColor, isWeb),
          ),
        );
      },
    );
  }

  Widget _buildTaskItem(Task task, bool isDark, Color borderColor, bool isWeb) {
    final textColor = isDark ? ghDarkText : ghLightText;
    final subColor = isDark ? ghDarkSubText : ghLightSubText;
    final provider = Provider.of<TaskProvider>(context, listen: false);
    final isLocked = provider.isTaskLocked(task);
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? ghDarkCard : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Opacity(
        opacity: isLocked ? 0.65 : 1.0,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TaskDetailScreen(task: task))),
          leading: IconButton(
            icon: Icon(
              isLocked
                  ? Icons.lock_outline_rounded
                  : (task.status == 'completed' ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded),
              color: isLocked
                  ? Colors.redAccent
                  : (task.status == 'completed' ? ghGreen : subColor),
              size: 26,
            ),
            onPressed: () async {
              if (isLocked) {
                _showLockWarning(task);
                return;
              }
              task.status = task.status == 'completed' ? 'pending' : 'completed';
              task.updatedAt = DateTime.now();
              await provider.updateTask(task);
              setState(() {});
            },
          ),
          title: Text(
            task.title,
            style: GoogleFonts.nunito(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textColor,
              decoration: task.status == 'completed' ? TextDecoration.lineThrough : null,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Icon(Icons.access_time_rounded, size: 14, color: subColor),
                const SizedBox(width: 4),
                Text(
                  DateFormat('dd/MM HH:mm').format(task.due_day),
                  style: GoogleFonts.nunito(fontSize: 13, color: subColor),
                ),
              ],
            ),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: ghBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: ghBlue.withOpacity(0.2)),
            ),
            child: Text(
              task.category,
              style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.bold, color: ghBlue),
            ),
          ),
        ),
      ),
    );
  }

  void _showLockWarning(Task task) {
    final provider = Provider.of<TaskProvider>(context, listen: false);
    final prereq = provider.getPrerequisiteTask(task);
    final isDark = Provider.of<AppProvider>(context, listen: false).themeMode == ThemeMode.dark;
    final bgColor = isDark ? ghDarkCard : Colors.white;
    final textColor = isDark ? ghDarkText : ghLightText;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: bgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.lock, color: Colors.redAccent),
            const SizedBox(width: 8),
            Text("Nhiệm vụ đang bị khóa", style: GoogleFonts.nunito(fontWeight: FontWeight.bold, color: textColor)),
          ],
        ),
        content: RichText(
          text: TextSpan(
            style: GoogleFonts.nunito(color: textColor, fontSize: 14, height: 1.5),
            children: [
              const TextSpan(text: "Bạn chưa thể hoàn thành "),
              TextSpan(text: '"${task.title}"', style: const TextStyle(fontWeight: FontWeight.bold)),
              const TextSpan(text: " vì nó phụ thuộc vào công việc tiên quyết chưa hoàn thành:\n\n"),
              TextSpan(
                text: '• ${prereq?.title ?? "Công việc tiên quyết"}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Đã hiểu", style: GoogleFonts.nunito(color: ghBlue, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildCrisisAlerts(List<Task> projectTasks, TaskProvider provider, bool isDark, Color borderColor, bool isWeb) {
    final crisisTasks = projectTasks.where((t) => provider.crisisTasks.any((ct) => ct.task_id == t.task_id)).toList();
    if (crisisTasks.isEmpty) return const SizedBox.shrink();

    final textColor = isDark ? ghDarkText : ghLightText;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: isWeb ? 30 : 16, vertical: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.redAccent.withValues(alpha: isDark ? 0.1 : 0.05),
            border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4), width: 1.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    "CẢNH BÁO KHỦNG HOẢNG DEADLINE DỰ ÁN",
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.redAccent,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Column(
                children: crisisTasks.map((t) {
                  final prob = provider.crisisProbabilities[t.task_id] ?? 0.0;
                  final percent = (prob * 100).toInt();
                  return Card(
                    color: isDark ? ghDarkCard : Colors.white,
                    margin: const EdgeInsets.only(bottom: 8),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: borderColor.withOpacity(0.5)),
                    ),
                    child: ListTile(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TaskDetailScreen(task: t))),
                      leading: const Icon(Icons.timer_off, color: Colors.redAccent, size: 20),
                      title: Text(
                        t.title,
                        style: GoogleFonts.nunito(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      subtitle: Text(
                        "Nguy cơ trễ hạn: $percent%",
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      trailing: const Icon(Icons.chevron_right, size: 16, color: Colors.redAccent),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getProjectTimelineString() {
    final start = widget.project.startDate;
    final end = widget.project.endDate;
    final fmt = DateFormat('dd/MM/yyyy HH:mm');

    if (start != null && end != null) {
      return "Thời gian: ${fmt.format(start)} - ${fmt.format(end)}";
    } else if (start != null) {
      return "Bắt đầu từ: ${fmt.format(start)}";
    } else if (end != null) {
      return "Kết thúc trước: ${fmt.format(end)}";
    }
    return "";
  }
}
