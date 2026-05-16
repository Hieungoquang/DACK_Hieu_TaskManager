import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

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
  final TextEditingController _descriptionController = TextEditingController();
  bool _previewDescription = false;
  bool _previewComment = false;

  final Color bgColor = const Color(0xFFF7F8FC);
  final Color cardColor = Colors.white;
  final Color textColor = const Color(0xFF1F2937);
  final Color secondaryText = const Color(0xFF6B7280);
  final Color borderColor = const Color(0xFFE5E7EB);

  @override
  void initState() {
    super.initState();
    _descriptionController.text = widget.task.description;
    attachments.addAll(widget.task.attachments);
  }

  @override
  void dispose() {
    _commentController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickAttachment() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
    );
    if (result != null) {
      setState(() {
        attachments.addAll(
          result.files
              .map((e) => e.name)
              .where((name) => !attachments.contains(name)),
        );
      });
      await _saveAttachments(showMessage: true);
    }
  }

  Future<void> _saveAttachments({bool showMessage = false}) async {
    widget.task.attachments = List<String>.from(attachments);
    widget.task.updatedAt = DateTime.now();
    await widget.task.save();
    if (showMessage && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã lưu tệp đính kèm')),
      );
    }
  }

  void _addComment() {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      comments.add({'text': text, 'date': DateTime.now()});
      _commentController.clear();
    });
  }

  void _editTaskDate(String field) async {
    DateTime? picked;
    DateTime? initialDate =
        field == 'start' ? widget.task.due_day : widget.task.deadline;

    picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null && mounted) {
      TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDate),
      );

      if (time != null && mounted) {
        final finalDateTime = DateTime(
          picked.year,
          picked.month,
          picked.day,
          time.hour,
          time.minute,
        );

        setState(() {
          if (field == 'start') {
            widget.task.due_day = finalDateTime;
          } else if (field == 'end') {
            widget.task.deadline = finalDateTime;
          }
          widget.task.updatedAt = DateTime.now();
        });
        await widget.task.save();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã cập nhật ngày giờ')),
          );
        }
      }
    }
  }

  void _editCategory() async {
    final categories = ['Công việc', 'Cá nhân', 'Học tập', 'Khác'];
    final selected = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Chọn nhãn",
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: categories
              .map((cat) => ListTile(
                    title: Text(cat, style: GoogleFonts.inter()),
                    onTap: () => Navigator.pop(context, cat),
                  ))
              .toList(),
        ),
      ),
    );
    if (selected != null && mounted) {
      setState(() {
        widget.task.category = selected;
        widget.task.updatedAt = DateTime.now();
      });
      await widget.task.save();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã đổi nhãn thành $selected')),
        );
      }
    }
  }

  void _confirmDeleteTask() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Xóa công việc",
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        content: Text(
          "Bạn có chắc muốn xóa công việc này?",
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              await context.read<TaskProvider>().deleteTask(
                    widget.task.task_id,
                  );

              if (mounted) {
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Xóa", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showEditDialog() {
    final titleController = TextEditingController(text: widget.task.title);
    final descController = TextEditingController(text: widget.task.description);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Chỉnh sửa nhiệm vụ",
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: "Tiêu đề",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: "Mô tả",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            onPressed: () async {
              setState(() {
                widget.task.title = titleController.text;
                widget.task.description = descController.text;
                widget.task.updatedAt = DateTime.now();
              });
              await widget.task.save();
              if (mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text("Lưu", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _setTaskStatus(String status) async {
    setState(() {
      widget.task.status = status;
      widget.task.updatedAt = DateTime.now();
    });
    await widget.task.save();
    if (mounted) {
      final statusText = status == 'completed'
          ? 'hoàn thành'
          : status == 'in_progress'
              ? 'đang làm'
              : 'mở lại';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nhiệm vụ đã chuyển sang $statusText')),
      );
    }
  }

  void _saveDescription() async {
    setState(() {
      widget.task.description = _descriptionController.text.trim();
      widget.task.attachments = attachments;
      widget.task.updatedAt = DateTime.now();
    });
    await widget.task.save();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã lưu mô tả nhiệm vụ')));
    }
  }

  Widget buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            offset: const Offset(0, 2),
            color: Colors.black.withValues(alpha: 0.04),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget infoTile(IconData icon, String title, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 10),
        Text(
          "$title:",
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: secondaryText,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          value,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ],
    );
  }

  Widget sectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
    );
  }

  String getPriorityText(int p) {
    if (p == 3) return "Cao";
    if (p == 2) return "Trung bình";
    return "Thấp";
  }

  Widget _buildActivityItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Icon(icon, size: 16, color: secondaryText),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(color: secondaryText, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildDescriptionCard() {
    return buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          sectionTitle("Mô tả nhiệm vụ"),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: borderColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    InkWell(
                      onTap: () => setState(() => _previewDescription = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: !_previewDescription
                              ? Colors.white
                              : Colors.transparent,
                          border: Border(
                            right: BorderSide(color: borderColor),
                            bottom: BorderSide(
                              color: !_previewDescription
                                  ? Colors.white
                                  : borderColor,
                            ),
                          ),
                        ),
                        child: Text(
                          "Viết",
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => setState(() => _previewDescription = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                        child: Text(
                          "Xem trước",
                          style: GoogleFonts.inter(color: textColor),
                        ),
                      ),
                    ),
                  ],
                ),
                Divider(height: 1, color: borderColor),
                _buildEditorToolbar(iconSize: 18, spacing: 18, height: 42),
                Divider(height: 1, color: borderColor),
                SizedBox(
                  height: 260,
                  child: _previewDescription
                      ? SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              _descriptionController.text.trim().isEmpty
                                  ? "Chưa có mô tả."
                                  : _descriptionController.text,
                              softWrap: true,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: textColor,
                              ),
                            ),
                          ),
                        )
                      : TextField(
                          controller: _descriptionController,
                          maxLines: null,
                          expands: true,
                          textAlignVertical: TextAlignVertical.top,
                          decoration: InputDecoration(
                            hintText: "Nhập mô tả của bạn tại đây...",
                            hintStyle: GoogleFonts.inter(color: secondaryText),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(16),
                          ),
                        ),
                ),
                Divider(height: 1, color: borderColor),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      InkWell(
                        onTap: _pickAttachment,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.attach_file,
                              size: 18,
                              color: secondaryText,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Chọn tệp đính kèm",
                              style: GoogleFonts.inter(color: secondaryText),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: _saveDescription,
                        child: const Text("Lưu mô tả"),
                      ),
                    ],
                  ),
                ),
                if (attachments.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: attachments
                            .map(
                              (file) => Chip(
                                label: Text(file),
                                deleteIcon: const Icon(Icons.close, size: 16),
                                onDeleted: () async {
                                  setState(() => attachments.remove(file));
                                  await _saveAttachments();
                                },
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditorToolbar({
    required double iconSize,
    required double spacing,
    required double height,
  }) {
    return SizedBox(
      height: height,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            Icon(Icons.title, size: iconSize, color: secondaryText),
            SizedBox(width: spacing),
            Icon(Icons.format_bold, size: iconSize, color: secondaryText),
            SizedBox(width: spacing),
            Icon(Icons.format_italic, size: iconSize, color: secondaryText),
            SizedBox(width: spacing),
            Icon(Icons.format_list_bulleted,
                size: iconSize, color: secondaryText),
            SizedBox(width: spacing),
            Icon(Icons.code, size: iconSize, color: secondaryText),
            SizedBox(width: spacing),
            Icon(Icons.link, size: iconSize, color: secondaryText),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentsCard() {
    return buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          sectionTitle("Tệp đính kèm"),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ...attachments.map(
                (file) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.attach_file, size: 16),
                      const SizedBox(width: 6),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 180),
                        child: Text(
                          file,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () async {
                          setState(() => attachments.remove(file));
                          await _saveAttachments();
                        },
                        child: const Icon(
                          Icons.close,
                          color: Colors.red,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              InkWell(
                onTap: _pickAttachment,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: borderColor),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.upload_file, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        "Đính kèm",
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommentItem(Map<String, dynamic> comment) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.blue.shade100,
            child: Icon(Icons.person, size: 18, color: Colors.blue.shade700),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      "Bạn đã ghi chú vào ${DateFormat('dd/MM/yyyy').format(comment['date'] as DateTime)}",
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: textColor,
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.more_horiz, color: secondaryText, size: 18),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: borderColor),
                  ),
                  child: Text(
                    comment['text'] as String,
                    style: GoogleFonts.inter(fontSize: 14, color: textColor),
                  ),
                ),
              ],
            ),
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
          /// Existing comments
          ...comments.map((c) => _buildCommentItem(c)),

          /// Activity timeline
          _buildActivityItem(
            Icons.person_add_outlined,
            "Đã tạo công việc vào ${DateFormat('dd/MM/yyyy HH:mm').format(widget.task.due_day)}",
          ),
          _buildActivityItem(
            Icons.label_outline,
            "Đã thêm nhãn: ${widget.task.category}",
          ),
          _buildActivityItem(
            Icons.change_circle_outlined,
            "Trạng thái: ${widget.task.status == 'in_progress' ? 'Đang làm' : widget.task.status == 'completed' ? 'Hoàn thành' : 'Mở lại'}",
          ),

          const SizedBox(height: 16),
          Divider(height: 1, color: borderColor),
          const SizedBox(height: 16),

          Container(
            decoration: BoxDecoration(
              border: Border.all(color: borderColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    InkWell(
                      onTap: () => setState(() => _previewComment = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: !_previewComment
                              ? Colors.white
                              : Colors.transparent,
                          border: Border(right: BorderSide(color: borderColor)),
                        ),
                        child: Text(
                          "Viết",
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => setState(() => _previewComment = true),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                        child: Text(
                          "Xem trước",
                          style: GoogleFonts.inter(color: textColor),
                        ),
                      ),
                    ),
                  ],
                ),
                Divider(height: 1, color: borderColor),
                _buildEditorToolbar(iconSize: 17, spacing: 16, height: 38),
                Divider(height: 1, color: borderColor),
                SizedBox(
                  height: 150,
                  child: _previewComment
                      ? SingleChildScrollView(
                          padding: const EdgeInsets.all(14),
                          child: Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              _commentController.text.trim().isEmpty
                                  ? "Chưa có nội dung ghi chú."
                                  : _commentController.text,
                              softWrap: true,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: textColor,
                              ),
                            ),
                          ),
                        )
                      : TextField(
                          controller: _commentController,
                          maxLines: null,
                          expands: true,
                          textAlignVertical: TextAlignVertical.top,
                          decoration: InputDecoration(
                            hintText: "Thêm ghi chú...",
                            hintStyle: GoogleFonts.inter(color: secondaryText),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(14),
                          ),
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton(
                onPressed: _addComment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  "Ghi chú",
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetaSidebar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        /// Labels
        sectionTitle("Nhãn"),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildMetaChip(widget.task.category, Colors.blue),
            GestureDetector(
              onTap: _editCategory,
              child: Icon(Icons.edit, size: 14, color: Colors.blue.shade600),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildMetaChip(
          getPriorityText(widget.task.priority),
          Colors.orange,
        ),
        const SizedBox(height: 24),

        /// Status
        sectionTitle("Trạng thái"),
        const SizedBox(height: 10),
        Row(
          children: [
            _buildMetaChip(
              widget.task.status == 'in_progress'
                  ? 'Đang làm'
                  : widget.task.status == 'completed'
                      ? 'Hoàn thành'
                      : 'Mở lại',
              widget.task.status == 'in_progress'
                  ? Colors.orange
                  : widget.task.status == 'completed'
                      ? Colors.green
                      : Colors.blue,
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                showMenu(
                  context: context,
                  position: const RelativeRect.fromLTRB(0, 0, 0, 0),
                  items: [
                    const PopupMenuItem(
                      value: 'pending',
                      child: Text('Mở lại'),
                    ),
                    const PopupMenuItem(
                      value: 'in_progress',
                      child: Text('Đang làm'),
                    ),
                    const PopupMenuItem(
                      value: 'completed',
                      child: Text('Hoàn thành'),
                    ),
                  ],
                ).then((value) {
                  if (value != null) _setTaskStatus(value);
                });
              },
              child: Icon(Icons.edit, size: 14, color: Colors.blue.shade600),
            ),
          ],
        ),
        const SizedBox(height: 24),

        /// Time
        sectionTitle("Thời gian"),
        const SizedBox(height: 10),
        _buildMetaDateRow("Bắt đầu", widget.task.due_day, 'start'),
        const SizedBox(height: 10),
        _buildMetaDateRow("Kết thúc", widget.task.deadline, 'end'),
      ],
    );
  }

  Widget _buildMetaDateRow(String label, DateTime value, String field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 13, color: secondaryText),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              DateFormat('dd/MM/yyyy HH:mm').format(value),
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            GestureDetector(
              onTap: () => _editTaskDate(field),
              child: Icon(Icons.edit, size: 14, color: Colors.blue.shade600),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTaskHeader(double titleFontSize) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.task.title,
          style: GoogleFonts.inter(
            fontSize: titleFontSize,
            fontWeight: FontWeight.w700,
            color: textColor,
            height: 1.18,
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                "Đang làm",
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: Colors.orange.shade800,
                ),
              ),
            ),
            Text(
              "Bạn đã tạo công việc vào ${DateFormat('dd/MM/yyyy').format(widget.task.createdAt)}",
              style: GoogleFonts.inter(color: secondaryText),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeaderActions() {
    return Wrap(
      spacing: 12,
      runSpacing: 10,
      children: [
        OutlinedButton.icon(
          onPressed: _showEditDialog,
          icon: const Icon(Icons.edit_outlined, size: 18),
          label: const Text("Chỉnh sửa"),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        ElevatedButton.icon(
          onPressed: _confirmDeleteTask,
          icon: const Icon(Icons.delete_outline, size: 18),
          label: const Text("Xóa công việc"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    final isWeb = width > 900;
    final horizontalPadding = isWeb ? 40.0 : 16.0;
    final maxContentWidth = isWeb ? 1120.0 : 640.0;
    final titleFontSize = isWeb ? 30.0 : 24.0;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          // Auto-save description and attachments when back
          if (_descriptionController.text.trim() != widget.task.description ||
              !listEquals(attachments, widget.task.attachments)) {
            widget.task.description = _descriptionController.text.trim();
            widget.task.attachments = attachments;
            widget.task.updatedAt = DateTime.now();
            await widget.task.save();
          }
        }
      },
      child: Scaffold(
        backgroundColor: bgColor,
        body: Row(
          children: [
            if (isWeb) const WebSidebar(currentRoute: 'home'),
            Expanded(
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: isWeb ? 28 : 18,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxContentWidth),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          /// HEADER
                          isWeb
                              ? Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: _buildTaskHeader(titleFontSize),
                                    ),
                                    const SizedBox(width: 24),
                                    _buildHeaderActions(),
                                  ],
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildTaskHeader(titleFontSize),
                                    const SizedBox(height: 16),
                                    _buildHeaderActions(),
                                  ],
                                ),

                          const SizedBox(height: 30),

                          if (isWeb)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 7,
                                  child: Column(
                                    children: [
                                      _buildDescriptionCard(),
                                      const SizedBox(height: 20),
                                      _buildAttachmentsCard(),
                                      const SizedBox(height: 20),
                                      _buildActivityCard(),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 28),
                                SizedBox(
                                  width: 280,
                                  child: _buildMetaSidebar(),
                                ),
                              ],
                            )
                          else
                            Column(
                              children: [
                                _buildDescriptionCard(),
                                const SizedBox(height: 20),
                                _buildAttachmentsCard(),
                                const SizedBox(height: 20),
                                _buildActivityCard(),
                                const SizedBox(height: 24),
                                _buildMetaSidebar(),
                              ],
                            ),

                          const SizedBox(height: 50),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
