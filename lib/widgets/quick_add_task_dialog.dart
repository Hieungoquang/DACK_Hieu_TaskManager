import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:google_fonts/google_fonts.dart';
import '../models/task_model.dart';
import '../models/task_category_model.dart';
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

  String? _selectedCategoryId;
  String _reminder = 'Không thông báo';
  int _priority = 1;

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
    if (widget.initialDate != null) {
      _startDate = widget.initialDate!;
      _endDate = widget.initialDate!;
      _startTime = TimeOfDay(hour: widget.initialDate!.hour, minute: widget.initialDate!.minute);
      
      DateTime startDT = DateTime(_startDate.year, _startDate.month, _startDate.day, _startTime.hour, _startTime.minute);
      DateTime endDT = startDT.add(const Duration(hours: 1));
      
      _endTime = TimeOfDay(hour: endDT.hour, minute: endDT.minute);
      _endDate = DateTime(endDT.year, endDT.month, endDT.day);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<AppProvider>(context).themeMode == ThemeMode.dark;
    final size = MediaQuery.of(context).size;
    final isWeb = size.width > 900;
    final provider = context.watch<TaskProvider>();

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
                    _buildMetaRow(isDark, provider),
                    const SizedBox(height: 24),
                    _buildGoldenHourSuggestion(isDark),
                    _buildTimeSection(isDark),
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: _headerBg(isDark),
        border: Border(bottom: BorderSide(color: _border(isDark))),
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
      ),
      child: Row(
        children: [
          const Icon(Icons.bolt, color: Colors.amber, size: 24),
          const SizedBox(width: 12),
          Text("THÊM CÔNG VIỆC NHANH",
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
        Text("Tiêu đề công việc", style: GoogleFonts.nunito(color: _txt(isDark), fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 10),
        TextField(
          controller: _titleController,
          autofocus: true,
          style: GoogleFonts.nunito(color: _txt(isDark), fontWeight: FontWeight.bold, fontSize: 18),
          decoration: InputDecoration(
            hintText: "Nhập tiêu đề...",
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

  Widget _buildMetaRow(bool isDark, TaskProvider provider) {
    final selectedCat = _selectedCategoryId == null
        ? null
        : provider.categories.where((c) => c.id == _selectedCategoryId).firstOrNull;
    final catName = selectedCat?.name ?? 'Chọn nhóm';
    final catColor = selectedCat != null ? Color(selectedCat.colorValue) : ghBlue;

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _metaBtnWithColor(Icons.label_outline, catName, catColor, () => _showCategoryPicker(isDark, provider), isDark)),
            const SizedBox(width: 12),
            Expanded(child: _metaBtn(Icons.notifications_none, _reminder, () => _showReminderPicker(isDark), isDark)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildPrioritySelector(isDark)),
          ],
        ),
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

  Widget _buildPrioritySelector(bool isDark) {
    String label = _priority == 1 ? "Thấp" : (_priority == 2 ? "Vừa" : "Cao");
    Color color = _priority == 3 ? Colors.redAccent : (_priority == 2 ? Colors.orange : Colors.blue);
    return _metaBtn(Icons.flag_outlined, "Ưu tiên: $label", () => _showPriorityPicker(isDark), isDark, labelColor: color);
  }

  void _showPriorityPicker(bool isDark) {
    final prios = [
      {'v': 1, 'l': 'Thấp', 'c': Colors.blue},
      {'v': 2, 'l': 'Vừa', 'c': Colors.orange},
      {'v': 3, 'l': 'Cao', 'c': Colors.redAccent}
    ];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _bg(isDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Độ ưu tiên", textAlign: TextAlign.center, style: GoogleFonts.nunito(color: _txt(isDark), fontWeight: FontWeight.bold, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: prios.map((p) => ListTile(
            leading: Icon(Icons.flag_rounded, color: p['c'] as Color, size: 24),
            title: Text(p['l'] as String, style: GoogleFonts.nunito(color: p['c'] as Color, fontWeight: FontWeight.bold, fontSize: 15)),
            trailing: _priority == p['v'] ? Icon(Icons.check_circle_rounded, color: p['c'] as Color, size: 22) : null,
            onTap: () { setState(() => _priority = p['v'] as int); Navigator.pop(ctx); },
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          )).toList(),
        ),
      ),
    );
  }

  Widget _buildGoldenHourSuggestion(bool isDark) {
    if (_priority != 3) return const SizedBox.shrink();

    final provider = Provider.of<TaskProvider>(context, listen: false);
    final hours = provider.getGoldenHours();
    if (hours.isEmpty) return const SizedBox.shrink();

    final h1 = hours[0];
    final h2 = hours.length > 1 ? hours[1] : (h1 + 4) % 24;

    final formatHour = (int h) => "${h.toString().padLeft(2, '0')}:00 - ${((h + 1) % 24).toString().padLeft(2, '0')}:00";

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: isDark ? 0.1 : 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.4), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.wb_sunny_outlined, color: Colors.amber, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "GỢI Ý KHUNG GIỜ VÀNG TẬP TRUNG",
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.amber[800] ?? Colors.orange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "Đây là một công việc khó! Sắp xếp công việc này vào khung giờ vàng của bạn để hoàn thành hiệu quả nhất:",
            style: GoogleFonts.nunito(
              fontSize: 13,
              color: isDark ? const Color(0xFFC9D1D9) : const Color(0xFF24292F),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            children: [
              _goldenHourChip(formatHour(h1), h1, isDark),
              _goldenHourChip(formatHour(h2), h2, isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _goldenHourChip(String label, int hour, bool isDark) {
    return ActionChip(
      onPressed: () {
        setState(() {
          _startTime = TimeOfDay(hour: hour, minute: 0);
          int endHour = (hour + 1) % 24;
          _endTime = TimeOfDay(hour: endHour, minute: 0);
          if (hour == 23) {
            _endDate = _startDate.add(const Duration(days: 1));
          } else {
            _endDate = _startDate;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Đã áp dụng khung giờ vàng: $label"),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.amber[700],
          ),
        );
      },
      avatar: const Icon(Icons.bolt, color: Colors.amber, size: 14),
      label: Text(
        "Áp dụng $label",
        style: GoogleFonts.nunito(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.amber[300] : Colors.amber[900],
        ),
      ),
      backgroundColor: Colors.amber.withValues(alpha: 0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.amber.withValues(alpha: 0.5)),
      ),
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

  Widget _metaBtn(IconData icon, String label, VoidCallback onTap, bool isDark, {Color? labelColor}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(color: _input(isDark), borderRadius: BorderRadius.circular(8), border: Border.all(color: _border(isDark), width: 1.2)),
        child: Row(
          children: [
            Icon(icon, color: labelColor ?? ghBlue, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(label, style: GoogleFonts.nunito(color: labelColor ?? _txt(isDark), fontSize: 13, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
            Icon(Icons.arrow_drop_down, color: _sub(isDark), size: 18),
          ],
        ),
      ),
    );
  }

  Widget _metaBtnWithColor(IconData icon, String label, Color dotColor, VoidCallback onTap, bool isDark) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: _input(isDark),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _border(isDark), width: 1.2),
        ),
        child: Row(
          children: [
            Container(
              width: 10, height: 10,
              decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
            ),
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
        Text("Mô tả chi tiết", style: GoogleFonts.nunito(color: _txt(isDark), fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: _input(isDark),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _border(isDark), width: 1.2),
          ),
          child: TextField(
            controller: _descController,
            maxLines: 5,
            style: GoogleFonts.nunito(color: _txt(isDark), fontSize: 14, height: 1.5),
            decoration: InputDecoration(
              hintText: "Thêm ghi chú mô tả của bạn tại đây...",
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
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("HỦY", style: GoogleFonts.nunito(color: _sub(isDark), fontWeight: FontWeight.bold, fontSize: 14)),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: _save,
            style: ElevatedButton.styleFrom(backgroundColor: ghGreen, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), elevation: 0),
            child: Text("LƯU LẠI", style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 14)),
          ),
        ],
      ),
    );
  }

  void _showCategoryPicker(bool isDark, TaskProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _bg(isDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Chọn nhóm công việc", textAlign: TextAlign.center, style: GoogleFonts.nunito(color: _txt(isDark), fontWeight: FontWeight.bold, fontSize: 18)),
        content: SizedBox(
          width: 300,
          child: SingleChildScrollView(
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 10,
              children: [
                // Option: không nhóm
                ActionChip(
                  avatar: Container(width: 10, height: 10, decoration: const BoxDecoration(color: Color(0xFF58A6FF), shape: BoxShape.circle)),
                  label: Text("Chung (Mặc định)", style: GoogleFonts.nunito(fontSize: 13)),
                  onPressed: () { setState(() => _selectedCategoryId = null); Navigator.pop(ctx); },
                  backgroundColor: _selectedCategoryId == null ? const Color(0xFF58A6FF).withOpacity(0.15) : _input(isDark),
                  labelStyle: GoogleFonts.nunito(
                    color: _selectedCategoryId == null ? const Color(0xFF58A6FF) : _txt(isDark),
                    fontWeight: _selectedCategoryId == null ? FontWeight.bold : FontWeight.normal,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: _selectedCategoryId == null ? const Color(0xFF58A6FF) : _border(isDark))),
                ),
                ...provider.categories.map((c) {
                  final catColor = Color(c.colorValue);
                  final isSelected = _selectedCategoryId == c.id;
                  return ActionChip(
                    avatar: Container(width: 10, height: 10, decoration: BoxDecoration(color: catColor, shape: BoxShape.circle)),
                    label: Text(c.name, style: GoogleFonts.nunito(fontSize: 13)),
                    onPressed: () { setState(() => _selectedCategoryId = c.id); Navigator.pop(ctx); },
                    backgroundColor: isSelected ? catColor.withOpacity(0.15) : _input(isDark),
                    labelStyle: GoogleFonts.nunito(
                      color: isSelected ? catColor : _txt(isDark),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: isSelected ? catColor : _border(isDark)),
                    ),
                  );
                }),
                ActionChip(
                  avatar: Icon(Icons.add, size: 14, color: _txt(isDark)),
                  label: Text("Thêm nhóm", style: GoogleFonts.nunito(fontSize: 13)),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _showAddCategoryDialog(isDark, provider);
                  },
                  backgroundColor: Colors.grey.withOpacity(0.12),
                  labelStyle: TextStyle(color: _txt(isDark)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: _border(isDark))),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Palette màu (nhất quán với CalendarScreen)
  static const List<Color> _categoryPalette = [
    Color(0xFF1E88E5), Color(0xFF43A047), Color(0xFFFB8C00), Color(0xFF8E24AA),
    Color(0xFF00ACC1), Color(0xFFE91E63), Color(0xFF6D4C41), Color(0xFF00BCD4),
    Color(0xFFFFB300), Color(0xFF3949AB), Color(0xFF7CB342), Color(0xFF6200EA),
    Color(0xFF0097A7), Color(0xFFF4511E), Color(0xFF039BE5),
  ];

  void _showAddCategoryDialog(bool isDark, TaskProvider provider) {
    final controller = TextEditingController();
    Color selectedColor = _categoryPalette[0];
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: _bg(isDark),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(width: 16, height: 16,
                decoration: BoxDecoration(color: selectedColor, shape: BoxShape.circle)),
              const SizedBox(width: 10),
              Text("Tạo nhóm mới",
                style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 17)),
            ],
          ),
          content: SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Tên nhóm",
                  style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.bold, color: _sub(isDark))),
                const SizedBox(height: 8),
                TextField(
                  controller: controller,
                  autofocus: true,
                  onChanged: (_) => setDialogState(() {}),
                  decoration: InputDecoration(
                    hintText: "Nhập tên nhóm...",
                    hintStyle: GoogleFonts.nunito(color: _sub(isDark).withOpacity(0.5)),
                    filled: true, fillColor: _input(isDark),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: _border(isDark))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: _border(isDark))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: ghBlue, width: 2)),
                  ),
                  style: GoogleFonts.nunito(color: _txt(isDark)),
                ),
                const SizedBox(height: 16),
                Text("Màu sắc (đỏ dành riêng cho Dự án)",
                  style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.bold, color: _sub(isDark))),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10, runSpacing: 10,
                  children: _categoryPalette.map((color) => GestureDetector(
                    onTap: () => setDialogState(() => selectedColor = color),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: selectedColor == color ? 34 : 28,
                      height: selectedColor == color ? 34 : 28,
                      decoration: BoxDecoration(
                        color: color, shape: BoxShape.circle,
                        border: selectedColor == color ? Border.all(color: _txt(isDark), width: 2.5) : null,
                        boxShadow: selectedColor == color ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 8, spreadRadius: 1)] : null,
                      ),
                      child: selectedColor == color ? const Icon(Icons.check, color: Colors.white, size: 14) : null,
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 14),
                // Preview
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: selectedColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: selectedColor.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      Container(width: 10, height: 10, decoration: BoxDecoration(color: selectedColor, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Text(
                        controller.text.isEmpty ? "Tên nhóm của bạn" : controller.text,
                        style: GoogleFonts.nunito(color: selectedColor, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx),
              child: Text("Hủy", style: GoogleFonts.nunito(color: _sub(isDark)))),
            ElevatedButton(
              onPressed: () {
                if (controller.text.trim().isEmpty) return;
                final newCat = TaskCategory(
                  id: const Uuid().v4(),
                  name: controller.text.trim(),
                  colorValue: selectedColor.value,
                  userId: auth.FirebaseAuth.instance.currentUser?.uid ?? 'guest',
                );
                provider.addCategory(newCat);
                setState(() => _selectedCategoryId = newCat.id);
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: selectedColor, foregroundColor: Colors.white,
                elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              child: Text("Tạo", style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
            )
          ],
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
    if (d != null) {
      setState(() {
        if (isStart) {
          _startDate = d;
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = d;
        }
      });
    }
  }

  Future<void> _pickTime(bool isStart) async {
    final t = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
      builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: ColorScheme.fromSeed(seedColor: ghBlue)), child: child!),
    );
    if (t != null) {
      setState(() {
        if (isStart) {
          _startTime = t;
          int endHour = (t.hour + 1) % 24;
          _endTime = TimeOfDay(hour: endHour, minute: t.minute);
          
          if (t.hour == 23) {
            _endDate = _startDate.add(const Duration(days: 1));
          } else {
            _endDate = _startDate;
          }
        } else {
          _endTime = t;
        }
      });
    }
  }

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty) return;
    try {
      final start = DateTime(_startDate.year, _startDate.month, _startDate.day, _startTime.hour, _startTime.minute);
      final deadline = DateTime(_endDate.year, _endDate.month, _endDate.day, _endTime.hour, _endTime.minute);
      final user = auth.FirebaseAuth.instance.currentUser;

      final task = Task(
        task_id: const Uuid().v4(),
        user_id: user?.uid ?? 'guest',
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        due_day: start,
        priority: _priority,
        progress: 0,
        duration: deadline.difference(start).inMinutes.abs().clamp(15, 1440),
        deadline: deadline,
        status: 'pending',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        category: 'Công việc',
        reminder: _reminderOptions[_reminder] ?? 0,
        categoryId: _selectedCategoryId,
      );

      final provider = context.read<TaskProvider>();

      final overlappingTask = provider.checkOverlapWithProjectTask(task);
      if (overlappingTask != null) {
        final isDarkNow = Provider.of<AppProvider>(context, listen: false).themeMode == ThemeMode.dark;
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: _bg(isDarkNow),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Trùng lịch dự án",
                    style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 17),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Công việc cá nhân của bạn đang trùng với thời gian thực hiện công việc trong dự án:",
                  style: GoogleFonts.nunito(fontSize: 14, height: 1.5),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.work_outline_rounded, color: Colors.red, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          overlappingTask.title,
                          style: GoogleFonts.nunito(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Bạn có muốn thêm công việc này không?",
                  style: GoogleFonts.nunito(fontSize: 14, height: 1.5),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(
                  "Không",
                  style: GoogleFonts.nunito(color: Colors.grey, fontWeight: FontWeight.bold),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ghBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text("Có, thêm vào", style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
        if (confirm != true) return;
      }

      await provider.addTask(task);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint("Error saving task: $e");
    }
  }
}
