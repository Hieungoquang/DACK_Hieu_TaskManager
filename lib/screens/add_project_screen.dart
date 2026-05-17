import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/project_model.dart';
import '../provider/task_provider.dart';
import '../provider/app_provider.dart';
import 'project_board_screen.dart';

class AddProjectScreen extends StatefulWidget {
  final Project? project;
  const AddProjectScreen({super.key, this.project});

  @override
  State<AddProjectScreen> createState() => _AddProjectScreenState();
}

class _AddProjectScreenState extends State<AddProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descController;

  // GitHub Style Colors
  static const Color ghBlue = Color(0xFF58A6FF);
  static const Color ghGreen = Color(0xFF3FB950);
  static const Color ghBlueLink = Color(0xFF0969DA);

  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.project?.name ?? '');
    _descController = TextEditingController(text: widget.project?.description ?? '');
    _startDate = widget.project?.startDate;
    _endDate = widget.project?.endDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _saveProject() async {
    if (!_formKey.currentState!.validate()) return;

    final taskProvider = context.read<TaskProvider>();
    final user = auth.FirebaseAuth.instance.currentUser;
    
    if (widget.project == null) {
      final newProject = Project(
        project_id: const Uuid().v4(),
        user_id: user?.uid ?? "guest",
        name: _nameController.text.trim(),
        description: _descController.text.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        memberIds: [],
        memberStatuses: {},
        startDate: _startDate,
        endDate: _endDate,
      );
      await taskProvider.addProject(newProject);
      if (!mounted) return;
      Navigator.pop(context);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProjectBoardScreen(project: newProject),
        ),
      );
    } else {
      if (_startDate != null) {
        final existingTasks = taskProvider.tasks.where((t) => t.project_id == widget.project!.project_id);
        final earlierTasks = existingTasks.where((t) => t.due_day.isBefore(_startDate!)).toList();
        if (earlierTasks.isNotEmpty) {
          final isDarkNow = Provider.of<AppProvider>(context, listen: false).themeMode == ThemeMode.dark;
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: isDarkNow ? const Color(0xFF161B22) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: Colors.red, size: 24),
                  const SizedBox(width: 8),
                  Text("Lỗi mốc thời gian", style: GoogleFonts.nunito(fontWeight: FontWeight.bold, color: isDarkNow ? const Color(0xFFC9D1D9) : const Color(0xFF24292F))),
                ],
              ),
              content: Text(
                "Không thể thay đổi ngày bắt đầu dự án thành ${DateFormat('dd/MM/yyyy HH:mm').format(_startDate!)} vì có công việc '${earlierTasks.first.title}' bắt đầu trước ngày này (${DateFormat('dd/MM/yyyy HH:mm').format(earlierTasks.first.due_day)}).",
                style: GoogleFonts.nunito(color: isDarkNow ? const Color(0xFFC9D1D9) : const Color(0xFF24292F), fontSize: 14, height: 1.5),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(backgroundColor: ghBlueLink, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  child: Text("Đã hiểu", style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
          return;
        }
      }

      final updatedProject = widget.project!;
      updatedProject.name = _nameController.text.trim();
      updatedProject.description = _descController.text.trim();
      updatedProject.startDate = _startDate;
      updatedProject.endDate = _endDate;
      updatedProject.updatedAt = DateTime.now();
      await taskProvider.updateProject(updatedProject);
      if (!mounted) return;
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final isDark = appProvider.themeMode == ThemeMode.dark;
    final size = MediaQuery.of(context).size;
    final isWeb = size.width > 900;

    final bgColor = isDark ? const Color(0xFF161B22) : Colors.white;
    final textColor =
        isDark ? const Color(0xFFC9D1D9) : const Color(0xFF24292F);
    final borderColor =
        isDark ? const Color(0xFF30363D) : const Color(0xFFD0D7DE);
    final headerColor = isDark ? const Color(0xFF0D1117) : const Color(0xFFF6F8FA);

    return Dialog(
      backgroundColor: bgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor, width: 1.5),
      ),
      insetPadding: EdgeInsets.symmetric(
        horizontal: isWeb ? size.width * 0.25 : 16,
        vertical: isWeb ? 100 : 24,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: size.height * 0.85, maxWidth: 800),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _topBar(isDark, textColor, borderColor, headerColor),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInput(
                        isDark,
                        'Tên dự án',
                        _nameController,
                        'Ví dụ: Dự án Website Alpha',
                        Icons.folder_outlined,
                        borderColor,
                        textColor,
                        required: true,
                      ),
                      const SizedBox(height: 24),
                      _buildDescriptionSection(isDark, borderColor, textColor),
                      const SizedBox(height: 24),
                      _buildTimeSection(isDark, borderColor, textColor),
                      const SizedBox(height: 32),
                      _buildCreateButton(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topBar(bool isDark, Color textColor, Color borderColor, Color headerColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: headerColor,
        border: Border(bottom: BorderSide(color: borderColor)),
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
      ),
      child: Row(
        children: [
          Icon(widget.project == null ? Icons.create_new_folder_outlined : Icons.edit_note, color: ghGreen, size: 28),
          const SizedBox(width: 15),
          Text(
            widget.project == null ? 'TẠO DỰ ÁN MỚI' : 'CHỈNH SỬA DỰ ÁN',
            style: GoogleFonts.nunito(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
              letterSpacing: 1,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.close, color: textColor, size: 24),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection(bool isDark, Color borderColor, Color textColor) {
    final subColor = isDark ? const Color(0xFF8B949E) : const Color(0xFF57606A);
    final inputBg = isDark ? const Color(0xFF0D1117) : const Color(0xFFF6F8FA);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Mô tả dự án",
          style: GoogleFonts.nunito(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          height: 180,
          decoration: BoxDecoration(
            color: inputBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor, width: 1.2),
          ),
          child: TextFormField(
            controller: _descController,
            maxLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            style: GoogleFonts.nunito(color: textColor, fontSize: 14, height: 1.6),
            decoration: InputDecoration(
              hintText: "Mục tiêu và kế hoạch của dự án này là...",
              hintStyle: GoogleFonts.nunito(
                color: subColor.withOpacity(0.5),
                fontSize: 14,
              ),
              contentPadding: const EdgeInsets.all(14),
              border: InputBorder.none,
              focusedBorder: InputBorder.none,
              enabledBorder: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInput(
    bool isDark,
    String label,
    TextEditingController ctrl,
    String hint,
    IconData icon,
    Color borderColor,
    Color textColor, {
    bool required = false,
  }) {
    final subColor = isDark ? const Color(0xFF8B949E) : const Color(0xFF57606A);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.nunito(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0D1117) : const Color(0xFFF6F8FA),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor, width: 1.2),
          ),
          child: TextFormField(
            controller: ctrl,
            style: GoogleFonts.nunito(
              color: textColor,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
            decoration: InputDecoration(
              icon: Icon(icon, color: ghBlue, size: 20),
              hintText: hint,
              hintStyle: GoogleFonts.nunito(
                color: subColor.withOpacity(0.5),
                fontSize: 15,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
            validator: (v) => (required && (v == null || v.isEmpty))
                ? "Vui lòng nhập $label"
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildCreateButton() {
    return ElevatedButton(
      onPressed: _saveProject,
      style: ElevatedButton.styleFrom(
        backgroundColor: ghGreen,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 0,
      ),
      child: Text(
        widget.project == null ? "TẠO DỰ ÁN" : "LƯU THAY ĐỔI",
        style: GoogleFonts.nunito(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildTimeSection(bool isDark, Color borderColor, Color textColor) {
    final subColor = isDark ? const Color(0xFF8B949E) : const Color(0xFF57606A);
    final inputBg = isDark ? const Color(0xFF0D1117) : const Color(0xFFF6F8FA);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Thời gian dự án (Không bắt buộc)",
          style: GoogleFonts.nunito(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: inputBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor, width: 1.2),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _timeSubBtn(
                      _startDate == null ? "Bắt đầu" : DateFormat('dd/MM/yyyy HH:mm').format(_startDate!),
                      () => _pickDateTime(true),
                      isDark,
                      borderColor,
                      textColor,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
                  ),
                  Expanded(
                    child: _timeSubBtn(
                      _endDate == null ? "Kết thúc" : DateFormat('dd/MM/yyyy HH:mm').format(_endDate!),
                      () => _pickDateTime(false),
                      isDark,
                      borderColor,
                      textColor,
                    ),
                  ),
                ],
              ),
              if (_startDate != null || _endDate != null) ...[
                const SizedBox(height: 10),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _startDate = null;
                      _endDate = null;
                    });
                  },
                  icon: const Icon(Icons.clear, size: 16, color: Colors.redAccent),
                  label: Text(
                    "Xóa thời gian",
                    style: GoogleFonts.nunito(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _timeSubBtn(String label, VoidCallback onTap, bool isDark, Color borderColor, Color textColor) {
    final btnBg = isDark ? const Color(0xFF161B22) : Colors.white;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: btnBg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: borderColor.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.calendar_month_outlined, size: 16, color: ghBlueLink),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.nunito(
                color: textColor,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDateTime(bool isStart) async {
    final now = DateTime.now();
    final initialDate = isStart ? (_startDate ?? now) : (_endDate ?? _startDate ?? now);

    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.fromSeed(seedColor: ghBlueLink),
        ),
        child: child!,
      ),
    );

    if (date == null) return;

    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.fromSeed(seedColor: ghBlueLink),
        ),
        child: child!,
      ),
    );

    if (time == null) return;

    setState(() {
      final combined = DateTime(date.year, date.month, date.day, time.hour, time.minute);
      if (isStart) {
        _startDate = combined;
        if (_endDate != null && _endDate!.isBefore(_startDate!)) {
          _endDate = _startDate!.add(const Duration(hours: 2));
        }
      } else {
        _endDate = combined;
        if (_startDate == null) {
          _startDate = _endDate!.subtract(const Duration(hours: 2));
        } else if (_endDate!.isBefore(_startDate!)) {
          _startDate = _endDate!.subtract(const Duration(hours: 2));
        }
      }
    });
  }
}
