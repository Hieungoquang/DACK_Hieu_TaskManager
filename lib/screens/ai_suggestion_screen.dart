import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/task_model.dart';
import '../provider/task_provider.dart';
import '../services/ai_service.dart';
import '../widgets/web_sidebar.dart';
import '../widgets/mobile_bottom_nav.dart';
import '../widgets/app_popup.dart';
import 'home_screen.dart';

class AiSuggestionScreen extends StatefulWidget {
  const AiSuggestionScreen({super.key});

  @override
  State<AiSuggestionScreen> createState() => _AiSuggestionScreenState();
}

class _AiSuggestionScreenState extends State<AiSuggestionScreen> {
  final TextEditingController _taskController = TextEditingController();
  List<String> _suggestedSubtasks = [];
  bool _isLoading = false;
  bool _isSaving = false;

  final Color duoPurple = const Color(0xFFCE82FF);
  final Color duoPurpleDark = const Color(0xFFA55EEA);
  final Color duoGreen = const Color(0xFF58CC02);
  final Color duoGreenDark = const Color(0xFF46A302);
  final Color duoGray = const Color(0xFFE5E5E5);
  final Color duoText = const Color(0xFF1F1F1F);
  final Color duoSecondaryText = const Color(0xFF4B4B4B);

  void _getAiSuggestions() async {
    final title = _taskController.text.trim();
    if (title.isEmpty || _isLoading) return;

    setState(() {
      _isLoading = true;
      _suggestedSubtasks = [];
    });

    try {
      final suggestions = await AiService.generateSubtasks(title);
      if (!mounted) return;

      setState(() {
        _suggestedSubtasks = suggestions;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppPopup.error(context, "Lỗi kết nối AI, vui lòng thử lại!");
      }
    }
  }

  void _addTasksToSystem() async {
    if (_isSaving) return;

    final mainTitle = _taskController.text.trim();
    if (mainTitle.isEmpty) return;

    setState(() => _isSaving = true);

    try {
      final taskProvider = context.read<TaskProvider>();
      final user = FirebaseAuth.instance.currentUser;
      final userId = user?.uid ?? "guest_user";

      final mainTaskId = const Uuid().v4();
      final mainTask = Task(
        task_id: mainTaskId,
        user_id: userId,
        title: mainTitle,
        description: "Được gợi ý bởi AI",
        due_day: DateTime.now().add(const Duration(days: 1)),
        priority: 2,
        progress: 0,
        duration: 60,
        deadline: DateTime.now().add(const Duration(days: 1)),
        status: 'pending',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        category: 'Công việc',
      );

      // 1. Thêm Task chính
      await taskProvider.addTask(mainTask);

      // 2. Thêm các Subtasks
      for (var subTitle in _suggestedSubtasks) {
        await taskProvider.addSubtask(mainTaskId, subTitle);
      }

      // 3. 🔔 HIỂN THỊ THÔNG BÁO AI
      await taskProvider.notifyAISuggestion(mainTitle);

      if (mounted) {
        AppPopup.success(context, "Đã thêm lộ trình AI vào danh sách!");

        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) _handleBackNavigation();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        AppPopup.error(context, "Lỗi khi lưu: $e");
      }
    }
  }

  void _handleBackNavigation() {
    if (!mounted) return;
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : duoText;
    final labelColor =
        isDark ? Colors.white.withOpacity(0.7) : duoSecondaryText;
    final inputBg = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF7F7F7);
    final borderColor = isDark ? const Color(0xFF37464F) : duoGray;

    double width = MediaQuery.of(context).size.width;
    bool isWeb = width > 900;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: isWeb
          ? null
          : AppBar(
              backgroundColor: theme.scaffoldBackgroundColor,
              elevation: 0,
              leading: IconButton(
                icon: Icon(Icons.close, color: labelColor, size: 28),
                onPressed: _handleBackNavigation,
              ),
              title: Text(
                "AI TRỢ LÝ",
                style: TextStyle(
                  color: duoPurpleDark,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  letterSpacing: 1.2,
                ),
              ),
              centerTitle: true,
            ),
      bottomNavigationBar: isWeb ? null : MobileBottomNav(currentRoute: 'ai'),
      body: Row(
        children: [
          if (isWeb) const WebSidebar(currentRoute: 'ai'),
          Expanded(
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Column(
                  children: [
                    Expanded(
                      child: isWeb
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: SingleChildScrollView(
                                    padding: const EdgeInsets.all(40),
                                    child: _buildInputSection(
                                      inputBg,
                                      borderColor,
                                      isDark,
                                      textColor,
                                      labelColor,
                                      isWeb,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: _buildResultSection(
                                    isDark,
                                    borderColor,
                                    textColor,
                                    labelColor,
                                    isWeb,
                                  ),
                                ),
                              ],
                            )
                          : SingleChildScrollView(
                              padding: const EdgeInsets.all(25.0),
                              child: Column(
                                children: [
                                  _buildInputSection(
                                    inputBg,
                                    borderColor,
                                    isDark,
                                    textColor,
                                    labelColor,
                                    isWeb,
                                  ),
                                  const SizedBox(height: 30),
                                  _buildResultSection(
                                    isDark,
                                    borderColor,
                                    textColor,
                                    labelColor,
                                    isWeb,
                                  ),
                                ],
                              ),
                            ),
                    ),
                    if (_suggestedSubtasks.isNotEmpty)
                      _buildBottomAction(isWeb, isDark, borderColor),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputSection(
    Color inputBg,
    Color borderColor,
    bool isDark,
    Color textColor,
    Color labelColor,
    bool isWeb,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isWeb) ...[
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back_ios, color: labelColor),
                onPressed: _handleBackNavigation,
              ),
              Text(
                "AI TRỢ LÝ",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
        ],
        Text(
          "MÌNH GIÚP GÌ ĐƯỢC BẠN NHỈ?",
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: labelColor,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          "Nhập mục tiêu để mình chia nhỏ công việc giúp bạn!",
          style: TextStyle(
            fontSize: isWeb ? 24 : 22,
            fontWeight: FontWeight.w900,
            color: textColor,
          ),
        ),
        const SizedBox(height: 30),
        _buildDuoTextField(inputBg, borderColor, isDark, textColor, labelColor),
      ],
    );
  }

  Widget _buildResultSection(
    bool isDark,
    Color borderColor,
    Color textColor,
    Color labelColor,
    bool isWeb,
  ) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: duoPurple, strokeWidth: 5),
            const SizedBox(height: 20),
            Text(
              "ĐANG PHÙ PHÉP...",
              style: TextStyle(
                color: duoPurpleDark,
                fontWeight: FontWeight.w900,
                fontSize: 14,
                letterSpacing: 1.1,
              ),
            ),
          ],
        ),
      );
    }

    if (_suggestedSubtasks.isEmpty) {
      return isWeb
          ? _buildEmptyStateWeb(labelColor)
          : _buildEmptyStateMobile(labelColor);
    }

    return Container(
      padding: EdgeInsets.all(isWeb ? 40 : 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "LỘ TRÌNH ĐỀ XUẤT:",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: duoPurpleDark,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 15),
          ..._suggestedSubtasks
              .map(
                (subtask) => _buildSuggestionCard(
                  subtask,
                  isDark,
                  borderColor,
                  textColor,
                ),
              )
              .toList(),
        ],
      ),
    );
  }

  Widget _buildDuoTextField(
    Color inputBg,
    Color borderColor,
    bool isDark,
    Color textColor,
    Color labelColor,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: inputBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 2),
      ),
      child: TextField(
        controller: _taskController,
        onSubmitted: (_) => _getAiSuggestions(),
        style: TextStyle(fontWeight: FontWeight.w900, color: textColor),
        decoration: InputDecoration(
          hintText: "Ví dụ: Học lập trình Flutter...",
          hintStyle: TextStyle(
            color: labelColor.withOpacity(0.5),
            fontWeight: FontWeight.bold,
          ),
          contentPadding: const EdgeInsets.all(20),
          border: InputBorder.none,
          suffixIcon: IconButton(
            icon: Icon(Icons.auto_awesome, color: duoPurpleDark),
            onPressed: _getAiSuggestions,
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionCard(
    String title,
    bool isDark,
    Color borderColor,
    Color textColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border(
          top: BorderSide(color: borderColor, width: 2),
          left: BorderSide(color: borderColor, width: 2),
          right: BorderSide(color: borderColor, width: 2),
          bottom: BorderSide(color: borderColor, width: 5),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.bolt_rounded, color: duoPurple, size: 24),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: textColor,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStateMobile(Color labelColor) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 60),
          const Text("🪄", style: TextStyle(fontSize: 80)),
          const SizedBox(height: 20),
          Text(
            "CHƯA CÓ Ý TƯỞNG GÌ?\nHÃY THỬ NHẬP MỤC TIÊU CỦA BẠN!",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: labelColor,
              fontWeight: FontWeight.w900,
              fontSize: 13,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStateWeb(Color labelColor) {
    return Center(
      child: Opacity(
        opacity: 0.5,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_awesome_motion, size: 100, color: labelColor),
            const SizedBox(height: 20),
            Text(
              "KẾT QUẢ SẼ XUẤT HIỆN TẠI ĐÂY",
              style: TextStyle(color: labelColor, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomAction(bool isWeb, bool isDark, Color borderColor) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isWeb ? 40 : 20, vertical: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121212) : Colors.white,
        border: Border(top: BorderSide(color: borderColor, width: 2)),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isWeb ? 400 : double.infinity),
          child: ElevatedButton(
            onPressed: _isSaving ? null : _addTasksToSystem,
            style: ElevatedButton.styleFrom(
              backgroundColor: duoGreen,
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isSaving)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                if (_isSaving) const SizedBox(width: 15),
                Text(
                  _isSaving ? "ĐANG LƯU..." : "THÊM VÀO LỘ TRÌNH",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
