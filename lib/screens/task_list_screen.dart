import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/task_provider.dart';
import '../widgets/web_sidebar.dart';
import '../widgets/quick_edit_task_dialog.dart';
import 'task_detail_screen.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  _TaskListScreenState createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final Color duoGreen = const Color(0xFF58CC02);
  final Color duoBlue = const Color(0xFF1CB0F6);
  final Color duoGray = const Color(0xFFE5E5E5);
  final Color duoText = const Color(0xFF1F1F1F);
  final Color duoSecondaryText = const Color(0xFF4B4B4B);

  String _searchQuery = '';
  int? _selectedPriority; // null = Tất cả, 1 = Thấp, 2 = Vừa, 3 = Cao

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final scaffoldBg = isDark ? const Color(0xFF121212) : Colors.white;
    final textColor = isDark ? Colors.white : duoText;
    final labelColor =
        isDark ? Colors.white.withOpacity(0.7) : duoSecondaryText;

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
                "NHIỆM VỤ",
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  letterSpacing: 1.5,
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
          if (isWeb) const WebSidebar(currentRoute: 'tasks'),
          Expanded(
            child: Consumer<TaskProvider>(
              builder: (context, taskProvider, child) {
                final filteredTasks = taskProvider.tasks.where((t) {
                  final matchesSearch = t.title.toLowerCase().contains(_searchQuery.toLowerCase());
                  final matchesPriority = _selectedPriority == null || t.priority == _selectedPriority;
                  return matchesSearch && matchesPriority;
                }).toList();

                return Column(
                  children: [
                    if (isWeb) ...[
                      Padding(
                        padding: const EdgeInsets.only(
                          top: 30,
                          left: 40,
                          bottom: 10,
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "DANH SÁCH NHIỆM VỤ",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: textColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                    _buildSearchAndFilter(isDark, textColor, labelColor, isWeb),
                    if (filteredTasks.isEmpty)
                      Expanded(child: _buildEmptyState(labelColor))
                    else
                      Expanded(
                        child: ListView.builder(
                          padding: EdgeInsets.symmetric(
                            horizontal: isWeb ? 40 : 20,
                            vertical: 10,
                          ),
                          itemCount: filteredTasks.length,
                          itemBuilder: (context, index) {
                            final task = filteredTasks[index];
                            return Center(
                              child: Container(
                                constraints: const BoxConstraints(maxWidth: 800),
                                child: _buildTaskCard(
                                  context,
                                  task,
                                  taskProvider,
                                  isDark,
                                  textColor,
                                  labelColor,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(
    BuildContext context,
    task,
    taskProvider,
    bool isDark,
    Color textColor,
    Color labelColor,
  ) {
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderColor = isDark ? const Color(0xFF37464F) : duoGray;

    return GestureDetector(
      onTap: () => _openTask(context, task),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(15),
          border: Border(
            top: BorderSide(color: borderColor, width: 2),
            left: BorderSide(color: borderColor, width: 2),
            right: BorderSide(color: borderColor, width: 2),
            bottom: BorderSide(color: borderColor, width: 5), // Đổ bóng 3D
          ),
        ),
        child: Row(
          children: [
            // Checkbox tùy chỉnh
            GestureDetector(
              onTap: () {
                taskProvider.updateProgress(
                  task,
                  task.progress == 100 ? 0 : 100,
                );
              },
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: task.progress == 100 ? duoGreen : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: task.progress == 100
                        ? duoGreen
                        : labelColor.withOpacity(0.3),
                    width: 2.5,
                  ),
                ),
                child: task.progress == 100
                    ? const Icon(Icons.check, color: Colors.white, size: 18)
                    : null,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: task.progress == 100
                          ? labelColor.withOpacity(0.5)
                          : textColor,
                      decoration: task.progress == 100
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Thanh tiến độ nhỏ
                  ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: LinearProgressIndicator(
                      value: task.progress / 100,
                      backgroundColor: duoGray.withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation(duoGreen),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: labelColor),
              onSelected: (val) async {
                if (val == 'trash') {
                  await taskProvider.deleteTask(task.task_id);
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'trash',
                  child: Text('Di chuyển vào thùng rác'),
                ),
              ],
            ),
            Icon(Icons.chevron_right_rounded, color: labelColor),
          ],
        ),
      ),
    );
  }

  void _openTask(BuildContext context, task) {
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

  Widget _buildEmptyState(Color labelColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 15),
          Text(
            "KHÔNG CÓ CÔNG VIỆC NÀO",
            style: TextStyle(
              color: labelColor,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            "Chưa có công việc nào phù hợp với tìm kiếm của bạn.",
            style: TextStyle(
              color: labelColor.withOpacity(0.7),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter(bool isDark, Color textColor, Color labelColor, bool isWeb) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isWeb ? 40 : 20, vertical: 10),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thanh tìm kiếm
              Container(
                height: 46,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? const Color(0xFF37464F) : duoGray, width: 2),
                ),
                child: TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    hintText: "Tìm kiếm nhiệm vụ...",
                    hintStyle: TextStyle(color: labelColor.withOpacity(0.5), fontWeight: FontWeight.bold),
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
                    _priorityChip("Tất cả", null, isDark, textColor),
                    const SizedBox(width: 8),
                    _priorityChip("Cao", 3, isDark, Colors.redAccent),
                    const SizedBox(width: 8),
                    _priorityChip("Vừa", 2, isDark, Colors.orange),
                    const SizedBox(width: 8),
                    _priorityChip("Thấp", 1, isDark, Colors.blue),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _priorityChip(String label, int? value, bool isDark, Color baseColor) {
    final isSelected = _selectedPriority == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedPriority = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? baseColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? baseColor : (isDark ? const Color(0xFF37464F) : duoGray),
            width: 2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? baseColor : (isDark ? Colors.white70 : duoSecondaryText),
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
