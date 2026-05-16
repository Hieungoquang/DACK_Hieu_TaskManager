import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../provider/task_provider.dart';
import '../widgets/web_sidebar.dart';
import 'task_detail_screen.dart';

class TrashScreen extends StatefulWidget {
  const TrashScreen({super.key});

  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final provider = context.watch<TaskProvider>();
    final deletedProjects = provider.deletedProjects;
    final deletedTasks = provider.deletedTasks;
    final bgColor = isDark ? const Color(0xFF0D1117) : const Color(0xFFF6F8FA);
    final cardColor = isDark ? const Color(0xFF161B22) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF30363D) : const Color(0xFFD0D7DE);
    final textColor =
        isDark ? const Color(0xFFC9D1D9) : const Color(0xFF24292F);
    final subTextColor =
        isDark ? const Color(0xFF8B949E) : const Color(0xFF57606A);

    double width = MediaQuery.of(context).size.width;
    bool isWeb = width > 900;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: isWeb
          ? null
          : AppBar(
              backgroundColor: bgColor,
              elevation: 0,
              centerTitle: true,
              title: Text(
                'THÙNG RÁC',
                style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
              ),
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new,
                  color: subTextColor,
                  size: 22,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
      body: Row(
        children: [
          if (isWeb) const WebSidebar(currentRoute: 'trash'),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isWeb ? 40 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isWeb)
                    Text(
                      'THÙNG RÁC',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  if (isWeb) const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 18,
                    ),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Thùng rác cá nhân: ${deletedProjects.length} dự án, ${deletedTasks.length} công việc',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (deletedProjects.isNotEmpty ||
                            deletedTasks.isNotEmpty)
                          ElevatedButton(
                            onPressed: () => _confirmEmptyTrash(provider),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                            ),
                            child: const Text('Xóa hết'),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (deletedProjects.isEmpty && deletedTasks.isEmpty)
                    _buildEmptyState(textColor, subTextColor)
                  else ...[
                    if (deletedProjects.isNotEmpty) ...[
                      Text(
                        'Dự án đã xóa',
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Column(
                        children: deletedProjects
                            .map(
                              (project) => _buildProjectCard(
                                project,
                                provider,
                                cardColor,
                                borderColor,
                                textColor,
                                subTextColor,
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 24),
                    ],
                    if (deletedTasks.isNotEmpty) ...[
                      Text(
                        'Công việc đã xóa',
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Column(
                        children: deletedTasks
                            .map(
                              (task) => _buildTaskCard(
                                task,
                                provider,
                                cardColor,
                                borderColor,
                                textColor,
                                subTextColor,
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(Color textColor, Color subTextColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 80),
        child: Column(
          children: [
            Icon(Icons.delete_outline, size: 80, color: subTextColor),
            const SizedBox(height: 20),
            Text(
              'Thùng rác đang trống',
              style: TextStyle(
                color: textColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Bạn có thể khôi phục hoặc xóa vĩnh viễn các mục ở đây.',
              style: TextStyle(color: subTextColor, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectCard(
    project,
    TaskProvider provider,
    Color cardColor,
    Color borderColor,
    Color textColor,
    Color subTextColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  project.name,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  project.description.isNotEmpty
                      ? project.description
                      : 'Không có mô tả',
                  style: TextStyle(color: subTextColor, fontSize: 13),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => provider.restoreProject(project.project_id),
            child: const Text('Khôi phục'),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () =>
                _confirmPermanentProjectDelete(provider, project.project_id),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Xóa vĩnh viễn'),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(
    task,
    TaskProvider provider,
    Color cardColor,
    Color borderColor,
    Color textColor,
    Color subTextColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  DateFormat('dd MMM yyyy').format(task.due_day),
                  style: TextStyle(color: subTextColor, fontSize: 13),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              if (task.project_id != null && task.project_id!.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TaskDetailScreen(task: task),
                  ),
                );
              }
            },
            icon: Icon(Icons.open_in_new, color: subTextColor),
          ),
          TextButton(
            onPressed: () => provider.restoreTask(task.task_id),
            child: const Text('Khôi phục'),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () =>
                _confirmPermanentTaskDelete(provider, task.task_id),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Xóa vĩnh viễn'),
          ),
        ],
      ),
    );
  }

  void _confirmEmptyTrash(TaskProvider provider) {
    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF161B22) : Colors.white,
          title: Text(
            'Xóa hết thùng rác',
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
          ),
          content: Text(
            'Bạn có chắc chắn muốn xóa tất cả mục trong thùng rác không? Hành động này không thể hoàn tác.',
            style: TextStyle(
              color: isDark ? const Color(0xFF8B949E) : const Color(0xFF57606A),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('HỦY'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                final deletedProjects = provider.deletedProjects.toList();
                final deletedTasks = provider.deletedTasks.toList();
                for (var project in deletedProjects) {
                  await provider.permanentlyDeleteProject(project.project_id);
                }
                for (var task in deletedTasks) {
                  if (!deletedProjects.any(
                    (p) => p.project_id == task.project_id,
                  )) {
                    await provider.permanentlyDeleteTask(task.task_id);
                  }
                }
              },
              style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
              child: const Text('XÓA HẾT'),
            ),
          ],
        );
      },
    );
  }

  void _confirmPermanentProjectDelete(TaskProvider provider, String projectId) {
    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF161B22) : Colors.white,
          title: Text(
            'Xóa vĩnh viễn dự án',
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
          ),
          content: Text(
            'Hành động này sẽ xóa hoàn toàn dự án và tất cả công việc liên quan. Bạn có chắc không?',
            style: TextStyle(
              color: isDark ? const Color(0xFF8B949E) : const Color(0xFF57606A),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('HỦY'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await provider.permanentlyDeleteProject(projectId);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
              child: const Text('XÓA'),
            ),
          ],
        );
      },
    );
  }

  void _confirmPermanentTaskDelete(TaskProvider provider, String taskId) {
    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF161B22) : Colors.white,
          title: Text(
            'Xóa vĩnh viễn công việc',
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
          ),
          content: Text(
            'Hành động này sẽ xóa hoàn toàn công việc và tất cả dữ liệu liên quan. Bạn có chắc không?',
            style: TextStyle(
              color: isDark ? const Color(0xFF8B949E) : const Color(0xFF57606A),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('HỦY'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await provider.permanentlyDeleteTask(taskId);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
              child: const Text('XÓA'),
            ),
          ],
        );
      },
    );
  }
}
