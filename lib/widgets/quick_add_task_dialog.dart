import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/task_model.dart';
import '../provider/task_provider.dart';
import '../provider/app_provider.dart';

class QuickAddTaskDialog extends StatefulWidget {
  final DateTime? initialDate;
  const QuickAddTaskDialog({super.key, this.initialDate});

  @override
  State<QuickAddTaskDialog> createState() => _QuickAddTaskDialogState();
}

class _QuickAddTaskDialogState extends State<QuickAddTaskDialog> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  DateTime _startDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();
  DateTime _endDate = DateTime.now();
  TimeOfDay _endTime =
      TimeOfDay.now().replacing(hour: (TimeOfDay.now().hour + 1) % 24);

  bool _isAllDay = false;
  String _repeat = 'Không lặp lại';
  String _category = 'Công việc';
  String _reminder = 'Không thông báo';

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

  // GitHub Style Colors
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
    if (widget.initialDate != null) {
      _startDate = widget.initialDate!;
      _endDate = widget.initialDate!;
      _startTime = TimeOfDay(
          hour: widget.initialDate!.hour, minute: widget.initialDate!.minute);
      _endTime = TimeOfDay(
          hour: (widget.initialDate!.hour + 1) % 24,
          minute: widget.initialDate!.minute);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark =
        Provider.of<AppProvider>(context).themeMode == ThemeMode.dark;

    return Dialog(
      backgroundColor: _bg(isDark),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: _border(isDark))),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 800),
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
              child: Text("Thêm công việc nhanh",
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
        RichText(
            text: TextSpan(children: [
          TextSpan(
              text: "Tiêu đề ",
              style: TextStyle(
                  color: _txt(isDark),
                  fontWeight: FontWeight.bold,
                  fontSize: 14)),
          const TextSpan(
              text: "*",
              style: TextStyle(
                  color: Colors.redAccent, fontWeight: FontWeight.bold)),
        ])),
        const SizedBox(height: 8),
        TextField(
          controller: _titleController,
          autofocus: true,
          style: TextStyle(color: _txt(isDark)),
          decoration: InputDecoration(
            hintText: "VD: Họp dự án...",
            hintStyle: TextStyle(color: _sub(isDark).withOpacity(0.5)),
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
          const SizedBox(width: 20),
          _metaBtn(_repeat, () {}, isDark,
              icon: Icons
                  .refresh), // Fake placeholder for dropdown logic for now or keep meta style
        ]),
      ],
    );
  }

  Widget _metaBtn(String label, VoidCallback onTap, bool isDark,
      {IconData? icon}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
            color: _headerBg(isDark),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: _border(isDark))),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: _sub(isDark), size: 14),
              const SizedBox(width: 6)
            ],
            Text(label,
                style: TextStyle(
                    color: _txt(isDark),
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
          ],
        ),
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
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: _border(isDark))),
          child: Column(
            children: [
              _buildToolbar(isDark),
              Container(
                height: 150,
                color: _input(isDark),
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
          ),
        ),
      ],
    );
  }

  Widget _buildToolbar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
          color: _headerBg(isDark),
          border: Border(bottom: BorderSide(color: _border(isDark)))),
      child: Row(
        children: [
          Icon(Icons.format_bold, color: _sub(isDark), size: 16),
          const SizedBox(width: 12),
          Icon(Icons.format_italic, color: _sub(isDark), size: 16),
          const SizedBox(width: 12),
          Icon(Icons.format_list_bulleted, color: _sub(isDark), size: 16),
          const SizedBox(width: 12),
          Icon(Icons.link, color: _sub(isDark), size: 16),
        ],
      ),
    );
  }

  Widget _buildFooter(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          border: Border(top: BorderSide(color: _border(isDark)))),
      child: Row(
        children: [
          const Spacer(),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Hủy",
                style: TextStyle(
                    color: _sub(isDark), fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _save,
            style: ElevatedButton.styleFrom(
                backgroundColor: ghGreen,
                foregroundColor: Colors.white,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6))),
            child: const Text("Lưu lại",
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
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

  Future<void> _pickDate(bool isStart) async {
    final initialDate = isStart ? _startDate : _endDate;
    final d = await showDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100));
    if (d != null) {
      setState(() {
        if (isStart) {
          _startDate = d;
          // Nếu ngày kết thúc trước ngày bắt đầu, điều chỉnh lại
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate;
          }
        } else {
          // Nếu chọn ngày kết thúc trước ngày bắt đầu, không cho phép
          if (d.isBefore(_startDate)) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Ngày kết thúc không thể trước ngày bắt đầu')),
            );
          } else {
            _endDate = d;
          }
        }
      });
    }
  }

  Future<void> _pickTime(bool isStart) async {
    final t = await showTimePicker(
        context: context, initialTime: isStart ? _startTime : _endTime);
    if (t != null) {
      setState(() {
        if (isStart) {
          _startTime = t;
          // Nếu cùng ngày và giờ kết thúc trước giờ bắt đầu, điều chỉnh lại
          if (_startDate.year == _endDate.year &&
              _startDate.month == _endDate.month &&
              _startDate.day == _endDate.day &&
              _endTime.hour < _startTime.hour) {
            _endTime = TimeOfDay(
                hour: (_startTime.hour + 1) % 24, minute: _startTime.minute);
          }
        } else {
          // Nếu cùng ngày và giờ kết thúc trước giờ bắt đầu, không cho phép
          if (_startDate.year == _endDate.year &&
              _startDate.month == _endDate.month &&
              _startDate.day == _endDate.day &&
              t.hour < _startTime.hour) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Giờ kết thúc không thể trước giờ bắt đầu')),
            );
          } else {
            _endTime = t;
          }
        }
      });
    }
  }

  void _save() async {
    if (_titleController.text.trim().isEmpty) return;
    try {
      final start = DateTime(_startDate.year, _startDate.month, _startDate.day,
          _startTime.hour, _startTime.minute);
      final deadline = DateTime(_endDate.year, _endDate.month, _endDate.day,
          _endTime.hour, _endTime.minute);
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final task = Task(
        task_id: const Uuid().v4(),
        user_id: user.uid,
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        due_day: start,
        priority: 1,
        progress: 0,
        duration: deadline.difference(start).inMinutes.abs().clamp(15, 1440),
        deadline: deadline,
        status: 'pending',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        category: _category,
        reminder: _reminderOptions[_reminder] ?? 0,
      );
      await context.read<TaskProvider>().addTask(task);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint("Lỗi lưu task: $e");
    }
  }
}
