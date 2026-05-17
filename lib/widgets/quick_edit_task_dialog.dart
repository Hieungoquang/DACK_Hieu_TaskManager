import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/task_model.dart';
import '../provider/task_provider.dart';
import '../provider/app_provider.dart';

class QuickEditTaskDialog extends StatefulWidget {
  final Task task;
  const QuickEditTaskDialog({super.key, required this.task});

  @override
  State<QuickEditTaskDialog> createState() => _QuickEditTaskDialogState();
}

class _QuickEditTaskDialogState extends State<QuickEditTaskDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  late DateTime _startDate;
  late TimeOfDay _startTime;
  late DateTime _endDate;
  late TimeOfDay _endTime;
  late String _category;
  bool _isAllDay = false;
  late String _reminder;
  String? _dependencyTaskId;

  static const Map<String, Color> _categoryColors = {
    'Công việc': Color(0xFF0969DA),
    'Cá nhân': Color(0xFF238636),
    'Học tập': Color(0xFFA371F7),
    'Khác': Color(0xFFD29922),
  };

  static const Map<String, int> _reminderOptions = {
    'Không thông báo': 0,
    '15 phút trước': 15,
    '30 phút trước': 30,
    '1 giờ trước': 60,
    '1 ngày trước': 1440,
  };

  static const Color ghGreen = Color(0xFF238636);
  static const Color ghBlue = Color(0xFF0969DA);

  Color _bg(bool d) => d ? const Color(0xFF0D1117) : Colors.white;
  Color _headerBg(bool d) => d ? const Color(0xFF0D1117) : const Color(0xFFF6F8FA);
  Color _border(bool d) => d ? const Color(0xFF30363D) : const Color(0xFFD0D7DE);
  Color _input(bool d) => d ? const Color(0xFF010409) : Colors.white;
  Color _txt(bool d) => d ? const Color(0xFFC9D1D9) : const Color(0xFF24292F);
  Color _sub(bool d) => d ? const Color(0xFF8B949E) : const Color(0xFF57606A);

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _descController = TextEditingController(text: widget.task.description);
    _startDate = widget.task.due_day;
    _startTime = TimeOfDay.fromDateTime(widget.task.due_day);
    _endDate = widget.task.deadline;
    _endTime = TimeOfDay.fromDateTime(widget.task.deadline);
    _category = widget.task.category;
    _dependencyTaskId = widget.task.dependencyTaskId;
    _reminder = _reminderOptions.entries
        .firstWhere(
          (entry) => entry.value == widget.task.reminder,
          orElse: () => _reminderOptions.entries.first,
        )
        .key;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<AppProvider>(context).themeMode == ThemeMode.dark;
    final size = MediaQuery.of(context).size;
    final isWeb = size.width > 900;

    return Dialog(
      backgroundColor: _bg(isDark),
      insetPadding: EdgeInsets.symmetric(horizontal: isWeb ? size.width * 0.25 : 16, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: _border(isDark), width: 1.5),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 800, maxHeight: size.height * 0.85),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(isDark),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTitleSection(isDark),
                    const SizedBox(height: 24),
                    _buildMetaRow(isDark),
                    const SizedBox(height: 24),
                    _buildTimeSection(isDark),
                    const SizedBox(height: 24),
                    _buildDescriptionSection(isDark),
                    const SizedBox(height: 24),
                    _buildDependencySelector(isDark),
                  ],
                ),
              ),
            ),
            _buildFooter(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: _headerBg(isDark),
        border: Border(bottom: BorderSide(color: _border(isDark))),
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
      ),
      child: Row(
        children: [
          Icon(Icons.edit_calendar, color: ghBlue, size: 24),
          const SizedBox(width: 12),
          Text("CHỈNH SỬA CÔNG VIỆC",
              style: GoogleFonts.nunito(color: _txt(isDark), fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.close, color: _sub(isDark), size: 24),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Tên công việc", style: GoogleFonts.nunito(color: _txt(isDark), fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 10),
        TextField(
          controller: _titleController,
          style: GoogleFonts.nunito(color: _txt(isDark), fontWeight: FontWeight.bold, fontSize: 18),
          decoration: InputDecoration(
            hintText: "Nhập tên công việc...",
            hintStyle: GoogleFonts.nunito(color: _sub(isDark).withOpacity(0.5)),
            filled: true,
            fillColor: _input(isDark),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: _border(isDark))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: ghBlue, width: 2)),
          ),
        ),
      ],
    );
  }

  Widget _buildMetaRow(bool isDark) {
    return Row(
      children: [
        Expanded(child: _metaBtn(Icons.label_outline, _category, () => _showCategoryPicker(isDark), isDark)),
        const SizedBox(width: 12),
        Expanded(child: _metaBtn(Icons.notifications_none, _reminder, () => _showReminderPicker(isDark), isDark)),
      ],
    );
  }

  Widget _buildTimeSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Thời gian thực hiện", style: GoogleFonts.nunito(color: _txt(isDark), fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: _input(isDark), borderRadius: BorderRadius.circular(8), border: Border.all(color: _border(isDark))),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: _timeSubBtn(DateFormat('dd/MM/yyyy').format(_startDate), () => _pickDate(true), isDark)),
                  const Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Icon(Icons.arrow_forward, size: 16, color: Colors.grey)),
                  Expanded(child: _timeSubBtn(DateFormat('dd/MM/yyyy').format(_endDate), () => _pickDate(false), isDark)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _timeSubBtn(_startTime.format(context), () => _pickTime(true), isDark, icon: Icons.access_time)),
                  const Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Icon(Icons.remove, size: 16, color: Colors.grey)),
                  Expanded(child: _timeSubBtn(_endTime.format(context), () => _pickTime(false), isDark, icon: Icons.access_time)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _timeSubBtn(String label, VoidCallback onTap, bool isDark, {IconData? icon}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(color: _headerBg(isDark), borderRadius: BorderRadius.circular(6), border: Border.all(color: _border(isDark).withOpacity(0.5))),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[Icon(icon, size: 14, color: ghBlue), const SizedBox(width: 6)],
            Text(label, style: GoogleFonts.nunito(color: _txt(isDark), fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _metaBtn(IconData icon, String label, VoidCallback onTap, bool isDark) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(color: _input(isDark), borderRadius: BorderRadius.circular(8), border: Border.all(color: _border(isDark), width: 1.2)),
        child: Row(
          children: [
            Icon(icon, color: ghBlue, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(label, style: GoogleFonts.nunito(color: _txt(isDark), fontSize: 13, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
            Icon(Icons.arrow_drop_down, color: _sub(isDark), size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Ghi chú mô tả", style: GoogleFonts.nunito(color: _txt(isDark), fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 10),
        Container(
          height: 150,
          decoration: BoxDecoration(color: _input(isDark), borderRadius: BorderRadius.circular(8), border: Border.all(color: _border(isDark), width: 1.2)),
          child: TextField(
            controller: _descController,
            maxLines: null,
            expands: true,
            style: GoogleFonts.nunito(color: _txt(isDark), fontSize: 14, height: 1.5),
            decoration: InputDecoration(
              hintText: "Thêm chi tiết công việc...",
              hintStyle: GoogleFonts.nunito(color: _sub(isDark).withOpacity(0.5)),
              contentPadding: const EdgeInsets.all(12),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: _border(isDark))), color: _headerBg(isDark), borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16))),
      child: Row(
        children: [
          ElevatedButton.icon(
            onPressed: _deleteTask,
            icon: const Icon(Icons.delete_outline, size: 18),
            label: Text("XÓA", style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), elevation: 0),
          ),
          const Spacer(),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("HỦY", style: GoogleFonts.nunito(color: _sub(isDark), fontWeight: FontWeight.bold, fontSize: 14)),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _save,
            style: ElevatedButton.styleFrom(backgroundColor: ghGreen, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), elevation: 0),
            child: Text("CẬP NHẬT", style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 14)),
          ),
        ],
      ),
    );
  }

  void _showCategoryPicker(bool isDark) {
    final cats = _categoryColors.keys.toList();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _bg(isDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Chọn nhãn", textAlign: TextAlign.center, style: GoogleFonts.nunito(color: _txt(isDark), fontWeight: FontWeight.bold, fontSize: 18)),
        content: SizedBox(
          width: 300,
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: cats.map((c) => ActionChip(
              label: Text(c, style: GoogleFonts.nunito(fontSize: 14)),
              onPressed: () { setState(() => _category = c); Navigator.pop(ctx); },
              backgroundColor: _category == c ? ghBlue : _input(isDark),
              labelStyle: GoogleFonts.nunito(color: _category == c ? Colors.white : _txt(isDark), fontWeight: FontWeight.bold),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            )).toList(),
          ),
        ),
      ),
    );
  }

  void _showReminderPicker(bool isDark) {
    final opts = _reminderOptions.keys.toList();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _bg(isDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Thông báo", textAlign: TextAlign.center, style: GoogleFonts.nunito(color: _txt(isDark), fontWeight: FontWeight.bold, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: opts.map((o) => ListTile(
            title: Text(o, style: GoogleFonts.nunito(color: _txt(isDark), fontSize: 15, fontWeight: FontWeight.bold)),
            trailing: _reminder == o ? Icon(Icons.check, color: ghBlue) : null,
            onTap: () { setState(() => _reminder = o); Navigator.pop(ctx); },
          )).toList(),
        ),
      ),
    );
  }

  Future<void> _pickDate(bool isStart) async {
    final d = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: ColorScheme.fromSeed(seedColor: ghBlue)), child: child!),
    );
    if (d != null) setState(() => isStart ? _startDate = d : _endDate = d);
  }

  Future<void> _pickTime(bool isStart) async {
    final t = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
      builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: ColorScheme.fromSeed(seedColor: ghBlue)), child: child!),
    );
    if (t != null) setState(() => isStart ? _startTime = t : _endTime = t);
  }

  void _save() async {
    if (_titleController.text.trim().isEmpty) return;
    try {
      final start = DateTime(_startDate.year, _startDate.month, _startDate.day, _startTime.hour, _startTime.minute);
      final deadline = DateTime(_endDate.year, _endDate.month, _endDate.day, _endTime.hour, _endTime.minute);
      
      if (widget.task.project_id != null) {
        final provider = context.read<TaskProvider>();
        final project = provider.projects.where((p) => p.project_id == widget.task.project_id).firstOrNull;
        if (project != null && project.startDate != null && start.isBefore(project.startDate!)) {
          final isDarkNow = Provider.of<AppProvider>(context, listen: false).themeMode == ThemeMode.dark;
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: _bg(isDarkNow),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: Colors.red, size: 24),
                  const SizedBox(width: 8),
                  Text("Lỗi thời gian", style: GoogleFonts.nunito(fontWeight: FontWeight.bold, color: _txt(isDarkNow))),
                ],
              ),
              content: Text(
                "Thời gian bắt đầu công việc phải trùng hoặc sau thời gian bắt đầu dự án (${DateFormat('dd/MM/yyyy HH:mm').format(project.startDate!)}).",
                style: GoogleFonts.nunito(color: _txt(isDarkNow), fontSize: 14, height: 1.5),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(backgroundColor: ghGreen, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  child: Text("Đã hiểu", style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
          return;
        }
      }

      widget.task.title = _titleController.text.trim();
      widget.task.description = _descController.text.trim();
      widget.task.category = _category;
      widget.task.reminder = _reminderOptions[_reminder] ?? 0;
      widget.task.due_day = start;
      widget.task.deadline = deadline;
      widget.task.duration = deadline.difference(start).inMinutes.abs().clamp(15, 1440);
      widget.task.dependencyTaskId = _dependencyTaskId;
      widget.task.updatedAt = DateTime.now();
      widget.task.isSynced = false;

      await context.read<TaskProvider>().updateTask(widget.task);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint("Error saving task: $e");
    }
  }

  void _deleteTask() async {
    final isDark = Provider.of<AppProvider>(context, listen: false).themeMode == ThemeMode.dark;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _bg(isDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Xóa công việc?", style: GoogleFonts.nunito(fontWeight: FontWeight.bold, color: _txt(isDark))),
        content: Text("Bạn có chắc chắn muốn xóa vĩnh viễn công việc này không?", style: GoogleFonts.nunito(color: _txt(isDark))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text("HỦY", style: GoogleFonts.nunito(color: _sub(isDark)))),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: Text("XÓA", style: GoogleFonts.nunito(color: Colors.white))),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<TaskProvider>().deleteTask(widget.task.task_id);
      if (mounted) Navigator.pop(context);
    }
  }

  Widget _buildDependencySelector(bool isDark) {
    if (widget.task.project_id == null) return const SizedBox.shrink();

    final provider = Provider.of<TaskProvider>(context);
    final candidates = provider.getPrerequisiteCandidates(widget.task);

    if (candidates.isEmpty) return const SizedBox.shrink();

    final selectedTask = provider.tasks.where((t) => t.task_id == _dependencyTaskId).firstOrNull;
    final label = selectedTask == null ? "Không có" : selectedTask.title;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Công việc tiên quyết (Bắt buộc hoàn thành trước)", style: GoogleFonts.nunito(color: _txt(isDark), fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 10),
        InkWell(
          onTap: () => _showDependencyPicker(isDark, candidates),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: _input(isDark),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _border(isDark), width: 1.2),
            ),
            child: Row(
              children: [
                const Icon(Icons.link_rounded, color: Colors.blueAccent, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.nunito(
                      color: selectedTask == null ? _sub(isDark) : _txt(isDark),
                      fontSize: 14,
                      fontWeight: selectedTask == null ? FontWeight.normal : FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_dependencyTaskId != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.clear, size: 18, color: Colors.redAccent),
                    onPressed: () {
                      setState(() {
                        _dependencyTaskId = null;
                      });
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
                const SizedBox(width: 8),
                Icon(Icons.arrow_drop_down, color: _sub(isDark), size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showDependencyPicker(bool isDark, List<Task> candidates) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _bg(isDark),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16))),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Chọn công việc tiên quyết",
                style: GoogleFonts.nunito(color: _txt(isDark), fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.block, color: Colors.grey),
                title: Text("Không có", style: GoogleFonts.nunito(color: _txt(isDark))),
                onTap: () {
                  setState(() {
                    _dependencyTaskId = null;
                  });
                  Navigator.pop(ctx);
                },
              ),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: candidates.length,
                  itemBuilder: (context, index) {
                    final t = candidates[index];
                    final isSelected = t.task_id == _dependencyTaskId;
                    return ListTile(
                      leading: Icon(
                        t.status == 'completed' ? Icons.check_circle_outline : Icons.pending_actions_rounded,
                        color: t.status == 'completed' ? Colors.green : Colors.blue,
                      ),
                      title: Text(
                        t.title,
                        style: GoogleFonts.nunito(
                          color: _txt(isDark),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      trailing: isSelected ? const Icon(Icons.check, color: Colors.blue) : null,
                      onTap: () {
                        setState(() {
                          _dependencyTaskId = t.task_id;
                        });
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
