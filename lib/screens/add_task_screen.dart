import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/task_model.dart';
import '../provider/task_provider.dart';
import '../provider/app_provider.dart';
import '../widgets/app_popup.dart';

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
  bool _isPreview = false;
  bool _createMore = false;
  String _category = 'Cá nhân';
  int _priority = 1;
  final List<String> _attachments = [];

  late DateTime _startTime;
  late DateTime _endTime;

  // GitHub Style Colors
  static const Color ghGreen = Color(0xFF238636);
  static const Color ghBlue = Color(0xFF0969DA);

  Color _bg(bool d) => d ? const Color(0xFF0D1117) : Colors.white;
  Color _headerBg(bool d) =>
      d ? const Color(0xFF0D1117) : const Color(0xFFF6F8FA);
  Color _border(bool d) =>
      d ? const Color(0xFF30363D) : const Color(0xFFD0D7DE);
  Color _input(bool d) => d ? const Color(0xFF010409) : Colors.white;
  Color _tabActive(bool d) => d ? const Color(0xFF161B22) : Colors.white;
  Color _txt(bool d) => d ? const Color(0xFFC9D1D9) : const Color(0xFF24292F);
  Color _sub(bool d) => d ? const Color(0xFF8B949E) : const Color(0xFF57606A);

  @override
  void initState() {
    super.initState();
    _startTime = widget.initialDate ?? DateTime.now();
    _endTime = widget.initialDate?.add(const Duration(hours: 1)) ??
        DateTime.now().add(const Duration(hours: 1));
  }

  void _save() async {
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
      category: _category == 'Nhãn' ? 'Công việc' : _category,
      project_id: widget.projectId,
      attachments: _attachments,
    );

    await context.read<TaskProvider>().addTask(task);

    if (_createMore) {
      _titleCtrl.clear();
      _descCtrl.clear();
      _attachments.clear();
      setState(() {});
      _showSuccessSnackBar();
    } else {
      if (mounted) {
        Navigator.pop(context);
        _showSuccessDialog(context);
      }
    }
  }

  void _showSuccessSnackBar() {
    AppPopup.success(context, "Đã tạo công việc thành công!");
  }

  void _showSuccessDialog(BuildContext context) {
    final isDark = Provider.of<AppProvider>(context, listen: false).themeMode ==
        ThemeMode.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _bg(isDark),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: _border(isDark)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ghGreen.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_outline,
                color: ghGreen,
                size: 60,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Thành công!",
              style: TextStyle(
                color: _txt(isDark),
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Công việc của bạn đã được khởi tạo và lưu trữ thành công.",
              textAlign: TextAlign.center,
              style: TextStyle(color: _sub(isDark), fontSize: 14),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ghGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  "TUYỆT VỜI",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark =
        Provider.of<AppProvider>(context).themeMode == ThemeMode.dark;
    final isWeb = MediaQuery.of(context).size.width > 900;

    Widget body = Column(
      children: [
        _buildHeader(isDark),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isWeb ? 24 : 20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTitleInput(isDark, isWeb),
                    const SizedBox(height: 16),
                    _buildDescriptionSection(isDark),
                    const SizedBox(height: 16),
                    _buildMetaActions(isDark),
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
        insetPadding: EdgeInsets.symmetric(
          horizontal: isWeb ? 100 : 16,
          vertical: 24,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: _border(isDark)),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
            maxWidth: isWeb ? 900 : MediaQuery.of(context).size.width - 32,
          ),
          child: body,
        ),
      );
    }

    return Scaffold(backgroundColor: _bg(isDark), body: body);
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _headerBg(isDark),
        border: Border(bottom: BorderSide(color: _border(isDark))),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              "Tạo đầu việc mới",
              style: TextStyle(
                color: _txt(isDark),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.close, color: _sub(isDark), size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleInput(bool isDark, bool isWeb) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: "Thêm tiêu đề ",
                style: TextStyle(
                  color: _txt(isDark),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const TextSpan(
                text: "*",
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _titleCtrl,
          autofocus: true,
          style: TextStyle(color: _txt(isDark)),
          decoration: InputDecoration(
            hintText: "Nhập tiêu đề...",
            hintStyle: TextStyle(color: _sub(isDark).withOpacity(0.5)),
            filled: true,
            fillColor: _input(isDark),
            contentPadding: EdgeInsets.symmetric(
              horizontal: isWeb ? 24 : 20,
              vertical: isWeb ? 28 : 18,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: _border(isDark)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: Color(0xFF0969DA), width: 2),
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
        Text(
          "Thêm mô tả",
          style: TextStyle(
            color: _txt(isDark),
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: _border(isDark)),
          ),
          child: Column(
            children: [
              _buildTabHeader(isDark),
              if (!_isPreview) ...[
                _buildToolbar(isDark),
                Container(
                  height: 300,
                  color: _input(isDark),
                  child: TextField(
                    controller: _descCtrl,
                    maxLines: null,
                    expands: true,
                    style: TextStyle(color: _txt(isDark), fontSize: 14),
                    decoration: InputDecoration(
                      hintText: "Nhập mô tả của bạn tại đây...",
                      hintStyle: TextStyle(color: _sub(isDark), fontSize: 14),
                      contentPadding: const EdgeInsets.all(16),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                _buildAttachmentBar(isDark),
              ] else
                Container(
                  height: 350,
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: _bg(isDark),
                  child: Text(
                    _descCtrl.text.isEmpty
                        ? "Không có gì để xem trước"
                        : _descCtrl.text,
                    style: TextStyle(color: _sub(isDark)),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.only(left: 8, top: 8),
      child: Row(
        children: [
          _tabItem(
            "Viết",
            !_isPreview,
            () => setState(() => _isPreview = false),
            isDark,
          ),
          _tabItem(
            "Xem trước",
            _isPreview,
            () => setState(() => _isPreview = true),
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _tabItem(String label, bool active, VoidCallback onTap, bool isDark) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: active ? _tabActive(isDark) : Colors.transparent,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(6),
            topRight: Radius.circular(6),
          ),
          border: active
              ? Border(
                  left: BorderSide(color: _border(isDark)),
                  right: BorderSide(color: _border(isDark)),
                  top: BorderSide(color: _border(isDark)),
                )
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: _txt(isDark),
            fontSize: 13,
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildToolbar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: _border(isDark)),
          bottom: BorderSide(color: _border(isDark)),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.title, color: _sub(isDark), size: 18),
          const SizedBox(width: 16),
          Icon(Icons.format_bold, color: _sub(isDark), size: 18),
          const SizedBox(width: 16),
          Icon(Icons.format_italic, color: _sub(isDark), size: 18),
          const SizedBox(width: 16),
          Icon(Icons.format_list_bulleted, color: _sub(isDark), size: 18),
          const SizedBox(width: 16),
          Icon(Icons.code, color: _sub(isDark), size: 18),
          const SizedBox(width: 16),
          Icon(Icons.link, color: _sub(isDark), size: 18),
        ],
      ),
    );
  }

  Widget _buildAttachmentBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: _border(isDark))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ..._attachments.map(
                (file) => Chip(
                  label: Text(file,
                      style: TextStyle(color: _txt(isDark), fontSize: 12)),
                  deleteIcon: Icon(Icons.close, size: 16, color: _sub(isDark)),
                  onDeleted: () => setState(() => _attachments.remove(file)),
                  backgroundColor: _tabActive(isDark).withValues(alpha: 0.5),
                ),
              ),
              InkWell(
                onTap: _pickAttachment,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: _border(isDark)),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.upload_file, size: 16, color: _sub(isDark)),
                      const SizedBox(width: 6),
                      Text(
                        'Đính kèm',
                        style: TextStyle(color: _txt(isDark), fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_attachments.isEmpty)
            Text(
              'Chưa có tệp đính kèm',
              style: TextStyle(color: _sub(isDark), fontSize: 12),
            ),
        ],
      ),
    );
  }

  Widget _buildMetaActions(bool isDark) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _metaBtn(
          Icons.label_outline,
          _category,
          () => _showCategoryPicker(isDark),
          isDark,
        ),
        _metaBtn(
          Icons.flag_outlined,
          "Độ ưu tiên",
          () => _showPriorityPicker(isDark),
          isDark,
        ),
        _metaBtn(
          Icons.access_time,
          "${DateFormat('HH:mm').format(_startTime)} - ${DateFormat('HH:mm').format(_endTime)}",
          () => _showTimePicker(isDark),
          isDark,
        ),
      ],
    );
  }

  Widget _metaBtn(
    IconData icon,
    String label,
    VoidCallback? onTap,
    bool isDark,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _headerBg(isDark),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _border(isDark)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: _sub(isDark), size: 16),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: _sub(isDark),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: _border(isDark))),
      ),
      child: Row(
        children: [
          const Spacer(),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Hủy",
              style: TextStyle(
                color: _sub(isDark),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          _buildCreateButton(),
        ],
      ),
    );
  }

  Widget _buildCreateButton() {
    return Container(
      decoration: BoxDecoration(
        color: ghGreen,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: _save,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: const Text(
                "Tạo",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const VerticalDivider(width: 1, color: Colors.white24),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Icon(
              Icons.keyboard_arrow_down,
              color: Colors.white,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAttachment() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
    );
    if (result != null) {
      setState(() {
        _attachments.addAll(result.files.map((e) => e.name));
      });
    }
  }

  void _showCategoryPicker(bool isDark) {
    final categories = [
      'Công việc',
      'Cá nhân',
      'Học tập',
      'Ưu tiên',
      'Bug',
      'Giao diện',
    ];
    showDialog(
      context: context,
      builder: (ctx) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 420,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _bg(isDark),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _border(isDark)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Chọn nhãn",
                  style: TextStyle(
                    color: _txt(isDark),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: categories
                      .map(
                        (c) => InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () {
                            setState(() => _category = c);
                            Navigator.pop(ctx);
                          },
                          child: Chip(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            label: Text(
                              c,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            backgroundColor: ghBlue,
                            side: BorderSide.none,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showTimePicker(bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _bg(isDark),
        title: Text(
          'Chọn thời gian',
          style: TextStyle(color: _txt(isDark)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                'Thời gian bắt đầu',
                style: TextStyle(color: _txt(isDark)),
              ),
              subtitle: Text(
                DateFormat('HH:mm dd/MM/yyyy').format(_startTime),
                style: TextStyle(color: _sub(isDark)),
              ),
              trailing: Icon(Icons.access_time, color: ghBlue),
              onTap: () async {
                final TimeOfDay? time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.fromDateTime(_startTime),
                );
                if (time != null) {
                  setState(() {
                    _startTime = DateTime(
                      _startTime.year,
                      _startTime.month,
                      _startTime.day,
                      time.hour,
                      time.minute,
                    );
                  });
                }
              },
            ),
            ListTile(
              title: Text(
                'Thời gian kết thúc',
                style: TextStyle(color: _txt(isDark)),
              ),
              subtitle: Text(
                DateFormat('HH:mm dd/MM/yyyy').format(_endTime),
                style: TextStyle(color: _sub(isDark)),
              ),
              trailing: Icon(Icons.access_time, color: ghGreen),
              onTap: () async {
                final TimeOfDay? time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.fromDateTime(_endTime),
                );
                if (time != null) {
                  setState(() {
                    _endTime = DateTime(
                      _endTime.year,
                      _endTime.month,
                      _endTime.day,
                      time.hour,
                      time.minute,
                    );
                  });
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Đóng',
              style: TextStyle(color: _sub(isDark)),
            ),
          ),
        ],
      ),
    );
  }

  void _showPriorityPicker(bool isDark) {
    final priorities = [
      {'val': 1, 'label': 'Thấp', 'color': Colors.blue},
      {'val': 2, 'label': 'Vừa', 'color': Colors.orange},
      {'val': 3, 'label': 'Cao', 'color': Colors.redAccent},
    ];
    showDialog(
      context: context,
      builder: (ctx) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 340,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _bg(isDark),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _border(isDark)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Chọn cột mốc",
                  style: TextStyle(
                    color: _txt(isDark),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 14),
                ...priorities.map((p) {
                  final color = p['color'] as Color;
                  final selected = _priority == p['val'];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        setState(() => _priority = p['val'] as int);
                        Navigator.pop(ctx);
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? color.withOpacity(0.12)
                              : _headerBg(isDark),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected ? color : _border(isDark),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                p['label'] as String,
                                style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (selected)
                              Icon(Icons.check, color: color, size: 18),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
