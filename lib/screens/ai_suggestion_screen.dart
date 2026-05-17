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
  List<AiSuggestedTask> _suggestedSubtasks = [];
  bool _isLoading = false;
  bool _isSaving = false;

  // Options
  int _subtaskCount = 5;
  bool _linkInChain = false;
  String? _selectedProjectId; // null means Personal (Cá nhân)
  int? _expandedIndex; // Which card is currently expanded for inline editing

  // GitHub Style Colors
  static const Color ghBlue = Color(0xFF58A6FF);
  static const Color ghGreen = Color(0xFF3FB950);
  static const Color ghOrange = Color(0xFFD29922);
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

  Color _bg(bool d) => d ? ghDarkBg : ghLightBg;
  Color _card(bool d) => d ? ghDarkCard : ghLightCard;
  Color _border(bool d) => d ? ghDarkBorder : ghLightBorder;
  Color _txt(bool d) => d ? ghDarkText : ghLightText;
  Color _sub(bool d) => d ? ghDarkSubText : ghLightSubText;

  final List<String> _quickIdeas = [
    "Học Flutter cơ bản",
    "Luyện thi IELTS 7.5",
    "Setup bàn làm việc",
    "Lên kế hoạch du lịch",
    "Chạy bộ 5K trong 30 ngày",
  ];

  void _getAiSuggestions() async {
    final title = _taskController.text.trim();
    if (title.isEmpty || _isLoading) return;

    setState(() {
      _isLoading = true;
      _suggestedSubtasks = [];
      _expandedIndex = null;
    });

    try {
      final suggestions = await AiService.generateSubtasks(title, count: _subtaskCount);
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

    final selectedTasks = _suggestedSubtasks.where((t) => t.isSelected).toList();
    if (selectedTasks.isEmpty) {
      AppPopup.error(context, "Vui lòng chọn ít nhất một tác vụ để thêm!");
      return;
    }

    setState(() => _isSaving = true);

    try {
      final taskProvider = context.read<TaskProvider>();
      final user = FirebaseAuth.instance.currentUser;
      final userId = user?.uid ?? "guest_user";

      // 1. Thêm Task chính đại diện cho lộ trình
      final mainTaskId = const Uuid().v4();
      final mainTask = Task(
        task_id: mainTaskId,
        user_id: userId,
        title: mainTitle,
        description: "Lộ trình hành động chi tiết được lập bởi Taskflow AI.",
        due_day: DateTime.now().add(const Duration(days: 1)),
        priority: 2,
        progress: 0,
        duration: selectedTasks.fold(0, (sum, t) => sum + t.duration),
        deadline: DateTime.now().add(Duration(days: selectedTasks.length + 1)),
        status: 'pending',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        category: 'Công việc',
        project_id: _selectedProjectId,
      );

      await taskProvider.addTask(mainTask);

      // 2. Thêm các tác vụ con do người dùng tùy chỉnh
      String? previousSubTaskId;
      for (int i = 0; i < selectedTasks.length; i++) {
        final sug = selectedTasks[i];
        final subTaskId = const Uuid().v4();

        final subTask = Task(
          task_id: subTaskId,
          user_id: userId,
          title: sug.title,
          description: sug.description,
          due_day: DateTime.now().add(Duration(days: i + 1)),
          priority: sug.priority,
          progress: 0,
          duration: sug.duration,
          deadline: DateTime.now().add(Duration(days: i + 2)),
          status: 'pending',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          category: sug.category,
          project_id: _selectedProjectId,
          dependencyTaskId: _linkInChain ? previousSubTaskId : null, // Gán phụ thuộc tuần tự!
        );

        await taskProvider.addTask(subTask);

        // Đánh dấu mốc nối tiếp
        if (_linkInChain) {
          previousSubTaskId = subTaskId;
        }

        // Đồng thời thêm một checklist phụ trợ bên trong task chính
        await taskProvider.addSubtask(mainTaskId, sug.title);
      }

      // 3. Thông báo hoàn tất
      await taskProvider.notifyAISuggestion(mainTitle);

      if (mounted) {
        AppPopup.success(context, "Đã khởi tạo lộ trình AI thành công!");
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
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final isDark = appProvider.themeMode == ThemeMode.dark;
    final textColor = _txt(isDark);
    final labelColor = _sub(isDark);
    final inputBg = _card(isDark);
    final borderColor = _border(isDark);

    double width = MediaQuery.of(context).size.width;
    bool isWeb = width > 900;

    final provider = context.watch<TaskProvider>();

    return Scaffold(
      backgroundColor: _bg(isDark),
      bottomNavigationBar: isWeb ? null : const MobileBottomNav(currentRoute: 'ai'),
      body: Row(
        children: [
          if (isWeb) const WebSidebar(currentRoute: 'ai'),
          Expanded(
            child: SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(horizontal: isWeb ? 40 : 16, vertical: 20),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 900),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildHeader(isDark, isWeb),
                              const SizedBox(height: 24),
                              _buildInputPanel(inputBg, borderColor, isDark, textColor, labelColor, isWeb, provider),
                              const SizedBox(height: 24),
                              _buildResultSection(isDark, borderColor, textColor, labelColor, isWeb),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (_suggestedSubtasks.isNotEmpty)
                    _buildBottomAction(isWeb, isDark, borderColor),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark, bool isWeb) {
    return Row(
      children: [
        if (!isWeb)
          IconButton(
            icon: Icon(Icons.arrow_back, color: _txt(isDark)),
            onPressed: _handleBackNavigation,
          ),
        Icon(Icons.auto_awesome_rounded, color: ghBlue, size: 28),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "TRỢ LÝ LẬP KẾ HOẠCH AI",
                style: GoogleFonts.nunito(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: _txt(isDark),
                ),
              ),
              Text(
                "Chia nhỏ lộ trình và tự động thiết lập chuỗi phụ thuộc",
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  color: _sub(isDark),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInputPanel(
    Color inputBg,
    Color borderColor,
    bool isDark,
    Color textColor,
    Color labelColor,
    bool isWeb,
    TaskProvider provider,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: inputBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "NHẬP MỤC TIÊU LỚN CỦA BẠN:",
            style: GoogleFonts.nunito(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: labelColor,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 12),
          _buildDuoTextField(inputBg, borderColor, isDark, textColor, labelColor),
          const SizedBox(height: 16),
          // Thẻ Gợi Ý Nhanh
          Text(
            "Gợi ý nhanh:",
            style: GoogleFonts.nunito(fontSize: 12, color: labelColor, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _quickIdeas.map((idea) {
              return GestureDetector(
                onTap: () {
                  _taskController.text = idea;
                  _getAiSuggestions();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF21262D) : const Color(0xFFEFEFEF),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderColor),
                  ),
                  child: Text(
                    idea,
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const Divider(height: 32),
          // Cài Đặt Nâng Cao
          Text(
            "CẤU HÌNH LỘ TRÌNH:",
            style: GoogleFonts.nunito(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: labelColor,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 16),
          if (isWeb)
            Row(
              children: [
                Expanded(child: _buildSubtaskCountDropdown(isDark, borderColor, textColor)),
                const SizedBox(width: 16),
                Expanded(child: _buildProjectDropdown(isDark, borderColor, textColor, provider)),
              ],
            )
          else ...[
            _buildSubtaskCountDropdown(isDark, borderColor, textColor),
            const SizedBox(height: 16),
            _buildProjectDropdown(isDark, borderColor, textColor, provider),
          ],
          const SizedBox(height: 16),
          _buildChainLinkSwitch(isDark, borderColor, textColor, labelColor),
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
        color: isDark ? const Color(0xFF0D1117) : const Color(0xFFF6F8FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: TextField(
        controller: _taskController,
        onSubmitted: (_) => _getAiSuggestions(),
        style: GoogleFonts.nunito(fontWeight: FontWeight.bold, color: textColor),
        decoration: InputDecoration(
          hintText: "Ví dụ: Lên kế hoạch tự học tiếng Nhật...",
          hintStyle: GoogleFonts.nunito(
            color: labelColor.withOpacity(0.5),
            fontWeight: FontWeight.bold,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: InputBorder.none,
          suffixIcon: IconButton(
            icon: Icon(Icons.auto_awesome, color: ghBlue),
            onPressed: _getAiSuggestions,
          ),
        ),
      ),
    );
  }

  Widget _buildSubtaskCountDropdown(bool isDark, Color borderColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D1117) : const Color(0xFFF6F8FA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _subtaskCount,
          dropdownColor: _card(isDark),
          items: const [
            DropdownMenuItem(value: 3, child: Text("Quy mô: 3 bước con")),
            DropdownMenuItem(value: 5, child: Text("Quy mô: 5 bước con (Chuẩn)")),
            DropdownMenuItem(value: 8, child: Text("Quy mô: 8 bước con")),
            DropdownMenuItem(value: 10, child: Text("Quy mô: 10 bước con (Chi tiết)")),
          ],
          onChanged: (val) {
            if (val != null) setState(() => _subtaskCount = val);
          },
          style: GoogleFonts.nunito(color: textColor, fontWeight: FontWeight.bold, fontSize: 13),
          isExpanded: true,
        ),
      ),
    );
  }

  Widget _buildProjectDropdown(bool isDark, Color borderColor, Color textColor, TaskProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D1117) : const Color(0xFFF6F8FA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: _selectedProjectId,
          dropdownColor: _card(isDark),
          hint: const Text("Chọn dự án"),
          items: [
            DropdownMenuItem(
              value: null,
              child: Text(
                "📂 Cá nhân (Không thuộc dự án)",
                style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
              ),
            ),
            ...provider.projects.map((proj) {
              return DropdownMenuItem(
                value: proj.project_id,
                child: Text("📁 Dự án: ${proj.name}"),
              );
            }),
          ],
          onChanged: (val) {
            setState(() => _selectedProjectId = val);
          },
          style: GoogleFonts.nunito(color: textColor, fontWeight: FontWeight.bold, fontSize: 13),
          isExpanded: true,
        ),
      ),
    );
  }

  Widget _buildChainLinkSwitch(bool isDark, Color borderColor, Color textColor, Color labelColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _linkInChain
            ? Colors.purple.withOpacity(isDark ? 0.15 : 0.05)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _linkInChain
              ? Colors.purple.withOpacity(0.5)
              : borderColor,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.link_rounded,
            color: _linkInChain ? Colors.purpleAccent : labelColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "TỰ ĐỘNG NỐI CHUỖI LIÊN KẾT TUẦN TỰ",
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: _linkInChain ? Colors.purpleAccent : textColor,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  "Bắt buộc hoàn thành nối tiếp nhau (Task 1 -> Task 2 -> Task 3)",
                  style: GoogleFonts.nunito(
                    fontSize: 11,
                    color: labelColor,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _linkInChain,
            activeColor: Colors.purpleAccent,
            onChanged: (val) => setState(() => _linkInChain = val),
          ),
        ],
      ),
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
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: [
              const CircularProgressIndicator(color: ghBlue, strokeWidth: 4),
              const SizedBox(height: 16),
              Text(
                "AI ĐANG CHIA NHỎ MỤC TIÊU...",
                style: GoogleFonts.nunito(
                  color: ghBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_suggestedSubtasks.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40),
        alignment: Alignment.center,
        child: Column(
          children: [
            const Text("🪄", style: TextStyle(fontSize: 60)),
            const SizedBox(height: 16),
            Text(
              "KẾT QUẢ PHÂN TÍCH LỘ TRÌNH SẼ XUẤT HIỆN TẠI ĐÂY",
              style: GoogleFonts.nunito(
                color: labelColor,
                fontWeight: FontWeight.bold,
                fontSize: 13,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "LỘ TRÌNH ĐỀ XUẤT (NHẤP ĐỂ TÙY CHỈNH CHÌ TIẾT):",
              style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: ghBlue,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              "${_suggestedSubtasks.where((t) => t.isSelected).length} việc được chọn",
              style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: ghGreen,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _suggestedSubtasks.length,
          itemBuilder: (context, index) {
            final task = _suggestedSubtasks[index];
            final isExpanded = _expandedIndex == index;

            return _buildInteractiveTaskCard(task, index, isExpanded, isDark, borderColor, textColor, labelColor);
          },
        ),
      ],
    );
  }

  Widget _buildInteractiveTaskCard(
    AiSuggestedTask task,
    int index,
    bool isExpanded,
    bool isDark,
    Color borderColor,
    Color textColor,
    Color labelColor,
  ) {
    final catColor = task.priority == 3
        ? Colors.redAccent
        : (task.priority == 2 ? ghOrange : ghBlue);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _card(isDark),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isExpanded ? Colors.purpleAccent.withOpacity(0.5) : borderColor,
          width: isExpanded ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          // Card Header (Collapsed view)
          ListTile(
            onTap: () {
              setState(() {
                _expandedIndex = isExpanded ? null : index;
              });
            },
            leading: Checkbox(
              value: task.isSelected,
              activeColor: ghGreen,
              onChanged: (val) {
                if (val != null) {
                  setState(() => task.isSelected = val);
                }
              },
            ),
            title: Text(
              task.title,
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.bold,
                color: task.isSelected ? textColor : labelColor.withOpacity(0.5),
                decoration: task.isSelected ? null : TextDecoration.lineThrough,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: catColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      task.priority == 3 ? "Ưu tiên: Cao" : (task.priority == 2 ? "Ưu tiên: Vừa" : "Ưu tiên: Thấp"),
                      style: GoogleFonts.nunito(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: catColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.access_time_filled_rounded, size: 12, color: labelColor),
                  const SizedBox(width: 4),
                  Text(
                    "${task.duration} phút",
                    style: GoogleFonts.nunito(fontSize: 11, color: labelColor, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.label_important_rounded, size: 12, color: ghBlue),
                  const SizedBox(width: 4),
                  Text(
                    task.category,
                    style: GoogleFonts.nunito(fontSize: 11, color: ghBlue, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            trailing: Icon(
              isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: labelColor,
              size: 20,
            ),
          ),
          // Expanded Editor panel
          if (isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Edit
                  TextFormField(
                    initialValue: task.title,
                    style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: "Tên nhiệm vụ",
                      labelStyle: GoogleFonts.nunito(color: labelColor, fontSize: 12),
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    onChanged: (val) => task.title = val,
                  ),
                  const SizedBox(height: 12),
                  // Description Edit
                  TextFormField(
                    initialValue: task.description,
                    style: GoogleFonts.nunito(fontSize: 13),
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: "Mô tả chi tiết",
                      labelStyle: GoogleFonts.nunito(color: labelColor, fontSize: 12),
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    onChanged: (val) => task.description = val,
                  ),
                  const SizedBox(height: 16),
                  // Configs row (Category, Priority, Duration)
                  Row(
                    children: [
                      // Category selection dropdown
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: task.category,
                          dropdownColor: _card(isDark),
                          decoration: InputDecoration(
                            labelText: "Danh mục",
                            labelStyle: GoogleFonts.nunito(color: labelColor, fontSize: 11),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            border: const OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: "Công việc", child: Text("Công việc")),
                            DropdownMenuItem(value: "Học tập", child: Text("Học tập")),
                            DropdownMenuItem(value: "Cá nhân", child: Text("Cá nhân")),
                            DropdownMenuItem(value: "Sức khỏe", child: Text("Sức khỏe")),
                            DropdownMenuItem(value: "Giải trí", child: Text("Giải trí")),
                            DropdownMenuItem(value: "Khác", child: Text("Khác")),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => task.category = val);
                            }
                          },
                          style: GoogleFonts.nunito(color: textColor, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Priority Selection
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: task.priority,
                          dropdownColor: _card(isDark),
                          decoration: InputDecoration(
                            labelText: "Ưu tiên",
                            labelStyle: GoogleFonts.nunito(color: labelColor, fontSize: 11),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            border: const OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: 1, child: Text("Thấp")),
                            DropdownMenuItem(value: 2, child: Text("Vừa")),
                            DropdownMenuItem(value: 3, child: Text("Cao")),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => task.priority = val);
                            }
                          },
                          style: GoogleFonts.nunito(color: textColor, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Duration counter picker
                      Container(
                        width: 100,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: borderColor),
                        ),
                        child: Column(
                          children: [
                            Text(
                              "THỜI LƯỢNG",
                              style: GoogleFonts.nunito(fontSize: 9, color: labelColor, fontWeight: FontWeight.bold),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                InkWell(
                                  onTap: () {
                                    if (task.duration > 15) {
                                      setState(() => task.duration -= 15);
                                    }
                                  },
                                  child: const Icon(Icons.remove, size: 16),
                                ),
                                Text(
                                  "${task.duration}'",
                                  style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.bold, color: textColor),
                                ),
                                InkWell(
                                  onTap: () {
                                    setState(() => task.duration += 15);
                                  },
                                  child: const Icon(Icons.add, size: 16),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomAction(bool isWeb, bool isDark, Color borderColor) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isWeb ? 24 : 20, vertical: 20),
      decoration: BoxDecoration(
        color: _card(isDark),
        border: Border(top: BorderSide(color: borderColor, width: 1.5)),
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
            _isSaving ? "ĐANG THIẾT LẬP..." : "THÊM LỘ TRÌNH VÀO DANH SÁCH",
            style: GoogleFonts.nunito(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              letterSpacing: 0.5,
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
