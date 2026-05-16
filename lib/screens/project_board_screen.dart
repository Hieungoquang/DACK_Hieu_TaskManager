import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class ProjectBoardScreen extends StatefulWidget {
  final Project project;
  const ProjectBoardScreen({super.key, required this.project});

  @override
  State<ProjectBoardScreen> createState() => _ProjectBoardScreenState();
}

class _ProjectBoardScreenState extends State<ProjectBoardScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _filterQuery = "";

  // GitHub Style Colors
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
      bottomNavigationBar: isWeb ? null : MobileBottomNav(currentRoute: 'home'),
      body: Row(
        children: [
          if (isWeb) const WebSidebar(currentRoute: 'home'),
          Expanded(
            child: Consumer<TaskProvider>(
              builder: (context, provider, child) {
                final projectTasks = provider.tasks
                    .where((t) => t.project_id == widget.project.project_id)
                    .where(
                      (t) =>
                          t.title.toLowerCase().contains(
                                _filterQuery.toLowerCase(),
                              ) ||
                          t.category.toLowerCase().contains(
                                _filterQuery.toLowerCase(),
                              ),
                    )
                    .toList();

                final completed =
                    projectTasks.where((t) => t.status == 'completed').toList();

                double progress = projectTasks.isEmpty
                    ? 0
                    : (completed.length / projectTasks.length);

                return Column(
                  children: [
                    _buildGithubHeader(isDark, appProvider, isWeb, progress),
                    _buildSubHeader(isDark, borderColor, textColor, isWeb),
                    Expanded(
                      child: _buildActiveView(
                        projectTasks,
                        isDark,
                        borderColor,
                      ),
                    ),
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
          builder: (_) => AddTaskScreen(
            projectId: widget.project.project_id,
            isDialog: true,
          ),
        ),
        backgroundColor: ghGreen,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildActiveView(
    List<Task> allTasks,
    bool isDark,
    Color borderColor,
  ) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool isWeb = screenWidth > 900;
    return _buildListView(allTasks, isDark, borderColor, isWeb);
  }

  Widget _buildListView(
      List<Task> tasks, bool isDark, Color borderColor, bool isWeb) {
    final textColor = isDark ? ghDarkText : ghLightText;
    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: isWeb ? 30 : 20, vertical: 20),
      itemCount: tasks.length,
      separatorBuilder: (_, __) => Divider(color: borderColor, height: 1),
      itemBuilder: (context, index) {
        final task = tasks[index];
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: isWeb ? 20 : 16,
            vertical: isWeb ? 16 : 12,
          ),
          decoration: BoxDecoration(
            color: isDark ? ghDarkCard : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => TaskDetailScreen(task: task)),
            ),
            leading: GestureDetector(
              onTap: () async {
                final newStatus =
                    task.status == 'completed' ? 'pending' : 'completed';
                task.status = newStatus;
                task.updatedAt = DateTime.now();
                await task.save();
                setState(() {});
              },
              child: Icon(
                task.status == 'completed'
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked,
                color: task.status == 'completed' ? ghGreen : ghDarkSubText,
                size: isWeb ? 26 : 22,
              ),
            ),
            title: Text(
              task.title,
              style: GoogleFonts.nunito(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: isWeb ? 16 : 15,
              ),
            ),
            subtitle: Text(
              "${widget.project.name} #${task.task_id.substring(0, 4)} • ${DateFormat('dd MMM').format(task.due_day)}",
              style: GoogleFonts.nunito(
                color: isDark ? ghDarkSubText : ghLightSubText,
                fontSize: isWeb ? 13 : 12,
              ),
            ),
            trailing: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isWeb ? 12 : 10,
                vertical: isWeb ? 6 : 5,
              ),
              decoration: BoxDecoration(
                color: ghBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: ghBlue.withOpacity(0.3)),
              ),
              child: Text(
                task.category,
                style: GoogleFonts.nunito(
                  color: ghBlue,
                  fontSize: isWeb ? 12 : 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGithubHeader(
    bool isDark,
    AppProvider appProvider,
    bool isWeb,
    double progress,
  ) {
    final textColor = isDark ? ghDarkText : ghLightText;
    final borderColor = isDark ? ghDarkBorder : ghLightBorder;

    return Container(
      padding: EdgeInsets.fromLTRB(
          isWeb ? 30 : 20, isWeb ? 20 : 10, isWeb ? 30 : 20, 0),
      color: isDark ? ghDarkBg : ghLightBg,
      child: Column(
        children: [
          Row(
            children: [
              if (!isWeb)
                IconButton(
                  icon: Icon(Icons.arrow_back, color: textColor, size: 24),
                  onPressed: () => Navigator.pop(context),
                ),
              Icon(
                Icons.table_chart,
                color: isDark ? ghDarkSubText : ghLightSubText,
                size: isWeb ? 24 : 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.project.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.nunito(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: isWeb ? 20 : 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 6,
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: borderColor,
                        color: ghGreen,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubHeader(
      bool isDark, Color borderColor, Color textColor, bool isWeb) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: isWeb ? 30 : 20, vertical: isWeb ? 16 : 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: isWeb ? 44 : 40,
              decoration: BoxDecoration(
                color: isDark ? ghDarkCard : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor, width: 1.5),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _filterQuery = val),
                style: GoogleFonts.nunito(
                    color: textColor, fontSize: isWeb ? 15 : 14),
                decoration: InputDecoration(
                  hintText: "Tìm kiếm công việc...",
                  hintStyle: GoogleFonts.nunito(
                    color: isDark ? ghDarkSubText : ghLightSubText,
                    fontSize: isWeb ? 15 : 14,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    size: isWeb ? 20 : 18,
                    color: isDark ? ghDarkSubText : ghLightSubText,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: isWeb ? 16 : 12,
                    vertical: isWeb ? 12 : 10,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
