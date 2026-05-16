import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
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

  // Categories với màu sắc
  static const Map<String, Color> _categoryColors = {
    'Công việc': Color(0xFF0969DA), // Xanh
    'Cá nhân': Color(0xFF238636), // Xanh lá
    'Học tập': Color(0xFFA371F7), // Tím
    'Khác': Color(0xFFD29922), // Cam
  };

  // Reminder options
  static const Map<String, int> _reminderOptions = {
    'Không thông báo': 0,
    '15 phút trước': 15,
    '30 phút trước': 30,
    '1 giờ trước': 60,
    '2 giờ trước': 120,
    '1 ngày trước': 1440,
  };

  static const Color ghGreen = Color(0xFF238636);
  static const Color ghBlue = Color(0xFF0969DA);

  Color _bg(bool d) => d ? const Color(0xFF0D1117) : Colors.white;
  Color _headerBg(bool d) =>
      d ? const Color(0xFF0D1117) : const Color(0xFFF6F8FA);
  Color _border(bool d) =>
      d ? const Color(0xFF30363D) : const Color(0xFFD0D7DE);
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: _bg(isDark),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: _border(isDark))),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 760),
        child: Column(
          children: [
            _buildHeader(isDark),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTitleSection(isDark),
                    const SizedBox(height: 24),
                    _buildCategorySection(isDark),
                    const SizedBox(height: 24),
                    _buildTimeSection(isDark),
                    const SizedBox(height: 24),
                    _buildReminderSection(isDark),
                    const SizedBox(height: 24),
                    _buildDescriptionSection(isDark),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
          color: _headerBg(isDark),
          border: Border(bottom: BorderSide(color: _border(isDark))),
          borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12), topRight: Radius.circular(12))),
      child: Row(
        children: [
          Expanded(
              child: Text("Chỉnh sửa công việc",
                  style: TextStyle(
                      color: _txt(isDark),
                      fontSize: 14,
                      fontWeight: FontWeight.bold))),
          IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(Icons.close, color: _sub(isDark), size: 20)),
        ],
      ),
    );
  }

  Widget _buildTitleSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Tên công việc",
            style: TextStyle(
                color: _txt(isDark),
                fontWeight: FontWeight.bold,
                fontSize: 14)),
        const SizedBox(height: 8),
        TextField(
          controller: _titleController,
          autofocus: true,
          style: TextStyle(color: _txt(isDark)),
          decoration: InputDecoration(
            hintText: "Nhập tên công việc...",
            hintStyle: TextStyle(color: _sub(isDark).withValues(alpha: 0.5)),
            filled: true,
            fillColor: _input(isDark),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: _border(isDark))),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: ghBlue, width: 2)),
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Phân loại",
            style: TextStyle(
                color: _txt(isDark),
                fontWeight: FontWeight.bold,
                fontSize: 14)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _categoryColors.entries.map((entry) {
            final isSelected = _category == entry.key;
            return InkWell(
              onTap: () => setState(() => _category = entry.key),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? entry.value : _headerBg(isDark),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? entry.value : _border(isDark),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: entry.value,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      entry.key,
                      style: TextStyle(
                        color: isSelected ? Colors.white : _txt(isDark),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildReminderSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Thông báo trước",
            style: TextStyle(
                color: _txt(isDark),
                fontWeight: FontWeight.bold,
                fontSize: 14)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _reminderOptions.entries.map((entry) {
            final isSelected = _reminder == entry.key;
            return InkWell(
              onTap: () => setState(() => _reminder = entry.key),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? ghBlue : _headerBg(isDark),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? ghBlue : _border(isDark),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Text(
                  entry.key,
                  style: TextStyle(
                    color: isSelected ? Colors.white : _txt(isDark),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTimeSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Thời gian",
            style: TextStyle(
                color: _txt(isDark),
                fontWeight: FontWeight.bold,
                fontSize: 14)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _metaBtn(DateFormat('dd/MM/yyyy').format(_startDate),
                () => _pickDate(true), isDark),
            _metaBtn(_startTime.format(context), () => _pickTime(true), isDark),
            Text("tới", style: TextStyle(color: _sub(isDark), fontSize: 13)),
            _metaBtn(_endTime.format(context), () => _pickTime(false), isDark),
            _metaBtn(DateFormat('dd/MM/yyyy').format(_endDate),
                () => _pickDate(false), isDark),
          ],
        ),
        const SizedBox(height: 16),
        Row(children: [
          _checkbox("Cả ngày", _isAllDay, (v) {
            setState(() {
              _isAllDay = v!;
              if (_isAllDay) {
                _startTime = const TimeOfDay(hour: 0, minute: 0);
                _endTime = const TimeOfDay(hour: 23, minute: 59);
              }
            });
          }, isDark),
        ]),
      ],
    );
  }

  Widget _checkbox(
      String label, bool value, Function(bool?) onChange, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
              value: value,
              onChanged: onChange,
              activeColor: ghBlue,
              side: BorderSide(color: _sub(isDark))),
        ),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: _txt(isDark), fontSize: 13)),
      ],
    );
  }

  Widget _metaBtn(String label, VoidCallback onTap, bool isDark) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
            color: _headerBg(isDark),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: _border(isDark))),
        child: Text(label,
            style: TextStyle(
                color: _txt(isDark),
                fontSize: 13,
                fontWeight: FontWeight.w500)),
      ),
    );
  }

  Widget _buildDescriptionSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Mô tả",
            style: TextStyle(
                color: _txt(isDark),
                fontWeight: FontWeight.bold,
                fontSize: 14)),
        const SizedBox(height: 8),
        Container(
          height: 180,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: _border(isDark)),
              color: _input(isDark)),
          child: TextField(
            controller: _descController,
            maxLines: null,
            expands: true,
            style: TextStyle(color: _txt(isDark), fontSize: 14),
            decoration: InputDecoration(
              hintText: "Thêm mô tả...",
              hintStyle: TextStyle(color: _sub(isDark), fontSize: 14),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          border: Border(top: BorderSide(color: _border(isDark)))),
      child: Row(
        children: [
          ElevatedButton(
            onPressed: _deleteTask,
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6))),
            child: const Text("Xóa",
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const Spacer(),
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Hủy",
                  style: TextStyle(
                      color: _sub(isDark), fontWeight: FontWeight.bold))),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _save,
            style: ElevatedButton.styleFrom(
                backgroundColor: ghGreen,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6))),
            child: const Text("Lưu",
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate(bool isStart) async {
    final d = await showDatePicker(
        context: context,
        initialDate: isStart ? _startDate : _endDate,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100));
    if (d != null) setState(() => isStart ? _startDate = d : _endDate = d);
  }

  Future<void> _pickTime(bool isStart) async {
    final t = await showTimePicker(
        context: context, initialTime: isStart ? _startTime : _endTime);
    if (t != null) setState(() => isStart ? _startTime = t : _endTime = t);
  }

  void _save() async {
    if (_titleController.text.trim().isEmpty) return;

    try {
      final start = DateTime(_startDate.year, _startDate.month, _startDate.day,
          _startTime.hour, _startTime.minute);
      final deadline = DateTime(_endDate.year, _endDate.month, _endDate.day,
          _endTime.hour, _endTime.minute);

      widget.task.title = _titleController.text.trim();
      widget.task.description = _descController.text.trim();
      widget.task.category = _category;
      widget.task.reminder = _reminderOptions[_reminder] ?? 0;
      widget.task.due_day = start;
      widget.task.deadline = deadline;
      widget.task.duration =
          deadline.difference(start).inMinutes.abs().clamp(15, 1440);
      widget.task.updatedAt = DateTime.now();
      widget.task.isSynced = false;

      await context.read<TaskProvider>().updateTask(widget.task);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint("Lỗi lưu task: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi lưu: $e')),
        );
      }
    }
  }

  void _deleteTask() async {
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: _bg(
              Provider.of<AppProvider>(context).themeMode == ThemeMode.dark),
          title: const Text("Xóa công việc"),
          content: const Text("Bạn có chắc muốn xóa công việc này không?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Hủy"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text("Xóa"),
            ),
          ],
        ),
      );
      if (confirmed == true && mounted) {
        await context.read<TaskProvider>().deleteTask(widget.task.task_id);
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      debugPrint("Lỗi xóa task: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi xóa: $e')),
        );
      }
    }
  }
}
