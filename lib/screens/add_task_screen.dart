import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/task_model.dart';
import '../provider/task_provider.dart';
import '../provider/app_provider.dart';

class AddTaskScreen extends StatefulWidget {
  final String? projectId;
  final bool isDialog;
  final DateTime? initialDate;
  const AddTaskScreen({
    super.key,
    this.projectId,
    this.isDialog = false,
    this.initialDate,
  });
  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _category = 'Cá nhân';
  int _priority = 1;
  final List<String> _attachments = [];

  late DateTime _startTime;
  late DateTime _endTime;
  String? _dependencyTaskId;

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
    _startTime = widget.initialDate ?? DateTime.now();
    _endTime = _startTime.add(const Duration(hours: 1));
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    final user = FirebaseAuth.instance.currentUser;
    final now = DateTime.now();
    final task = Task(
      task_id: const Uuid().v4(),
      user_id: user?.uid ?? 'guest',
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      due_day: _startTime,
      priority: _priority,
      progress: 0,
      duration: _endTime.difference(_startTime).inMinutes,
      deadline: _endTime,
      status: 'pending',
      createdAt: now,
      updatedAt: now,
      category: _category,
      project_id: widget.projectId,
      attachments: _attachments,
      dependencyTaskId: _dependencyTaskId,
    );

    final provider = context.read<TaskProvider>();
    
    if (widget.projectId != null) {
      final project = provider.projects.where((p) => p.project_id == widget.projectId).firstOrNull;
      if (project != null && project.startDate != null) {
        if (_startTime.isBefore(project.startDate!)) {
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
    } else {
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
                    style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 17, color: _txt(isDarkNow)),
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
                  style: GoogleFonts.nunito(fontSize: 14, height: 1.5, color: _txt(isDarkNow)),
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
                  style: GoogleFonts.nunito(fontSize: 14, height: 1.5, color: _txt(isDarkNow)),
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
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(
                  "Có, thêm vào",
                  style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
        if (confirm != true) return;
      }
    }

    await provider.addTask(task);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<AppProvider>(context).themeMode == ThemeMode.dark;
    final size = MediaQuery.of(context).size;
    final isWeb = MediaQuery.of(context).size.width > 900;

    Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(isDark),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMetaRow(isDark, isWeb),
                    const SizedBox(height: 20),
                    _buildGoldenHourSuggestion(isDark),
                    _buildTitleInput(isDark),
                    const SizedBox(height: 20),
                    _buildDescriptionSection(isDark),
                    const SizedBox(height: 20),
                    _buildDependencySelector(isDark),
                  ],
                ),
              ),
            ),
          ),
        ),
        _buildFooter(isDark),
      ],
    );

    if (widget.isDialog) {
      return Dialog(
        backgroundColor: _bg(isDark),
        insetPadding: EdgeInsets.symmetric(horizontal: isWeb ? size.width * 0.2 : 16, vertical: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: _border(isDark), width: 1.5),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: size.height * 0.85, maxWidth: 800),
          child: content,
        ),
      );
    }
    return Scaffold(backgroundColor: _bg(isDark), body: SafeArea(child: content));
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      decoration: BoxDecoration(
        color: _headerBg(isDark),
        border: Border(bottom: BorderSide(color: _border(isDark))),
        borderRadius: widget.isDialog ? const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)) : null,
      ),
      child: Row(
        children: [
          Icon(Icons.add_task_rounded, color: ghBlue, size: 26),
          const SizedBox(width: 12),
          Text("ĐẦU VIỆC MỚI", style: GoogleFonts.nunito(color: _txt(isDark), fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
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

  Widget _buildMetaRow(bool isDark, bool isWeb) {
    if (isWeb) {
      return Row(
        children: [
          Expanded(child: _metaBtn(Icons.label_outline, _category, () => _showCategoryPicker(isDark), isDark)),
          const SizedBox(width: 12),
          Expanded(child: _buildPrioritySelector(isDark)),
          const SizedBox(width: 12),
          Expanded(child: _buildTimeSelector(isDark)),
        ],
      );
    }
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _metaBtn(Icons.label_outline, _category, () => _showCategoryPicker(isDark), isDark)),
            const SizedBox(width: 12),
            Expanded(child: _buildPrioritySelector(isDark)),
          ],
        ),
        const SizedBox(height: 12),
        _buildTimeSelector(isDark),
      ],
    );
  }

  Widget _buildPrioritySelector(bool isDark) {
    String label = _priority == 1 ? "Thấp" : (_priority == 2 ? "Vừa" : "Cao");
    Color color = _priority == 3 ? Colors.redAccent : (_priority == 2 ? Colors.orange : Colors.blue);
    return _metaBtn(Icons.flag_outlined, "Ưu tiên: $label", () => _showPriorityPicker(isDark), isDark, labelColor: color);
  }

  Widget _buildTimeSelector(bool isDark) {
    return _metaBtn(Icons.access_time, "Giờ: ${DateFormat('HH:mm').format(_startTime)} - ${DateFormat('HH:mm').format(_endTime)}", () => _showTimePicker(isDark), isDark);
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
      margin: const EdgeInsets.only(bottom: 20),
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
          _startTime = DateTime(_startTime.year, _startTime.month, _startTime.day, hour, 0);
          _endTime = _startTime.add(const Duration(hours: 1));
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

  Widget _metaBtn(IconData icon, String label, VoidCallback onTap, bool isDark, {Color? labelColor}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(color: _input(isDark), borderRadius: BorderRadius.circular(10), border: Border.all(color: _border(isDark), width: 1.2)),
        child: Row(
          children: [
            Icon(icon, color: labelColor ?? ghBlue, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(label, style: GoogleFonts.nunito(color: labelColor ?? _txt(isDark), fontSize: 14, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
            Icon(Icons.arrow_drop_down, color: _sub(isDark), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleInput(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Tiêu đề công việc", style: GoogleFonts.nunito(color: _txt(isDark), fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: _input(isDark),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _border(isDark), width: 1.2),
          ),
          child: TextField(
            controller: _titleCtrl,
            style: GoogleFonts.nunito(color: _txt(isDark), fontWeight: FontWeight.bold, fontSize: 18),
            decoration: InputDecoration(
              hintText: "Nhập tiêu đề...",
              hintStyle: GoogleFonts.nunito(color: _sub(isDark).withOpacity(0.5), fontSize: 18),
              isDense: true,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Mô tả chi tiết", style: GoogleFonts.nunito(color: _txt(isDark), fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: _input(isDark),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _border(isDark), width: 1.2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 160,
                color: _input(isDark),
                child: TextField(
                  controller: _descCtrl,
                  maxLines: null,
                  expands: true,
                  style: GoogleFonts.nunito(color: _txt(isDark), fontSize: 15, height: 1.5),
                  decoration: InputDecoration(
                    hintText: "Thêm ghi chú mô tả của bạn tại đây...",
                    hintStyle: GoogleFonts.nunito(color: _sub(isDark).withOpacity(0.5)),
                    contentPadding: const EdgeInsets.all(16),
                    border: InputBorder.none,
                  ),
                ),
              ),
              _buildAttachmentBar(isDark),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAttachmentBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: _border(isDark))), color: _headerBg(isDark).withOpacity(0.5)),
      child: Row(
        children: [
          Expanded(child: _attachments.isEmpty ? Text('Đính kèm tài liệu...', style: GoogleFonts.nunito(color: _sub(isDark), fontSize: 13)) : SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: _attachments.map((f) => _fileChip(f)).toList()))),
          const SizedBox(width: 8),
          IconButton(onPressed: _pickAttachment, icon: Icon(Icons.attach_file, size: 22, color: ghBlue), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
        ],
      ),
    );
  }

  Widget _fileChip(String name) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: ghBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: ghBlue.withOpacity(0.3))),
      child: Row(children: [Text(name, style: GoogleFonts.nunito(color: ghBlue, fontSize: 12, fontWeight: FontWeight.bold)), const SizedBox(width: 6), InkWell(onTap: () => setState(() => _attachments.remove(name)), child: const Icon(Icons.close, size: 16, color: ghBlue))]),
    );
  }

  Widget _buildFooter(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: _border(isDark))),
        color: _headerBg(isDark),
        borderRadius: widget.isDialog ? const BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)) : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14)),
            child: Text("HỦY BỎ", style: GoogleFonts.nunito(color: _sub(isDark), fontWeight: FontWeight.bold, fontSize: 15)),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: ghGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: Text("TẠO MỚI", style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 15)),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAttachment() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result != null) setState(() => _attachments.addAll(result.files.map((e) => e.name)));
  }

  void _showCategoryPicker(bool isDark) {
    final cats = ['Công việc', 'Cá nhân', 'Học tập', 'Ưu tiên', 'Bug', 'Giao diện'];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _bg(isDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Chọn nhãn", textAlign: TextAlign.center, style: GoogleFonts.nunito(color: _txt(isDark), fontWeight: FontWeight.bold, fontSize: 20)),
        content: SizedBox(
          width: 320,
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: cats.map((c) => ActionChip(
              label: Text(c, style: GoogleFonts.nunito(fontSize: 15)),
              onPressed: () { setState(() => _category = c); Navigator.pop(ctx); },
              backgroundColor: _category == c ? ghBlue : _input(isDark),
              labelStyle: GoogleFonts.nunito(color: _category == c ? Colors.white : _txt(isDark), fontWeight: FontWeight.bold),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            )).toList(),
          ),
        ),
      ),
    );
  }

  void _showPriorityPicker(bool isDark) {
    final prios = [{'v': 1, 'l': 'Thấp', 'c': Colors.blue}, {'v': 2, 'l': 'Vừa', 'c': Colors.orange}, {'v': 3, 'l': 'Cao', 'c': Colors.redAccent}];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _bg(isDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Độ ưu tiên", textAlign: TextAlign.center, style: GoogleFonts.nunito(color: _txt(isDark), fontWeight: FontWeight.bold, fontSize: 20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: prios.map((p) => ListTile(
            leading: Icon(Icons.flag_rounded, color: p['c'] as Color, size: 26),
            title: Text(p['l'] as String, style: GoogleFonts.nunito(color: p['c'] as Color, fontWeight: FontWeight.bold, fontSize: 16)),
            trailing: _priority == p['v'] ? Icon(Icons.check_circle_rounded, color: p['c'] as Color, size: 24) : null,
            onTap: () { setState(() => _priority = p['v'] as int); Navigator.pop(ctx); },
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          )).toList(),
        ),
      ),
    );
  }

  void _showTimePicker(bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _bg(isDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Cài đặt thời gian', textAlign: TextAlign.center, style: GoogleFonts.nunito(color: _txt(isDark), fontSize: 20, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _timeTile('Giờ bắt đầu', _startTime, (t) {
              setState(() {
                _startTime = DateTime(_startTime.year, _startTime.month, _startTime.day, t.hour, t.minute);
                // Tự động nhảy giờ kết thúc sang 1 tiếng sau
                _endTime = _startTime.add(const Duration(hours: 1));
              });
            }, isDark),
            const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider()),
            _timeTile('Giờ kết thúc', _endTime, (t) => setState(() => _endTime = DateTime(_endTime.year, _endTime.month, _endTime.day, t.hour, t.minute)), isDark),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('XÁC NHẬN', style: GoogleFonts.nunito(fontWeight: FontWeight.bold, color: ghBlue, fontSize: 15))),
        ],
      ),
    );
  }

  Widget _timeTile(String title, DateTime val, Function(TimeOfDay) onSet, bool isDark) {
    return ListTile(
      title: Text(title, style: GoogleFonts.nunito(color: _txt(isDark), fontSize: 15, fontWeight: FontWeight.bold)),
      subtitle: Text(DateFormat('HH:mm').format(val), style: GoogleFonts.nunito(color: ghBlue, fontSize: 16, fontWeight: FontWeight.bold)),
      trailing: Icon(Icons.access_time_filled_rounded, color: ghBlue, size: 24),
      onTap: () async {
        final t = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(val),
          builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: ColorScheme.fromSeed(seedColor: ghBlue)), child: child!),
        );
        if (t != null) onSet(t);
      },
    );
  }

  Widget _buildDependencySelector(bool isDark) {
    if (widget.projectId == null) return const SizedBox.shrink();

    final provider = Provider.of<TaskProvider>(context);
    final projectTasks = provider.tasks.where((t) => t.project_id == widget.projectId).toList();

    if (projectTasks.isEmpty) return const SizedBox.shrink();

    final selectedTask = projectTasks.where((t) => t.task_id == _dependencyTaskId).firstOrNull;
    final label = selectedTask == null ? "Không có" : selectedTask.title;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Công việc tiên quyết (Bắt buộc hoàn thành trước)", style: GoogleFonts.nunito(color: _txt(isDark), fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 10),
        InkWell(
          onTap: () => _showDependencyPicker(isDark, projectTasks),
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

  void _showDependencyPicker(bool isDark, List<Task> tasks) {
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
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final t = tasks[index];
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
