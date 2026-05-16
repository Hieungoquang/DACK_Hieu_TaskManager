import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:task_manager/services/email_service.dart';
import '../models/project_model.dart';
import '../models/task_model.dart';
import '../provider/task_provider.dart';
import '../provider/app_provider.dart';
import '../widgets/web_sidebar.dart';
import '../widgets/mobile_bottom_nav.dart';
import 'add_task_screen.dart';
import 'task_detail_screen.dart';
import '../widgets/app_popup.dart';

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
  static const Color ghLightCard = Color(0xFFFFFFFF);
  static const Color ghLightBorder = Color(0xFFD0D7DE);
  static const Color ghLightText = Color(0xFF24292F);
  static const Color ghLightSubText = Color(0xFF57606A);

  static const Color ghBlue = Color(0xFF58A6FF);
  static const Color ghGreen = Color(0xFF3FB950);
  static const Color ghOrange = Color(0xFFD29922);
  static const Color ghPurple = Color(0xFFA371F7);

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
                    _buildSubHeader(isDark, borderColor, textColor),
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
    return _buildListView(allTasks, isDark, borderColor);
  }

  Widget _buildListView(List<Task> tasks, bool isDark, Color borderColor) {
    final textColor = isDark ? ghDarkText : ghLightText;
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: tasks.length,
      separatorBuilder: (_, __) => Divider(color: borderColor, height: 1),
      itemBuilder: (context, index) {
        final task = tasks[index];
        return ListTile(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => TaskDetailScreen(task: task)),
          ),
          leading: Icon(
            task.status == 'completed'
                ? Icons.check_circle
                : (task.status == 'in_progress'
                    ? Icons.timelapse
                    : Icons.radio_button_unchecked),
            color: task.status == 'completed'
                ? ghPurple
                : (task.status == 'in_progress' ? ghOrange : ghDarkSubText),
            size: 22,
          ),
          title: Text(
            task.title,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          subtitle: Text(
            "${widget.project.name} #${task.task_id.substring(0, 4)} • ${DateFormat('dd MMM').format(task.due_day)}",
            style: TextStyle(
              color: isDark ? ghDarkSubText : ghLightSubText,
              fontSize: 13,
            ),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: ghBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              task.category,
              style: const TextStyle(
                color: ghBlue,
                fontSize: 11,
                fontWeight: FontWeight.bold,
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
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
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
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.project.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: isWeb ? 18 : 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 5,
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: borderColor,
                        color: ghGreen,
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  color: Colors.redAccent,
                  size: isWeb ? 24 : 22,
                ),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                onPressed: () => _confirmTrashProject(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubHeader(bool isDark, Color borderColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 38,
              decoration: BoxDecoration(
                color: isDark ? ghDarkCard : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: borderColor),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _filterQuery = val),
                style: TextStyle(color: textColor, fontSize: 15),
                decoration: InputDecoration(
                  hintText: "Lọc theo từ khóa hoặc danh mục",
                  hintStyle: TextStyle(
                    color: isDark ? ghDarkSubText : ghLightSubText,
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    size: 18,
                    color: isDark ? ghDarkSubText : ghLightSubText,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.only(bottom: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmTrashProject() {
    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? ghDarkCard : Colors.white,
          title: Text(
            "Xóa dự án",
            style: TextStyle(
              color: isDark ? ghDarkText : ghLightText,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            "Bạn có muốn di chuyển dự án này vào thùng rác?",
            style: TextStyle(color: isDark ? ghDarkSubText : ghLightSubText),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("HỦY", style: TextStyle(color: ghBlue)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                final provider = Provider.of<TaskProvider>(
                  this.context,
                  listen: false,
                );
                await provider.deleteProject(widget.project.project_id);
                if (mounted) Navigator.pop(context);
              },
              child: Text(
                "DI CHUYỂN",
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMembersList(bool isDark, Color textColor) {
    return Row(
      children: [
        if (widget.project.memberIds.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF21262D) : const Color(0xFFF6F8FA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? ghDarkBorder : ghLightBorder),
            ),
            child: Row(
              children: [
                Icon(Icons.group, size: 14, color: textColor),
                const SizedBox(width: 4),
                Text(
                  "${widget.project.memberIds.length} TV",
                  style: TextStyle(
                    color: textColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(width: 8),
        IconButton(
          icon: Icon(Icons.person_add_alt_1, color: ghBlue, size: 20),
          onPressed: () => _showAddMemberDialog(isDark),
          tooltip: "Thêm thành viên",
        ),
      ],
    );
  }

  void _showAddMemberDialog(bool isDark) {
    TextEditingController emailController = TextEditingController();
    bool isLoading = false;
    Map<String, dynamic>? foundUser;
    String? errorMessage;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: isDark ? ghDarkCard : ghLightCard,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: isDark ? ghDarkBorder : ghLightBorder),
            ),
            title: Text(
              "Thêm thành viên",
              style: TextStyle(
                color: isDark ? ghDarkText : ghLightText,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: emailController,
                    style: TextStyle(color: isDark ? ghDarkText : ghLightText),
                    decoration: InputDecoration(
                      hintText: "Nhập email người dùng...",
                      hintStyle: TextStyle(
                        color: isDark ? ghDarkSubText : ghLightSubText,
                      ),
                      filled: true,
                      fillColor: isDark ? ghDarkBg : ghLightBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.search, color: ghBlue),
                        onPressed: () async {
                          if (emailController.text.trim().isEmpty) return;
                          setDialogState(() {
                            isLoading = true;
                            errorMessage = null;
                            foundUser = null;
                          });

                          try {
                            final query = await FirebaseFirestore.instance
                                .collection('users')
                                .where(
                                  'email',
                                  isEqualTo: emailController.text.trim(),
                                )
                                .limit(1)
                                .get();

                            if (query.docs.isNotEmpty) {
                              final doc = query.docs.first;
                              if (doc.id ==
                                  FirebaseAuth.instance.currentUser?.uid) {
                                errorMessage = "Bạn không thể thêm chính mình.";
                              } else if (widget.project.memberIds.contains(
                                doc.id,
                              )) {
                                errorMessage = "Người này đã là thành viên.";
                              } else {
                                foundUser = {'uid': doc.id, ...doc.data()};
                              }
                            } else {
                              errorMessage = "Không tìm thấy người dùng này.";
                            }
                          } catch (e) {
                            errorMessage = "Lỗi tìm kiếm: \$e";
                          }

                          setDialogState(() {
                            isLoading = false;
                          });
                        },
                      ),
                    ),
                  ),
                  if (isLoading)
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        errorMessage!,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    )
                  else if (foundUser != null)
                    ListTile(
                      contentPadding: const EdgeInsets.only(top: 16),
                      leading: CircleAvatar(
                        backgroundColor: ghBlue.withOpacity(0.2),
                        backgroundImage: foundUser!['avatar_url'] != null
                            ? NetworkImage(foundUser!['avatar_url'])
                            : null,
                        child: foundUser!['avatar_url'] == null
                            ? const Icon(Icons.person, color: ghBlue)
                            : null,
                      ),
                      title: Text(
                        foundUser!['full_name'] ??
                            foundUser!['username'] ??
                            'User',
                        style: TextStyle(
                          color: isDark ? ghDarkText : ghLightText,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        foundUser!['email'],
                        style: TextStyle(
                          color: isDark ? ghDarkSubText : ghLightSubText,
                          fontSize: 12,
                        ),
                      ),
                      trailing: ElevatedButton(
                        onPressed: () async {
                          setState(() {
                            widget.project.memberIds.add(foundUser!['uid']);
                            widget.project.memberStatuses = {
                              ...?widget.project.memberStatuses,
                              foundUser!['uid']: 'pending',
                            };
                          });
                          await widget.project.save();

                          await FirebaseFirestore.instance
                              .collection('projects')
                              .doc(widget.project.project_id)
                              .set({
                            'project_id': widget.project.project_id,
                            'user_id': widget.project.user_id,
                            'name': widget.project.name,
                            'description': widget.project.description,
                            'colorValue': widget.project.colorValue,
                            'createdAt':
                                widget.project.createdAt.toIso8601String(),
                            'updatedAt': DateTime.now().toIso8601String(),
                            'memberIds': widget.project.memberIds,
                            'memberStatuses': widget.project.memberStatuses,
                          });

                          // Gửi thông báo Cloud
                          final currentUser = FirebaseAuth.instance.currentUser;
                          final taskProvider = Provider.of<TaskProvider>(
                            context,
                            listen: false,
                          );
                          await taskProvider.sendCloudNotification(
                            targetUserId: foundUser!['uid'],
                            title: '📂 Lời mời vào dự án',
                            message:
                                '${currentUser?.displayName ?? "Một người dùng"} đã thêm bạn vào dự án "${widget.project.name}"',
                            type: 'project_invitation',
                            taskId: widget.project.project_id,
                          );

                          // Gửi mail thông báo
                          final emailSuccess =
                              await EmailService.sendProjectInvitation(
                            recipientEmail: foundUser!['email'],
                            projectName: widget.project.name,
                            inviterName: currentUser?.displayName ??
                                currentUser?.email ??
                                'Người quản lý',
                            inviteLink: EmailService.buildProjectInvitationLink(
                              projectId: widget.project.project_id,
                              inviteeId: foundUser!['uid'],
                            ),
                          );

                          if (mounted) {
                            Navigator.pop(context);
                            if (emailSuccess) {
                              AppPopup.success(
                                context,
                                "Đã thêm thành viên và gửi email mời thành công!",
                              );
                            } else {
                              AppPopup.error(
                                context,
                                "Đã thêm thành viên nhưng không thể gửi email. Kiểm tra console để xem chi tiết.",
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ghGreen,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text(
                          "Thêm",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  "ĐÓNG",
                  style: TextStyle(
                    color: isDark ? ghDarkSubText : ghLightSubText,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
