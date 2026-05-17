import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/task_model.dart';
import '../provider/task_provider.dart';
import '../widgets/web_sidebar.dart';

class TaskDetailScreen extends StatefulWidget {
  final Task task;

  const TaskDetailScreen({super.key, required this.task});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final List<String> attachments = [];
  final List<Map<String, dynamic>> comments = [];
  final TextEditingController _commentController = TextEditingController();
  bool _previewComment = false;

  // GitHub Style Colors
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
  static const Color ghBlue = Color(0xFF0969DA);

  Color bgColor = ghLightBg;
  Color cardColor = ghLightCard;
  Color textColor = ghLightText;
  Color secondaryText = ghLightSubText;
  Color borderColor = ghLightBorder;

  @override
  void initState() {
    super.initState();
    // Safety check for null fields from storage
    if (widget.task.attachments != null) {
      attachments.addAll(widget.task.attachments);
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _editCategory() async {
    final categories = ['Công việc', 'Cá nhân', 'Học tập', 'Ưu tiên', 'Bug', 'Giao diện'];
    final selected = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Chọn nhãn",
          textAlign: TextAlign.center,
          style: GoogleFonts.nunito(fontWeight: FontWeight.bold, color: textColor),
        ),
        content: SizedBox(
          width: 300,
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: categories
                .map((cat) => ActionChip(
                      label: Text(cat, style: GoogleFonts.nunito(fontSize: 14)),
                      onPressed: () => Navigator.pop(context, cat),
                      backgroundColor: widget.task.category == cat ? ghBlue : cardColor,
                      labelStyle: GoogleFonts.nunito(
                        color: widget.task.category == cat ? Colors.white : textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ))
                .toList(),
          ),
        ),
      ),
    );
    if (selected != null && mounted) {
      setState(() {
        widget.task.category = selected;
        widget.task.updatedAt = DateTime.now();
      });
    }
  }

  void _editTaskDate(String field) async {
    DateTime? current = field == 'start' ? widget.task.due_day : widget.task.deadline;
    DateTime initialDate = current ?? DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: ColorScheme.fromSeed(seedColor: ghBlue)), child: child!),
    );

    if (picked != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDate),
      );

      if (time != null && mounted) {
        final finalDateTime = DateTime(picked.year, picked.month, picked.day, time.hour, time.minute);
        
        if (field == 'start' && widget.task.project_id != null) {
          final provider = context.read<TaskProvider>();
          final project = provider.projects.where((p) => p.project_id == widget.task.project_id).firstOrNull;
          if (project != null && project.startDate != null && finalDateTime.isBefore(project.startDate!)) {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: cardColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Colors.red, size: 24),
                    const SizedBox(width: 8),
                    Text("Lỗi thời gian", style: GoogleFonts.nunito(fontWeight: FontWeight.bold, color: textColor)),
                  ],
                ),
                content: Text(
                  "Thời gian bắt đầu công việc phải trùng hoặc sau thời gian bắt đầu dự án (${DateFormat('dd/MM/yyyy HH:mm').format(project.startDate!)}).",
                  style: GoogleFonts.nunito(color: textColor, fontSize: 14, height: 1.5),
                ),
                actions: [
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(backgroundColor: ghBlue, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    child: Text("Đã hiểu", style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
            return;
          }
        }

        setState(() {
          if (field == 'start') {
            widget.task.due_day = finalDateTime;
          } else {
            widget.task.deadline = finalDateTime;
          }
          widget.task.updatedAt = DateTime.now();
        });
      }
    }
  }

  void _saveTask() async {
    if (widget.task.project_id != null) {
      final provider = context.read<TaskProvider>();
      final project = provider.projects.where((p) => p.project_id == widget.task.project_id).firstOrNull;
      if (project != null && project.startDate != null && widget.task.due_day.isBefore(project.startDate!)) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: cardColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.red, size: 24),
                const SizedBox(width: 8),
                Text("Lỗi thời gian", style: GoogleFonts.nunito(fontWeight: FontWeight.bold, color: textColor)),
              ],
            ),
            content: Text(
              "Thời gian bắt đầu công việc phải trùng hoặc sau thời gian bắt đầu dự án (${DateFormat('dd/MM/yyyy HH:mm').format(project.startDate!)}).",
              style: GoogleFonts.nunito(color: textColor, fontSize: 14, height: 1.5),
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(backgroundColor: ghBlue, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                child: Text("Đã hiểu", style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
        return;
      }
    }

    widget.task.attachments = List<String>.from(attachments);
    widget.task.updatedAt = DateTime.now();
    // Ensure attachments list is initialized
    widget.task.attachments ??= [];
    
    await context.read<TaskProvider>().updateTask(widget.task);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã lưu thay đổi thành công')));
    }
  }

  void _deleteTask() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Xác nhận xóa', style: GoogleFonts.nunito(fontWeight: FontWeight.bold, color: textColor)),
        content: Text('Bạn có chắc chắn muốn xóa công việc này không?', style: GoogleFonts.nunito(color: textColor)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Hủy', style: GoogleFonts.nunito(color: secondaryText))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, elevation: 0),
            child: Text('Xóa', style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await context.read<TaskProvider>().deleteTask(widget.task.task_id);
      if (mounted) Navigator.pop(context);
    }
  }

  Widget buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black.withOpacity(0.02))],
      ),
      child: child,
    );
  }

  Widget sectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.bold, color: secondaryText, letterSpacing: 1),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWeb = width > 900;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    bgColor = isDark ? ghDarkBg : ghLightBg;
    cardColor = isDark ? ghDarkCard : ghLightCard;
    textColor = isDark ? ghDarkText : ghLightText;
    secondaryText = isDark ? ghDarkSubText : ghLightSubText;
    borderColor = isDark ? ghDarkBorder : ghLightBorder;

    return Scaffold(
      backgroundColor: bgColor,
      body: Row(
        children: [
          if (isWeb) const WebSidebar(currentRoute: 'home'),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: SafeArea(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(horizontal: isWeb ? 40 : 16, vertical: 20),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 900),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildHeader(isWeb),
                              const SizedBox(height: 24),
                              _buildDependencyCard(),
                              const SizedBox(height: 24),
                              _buildMetaSection(),
                              const SizedBox(height: 24),
                              _buildDescriptionDisplay(),
                              const SizedBox(height: 24),
                              _buildAttachmentsDisplay(),
                              const SizedBox(height: 24),
                              _buildActivityCard(),
                              const SizedBox(height: 40),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                _buildBottomActions(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isWeb) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isWeb) IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.task.title ?? "Không có tiêu đề",
                style: GoogleFonts.nunito(fontSize: 24, fontWeight: FontWeight.bold, color: textColor),
              ),
              const SizedBox(height: 8),
              Text(
                "Đã tạo vào ${widget.task.createdAt != null ? DateFormat('dd/MM/yyyy HH:mm').format(widget.task.createdAt) : 'N/A'}",
                style: GoogleFonts.nunito(color: secondaryText, fontSize: 14),
              ),
            ],
          ),
        ),
        _buildStatusMenu(),
      ],
    );
  }

  Widget _buildStatusMenu() {
    final statuses = {
      'pending': 'Cần làm',
      'in_progress': 'Đang làm',
      'completed': 'Hoàn thành',
    };

    String currentStatus = widget.task.status ?? 'pending';
    final provider = Provider.of<TaskProvider>(context, listen: false);
    final isLocked = provider.isTaskLocked(widget.task);

    return PopupMenuButton<String>(
      onSelected: (value) {
        if (isLocked && value == 'completed') {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  const Icon(Icons.lock, color: Colors.redAccent),
                  const SizedBox(width: 8),
                  Text("Công việc đang bị khóa", style: GoogleFonts.nunito(fontWeight: FontWeight.bold, color: textColor)),
                ],
              ),
              content: Text(
                "Bạn không thể hoàn thành công việc này vì nó phụ thuộc vào công việc tiên quyết chưa hoàn thành.",
                style: GoogleFonts.nunito(color: textColor, height: 1.5),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text("Đã hiểu", style: GoogleFonts.nunito(color: ghBlue, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
          return;
        }
        setState(() {
          widget.task.status = value;
          if (value == 'completed') widget.task.progress = 100;
        });
      },
      itemBuilder: (context) => statuses.entries
          .map((e) => PopupMenuItem(value: e.key, child: Text(e.value, style: GoogleFonts.nunito())))
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: currentStatus == 'completed' ? Colors.green.withOpacity(0.1) : ghBlue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: currentStatus == 'completed' ? Colors.green.withOpacity(0.3) : ghBlue.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              statuses[currentStatus] ?? 'Trạng thái',
              style: GoogleFonts.nunito(
                color: currentStatus == 'completed' ? Colors.green : ghBlue,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            Icon(Icons.arrow_drop_down, color: currentStatus == 'completed' ? Colors.green : ghBlue),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaSection() {
    return buildCard(
      child: Wrap(
        spacing: 30,
        runSpacing: 20,
        children: [
          _metaItem("NHÃN", widget.task.category ?? "Chưa có", Icons.label_outline, _editCategory),
          _metaItem("BẮT ĐẦU", widget.task.due_day != null ? DateFormat('dd/MM/yyyy HH:mm').format(widget.task.due_day) : "N/A", Icons.calendar_today, () => _editTaskDate('start')),
          _metaItem("HẾT HẠN", widget.task.deadline != null ? DateFormat('dd/MM/yyyy HH:mm').format(widget.task.deadline) : "N/A", Icons.access_time, () => _editTaskDate('end')),
        ],
      ),
    );
  }

  Widget _metaItem(String label, String value, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.bold, color: secondaryText)),
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: ghBlue),
              const SizedBox(width: 8),
              Text(value, style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w600, color: textColor)),
              const SizedBox(width: 4),
              Icon(Icons.edit, size: 12, color: secondaryText.withOpacity(0.5)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionDisplay() {
    if (widget.task.description == null || widget.task.description.isEmpty) {
      return const SizedBox.shrink();
    }
    return buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          sectionTitle("Mô tả công việc"),
          const SizedBox(height: 12),
          Text(
            widget.task.description,
            style: GoogleFonts.nunito(fontSize: 15, color: textColor, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentsDisplay() {
    if (attachments.isEmpty) {
      return const SizedBox.shrink();
    }
    return buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          sectionTitle("Tài liệu đính kèm"),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: attachments.map((url) {
              final fileName = Uri.tryParse(url)?.pathSegments.last.split('?').first ?? "Tài liệu";
              return InkWell(
                onTap: () async {
                  final uri = Uri.parse(url);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Không thể mở tệp đính kèm')),
                      );
                    }
                  }
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: ghBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: ghBlue.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.attach_file, size: 16, color: ghBlue),
                      const SizedBox(width: 8),
                      Text(
                        fileName.length > 25 ? '${fileName.substring(0, 25)}...' : fileName,
                        style: GoogleFonts.nunito(fontSize: 14, color: ghBlue, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.download_rounded, size: 18, color: ghBlue),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard() {
    return buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          sectionTitle("Ghi chú công việc"),
          const SizedBox(height: 16),
          _buildEditor(
            ctrl: _commentController,
            isPreview: _previewComment,
            onToggle: (v) => setState(() => _previewComment = v),
            hint: "Nhập ghi chú mới...",
            minHeight: 100,
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () {
                if (_commentController.text.isNotEmpty) {
                  setState(() {
                    comments.add({'text': _commentController.text, 'date': DateTime.now()});
                    _commentController.clear();
                  });
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              child: Text("Thêm ghi chú", style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
            ),
          ),
          if (comments.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Divider(),
            ...comments.reversed.map((c) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(DateFormat('dd/MM/yyyy HH:mm').format(c['date'] as DateTime), style: GoogleFonts.nunito(fontSize: 12, color: secondaryText)),
                  const SizedBox(height: 4),
                  Text(c['text'] as String, style: GoogleFonts.nunito(fontSize: 14, color: textColor)),
                ],
              ),
            )),
          ]
        ],
      ),
    );
  }

  Widget _buildEditor({required TextEditingController ctrl, required bool isPreview, required Function(bool) onToggle, required String hint, double minHeight = 150}) {
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: borderColor)),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(color: bgColor, border: Border(bottom: BorderSide(color: borderColor)), borderRadius: const BorderRadius.vertical(top: Radius.circular(8))),
            child: Row(
              children: [
                _tabItem("Viết", !isPreview, () => onToggle(false)),
                _tabItem("Xem trước", isPreview, () => onToggle(true)),
              ],
            ),
          ),
          if (!isPreview)
            Container(
              height: minHeight,
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: ctrl,
                maxLines: null,
                style: GoogleFonts.nunito(fontSize: 14, color: textColor),
                decoration: InputDecoration(hintText: hint, hintStyle: GoogleFonts.nunito(color: secondaryText.withOpacity(0.5)), border: InputBorder.none),
              ),
            )
          else
            Container(
              width: double.infinity,
              height: minHeight,
              padding: const EdgeInsets.all(12),
              child: SingleChildScrollView(
                child: Text(
                  ctrl.text.isEmpty ? "Không có nội dung để hiển thị" : ctrl.text,
                  style: GoogleFonts.nunito(fontSize: 14, color: textColor, height: 1.5),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _tabItem(String label, bool active, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          border: active ? Border(bottom: BorderSide(color: ghBlue, width: 2)) : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.nunito(fontSize: 13, fontWeight: active ? FontWeight.bold : FontWeight.normal, color: active ? textColor : secondaryText),
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        border: Border(top: BorderSide(color: borderColor)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _deleteTask,
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              label: Text("Xóa công việc", style: GoogleFonts.nunito(color: Colors.red, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _saveTask,
              icon: const Icon(Icons.save_outlined),
              label: Text("Lưu thay đổi", style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: ghBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDependencyCard() {
    if (widget.task.project_id == null) return const SizedBox.shrink();

    final provider = Provider.of<TaskProvider>(context);
    final prereq = provider.getPrerequisiteTask(widget.task);
    final isLocked = provider.isTaskLocked(widget.task);

    return buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          sectionTitle("Chuỗi tự động hóa (Liên kết công việc)"),
          const SizedBox(height: 12),
          if (prereq != null) ...[
            Row(
              children: [
                Icon(
                  isLocked ? Icons.lock_outline_rounded : Icons.lock_open_rounded,
                  color: isLocked ? Colors.redAccent : Colors.green,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Phụ thuộc vào: ${prereq.title}",
                        style: GoogleFonts.nunito(
                          fontWeight: FontWeight.bold,
                          color: textColor,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isLocked ? Colors.redAccent.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: isLocked ? Colors.redAccent.withOpacity(0.3) : Colors.green.withOpacity(0.3)),
                            ),
                            child: Text(
                              isLocked ? "BỊ KHÓA" : "ĐÃ MỞ KHÓA",
                              style: GoogleFonts.nunito(
                                color: isLocked ? Colors.redAccent : Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              isLocked ? "Chờ công việc tiên quyết hoàn thành" : "Đã đủ điều kiện để thực hiện",
                              style: GoogleFonts.nunito(color: secondaryText, fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.link_off_rounded, color: Colors.redAccent),
                  tooltip: "Gỡ bỏ liên kết phụ thuộc",
                  onPressed: () {
                    setState(() {
                      widget.task.dependencyTaskId = null;
                    });
                    provider.updateTask(widget.task);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Đã gỡ bỏ yêu cầu công việc tiên quyết")),
                    );
                  },
                ),
              ],
            ),
          ] else ...[
            Row(
              children: [
                Icon(Icons.link_rounded, color: secondaryText, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Công việc này chưa có liên kết phụ thuộc nào.",
                    style: GoogleFonts.nunito(color: secondaryText, fontSize: 14),
                  ),
                ),
                TextButton.icon(
                  onPressed: _showAddDependencyDialog,
                  icon: const Icon(Icons.add, size: 16),
                  label: Text("Thêm liên kết", style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
                  style: TextButton.styleFrom(foregroundColor: ghBlue),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showAddDependencyDialog() {
    final provider = Provider.of<TaskProvider>(context, listen: false);
    final candidates = provider.getPrerequisiteCandidates(widget.task);

    if (candidates.isEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text("Không có công việc hợp lệ", style: GoogleFonts.nunito(fontWeight: FontWeight.bold, color: textColor)),
          content: Text("Không tìm thấy công việc nào khác trong dự án này có thể làm công việc tiên quyết.", style: GoogleFonts.nunito(color: textColor)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text("Đã hiểu", style: GoogleFonts.nunito(color: ghBlue, fontWeight: FontWeight.bold))),
          ],
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: bgColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16))),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Chọn công việc tiên quyết",
                style: GoogleFonts.nunito(color: textColor, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: candidates.length,
                  itemBuilder: (context, index) {
                    final t = candidates[index];
                    return ListTile(
                      leading: Icon(
                        t.status == 'completed' ? Icons.check_circle_outline : Icons.pending_actions_rounded,
                        color: t.status == 'completed' ? Colors.green : Colors.blue,
                      ),
                      title: Text(
                        t.title,
                        style: GoogleFonts.nunito(color: textColor),
                      ),
                      onTap: () {
                        setState(() {
                          widget.task.dependencyTaskId = t.task_id;
                        });
                        provider.updateTask(widget.task);
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Đã liên kết với công việc tiên quyết "${t.title}"')),
                        );
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
