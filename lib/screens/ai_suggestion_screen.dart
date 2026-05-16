import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/task_model.dart';
import '../provider/task_provider.dart';
import '../provider/app_provider.dart';
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

  // GitHub Style Colors
  static const Color ghBlue = Color(0xFF58A6FF);
  static const Color ghGreen = Color(0xFF3FB950);
  static const Color ghDarkBg = Color(0xFF0D1117);
  static const Color ghLightBg = Color(0xFFF6F8FA);
  static const Color ghDarkCard = Color(0xFF161B22);
  static const Color ghLightCard = Color(0xFFFFFFFF);
  static const Color ghDarkBorder = Color(0xFF30363D);
  static const Color ghLightBorder = Color(0xFFD0D7DE);
  static const Color ghDarkText = Color(0xFFC9D1D9);
  static const Color ghLightText = Color(0xFF24292F);
  static const Color ghDarkSubText = Color(0xFF8B949E);
  static const Color ghLightSubText = Color(0xFF57606A);

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
    final appProvider = Provider.of<AppProvider>(context);
    final isDark = appProvider.themeMode == ThemeMode.dark;
    final textColor = isDark ? ghDarkText : ghLightText;
    final labelColor = isDark ? ghDarkSubText : ghLightSubText;
    final inputBg = isDark ? ghDarkCard : ghLightCard;
    final borderColor = isDark ? ghDarkBorder : ghLightBorder;

    double width = MediaQuery.of(context).size.width;
    bool isWeb = width > 900;

    return Scaffold(
      backgroundColor: isDark ? ghDarkBg : ghLightBg,
      appBar: isWeb
          ? null
          : AppBar(
              backgroundColor: isDark ? ghDarkBg : ghLightBg,
              elevation: 0,
              centerTitle: false,
              title: Text(
                "AI TRỢ LÝ",
                style: GoogleFonts.quicksand(
                  color: isDark ? ghDarkText : ghLightText,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              leading: IconButton(
                icon: Icon(Icons.arrow_back,
                    color: isDark ? ghDarkSubText : ghLightSubText, size: 24),
                onPressed: _handleBackNavigation,
              ),
            ),
      bottomNavigationBar: isWeb ? null : MobileBottomNav(currentRoute: 'ai'),
      body: Row(
        children: [
          if (isWeb) const WebSidebar(currentRoute: 'ai'),
          Expanded(
            child: Column(
              children: [
                if (isWeb) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 30, 24, 20),
                    child: Row(
                      children: [
                        Text(
                          "AI TRỢ LÝ",
                          style: GoogleFonts.quicksand(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                Expanded(
                  child: isWeb
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.only(
                                  left: 24,
                                  right: 24,
                                  bottom: 24,
                                ),
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
                          padding: const EdgeInsets.only(
                            left: 20,
                            right: 20,
                            bottom: 20,
                          ),
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
        Text(
          "MÌNH GIÚP GÌ ĐƯỢC BẠN NHỈ?",
          style: GoogleFonts.quicksand(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: labelColor,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Nhập mục tiêu để mình chia nhỏ công việc giúp bạn!",
          style: GoogleFonts.quicksand(
            fontSize: isWeb ? 24 : 22,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 16),
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
            CircularProgressIndicator(color: ghBlue, strokeWidth: 5),
            const SizedBox(height: 20),
            Text(
              "ĐANG PHÙ PHÉP...",
              style: GoogleFonts.quicksand(
                color: ghBlue,
                fontWeight: FontWeight.bold,
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
            style: GoogleFonts.quicksand(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: ghBlue,
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
        style: GoogleFonts.quicksand(
            fontWeight: FontWeight.bold, color: textColor),
        decoration: InputDecoration(
          hintText: "Ví dụ: Học lập trình Flutter...",
          hintStyle: GoogleFonts.quicksand(
            color: labelColor.withOpacity(0.5),
            fontWeight: FontWeight.bold,
          ),
          contentPadding: const EdgeInsets.all(16),
          border: InputBorder.none,
          suffixIcon: IconButton(
            icon: Icon(Icons.auto_awesome, color: ghBlue),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? ghDarkCard : ghLightCard,
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
          Icon(Icons.bolt_rounded, color: ghBlue, size: 24),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.quicksand(
                fontWeight: FontWeight.bold,
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
            style: GoogleFonts.quicksand(
              color: labelColor,
              fontWeight: FontWeight.bold,
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
              style: GoogleFonts.quicksand(
                  color: labelColor, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomAction(bool isWeb, bool isDark, Color borderColor) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isWeb ? 24 : 20, vertical: 20),
      decoration: BoxDecoration(
        color: isDark ? ghDarkCard : ghLightCard,
        border: Border(top: BorderSide(color: borderColor, width: 2)),
      ),
      child: Center(
        child: ElevatedButton.icon(
          onPressed: _isSaving ? null : _addTasksToSystem,
          icon: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.add_task, size: 20),
          label: Text(
            _isSaving ? "ĐANG LƯU..." : "THÊM VÀO DANH SÁCH",
            style: GoogleFonts.quicksand(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              letterSpacing: 1.1,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: ghGreen,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(
              horizontal: isWeb ? 40 : 30,
              vertical: 16,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
        ),
      ),
    );
  }
}
