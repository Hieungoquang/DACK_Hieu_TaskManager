import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/task_model.dart';
import '../models/time_logs_model.dart';
import '../services/local_service.dart';
import '../provider/task_provider.dart';

class CompletionConfirmDialog extends StatefulWidget {
  final Task task;
  final VoidCallback onConfirm;

  const CompletionConfirmDialog({
    super.key,
    required this.task,
    required this.onConfirm,
  });

  @override
  State<CompletionConfirmDialog> createState() => _CompletionConfirmDialogState();
}

class _CompletionConfirmDialogState extends State<CompletionConfirmDialog> {
  double _progress = 100.0;
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _progress = widget.task.progress.toDouble();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Color _getProgressColor(double val) {
    if (val < 30) return Colors.redAccent;
    if (val < 75) return const Color(0xFFD29922); // ghOrange
    return const Color(0xFF3FB950); // ghGreen
  }

  String _getProgressLabel(double val) {
    if (val == 0) return "Chưa làm gì";
    if (val < 30) return "Mới bắt đầu";
    if (val < 75) return "Đang làm dở";
    if (val < 100) return "Gần hoàn thành";
    return "Hoàn thành xuất sắc! 🎉";
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ghGreen = const Color(0xFF3FB950);
    final cardBg = isDark ? const Color(0xFF161B22) : Colors.white;
    final textColor = isDark ? const Color(0xFFC9D1D9) : const Color(0xFF24292F);
    final subText = isDark ? const Color(0xFF8B949E) : const Color(0xFF57606A);
    final borderColor = isDark ? const Color(0xFF30363D) : const Color(0xFFD0D7DE);

    return Dialog(
      backgroundColor: cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Xác nhận kết quả công việc",
                style: GoogleFonts.nunito(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Đánh giá mức độ hoàn thành thực tế cho nhiệm vụ này.",
                style: GoogleFonts.nunito(fontSize: 13, color: subText),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Tiến độ công việc",
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  Text(
                    "${_progress.toInt()}%",
                    style: GoogleFonts.nunito(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: _getProgressColor(_progress),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: _getProgressColor(_progress),
                  thumbColor: _getProgressColor(_progress),
                  inactiveTrackColor: borderColor,
                  valueIndicatorColor: _getProgressColor(_progress),
                ),
                child: Slider(
                  value: _progress,
                  min: 0,
                  max: 100,
                  divisions: 20,
                  label: "${_progress.toInt()}%",
                  onChanged: (val) {
                    setState(() {
                      _progress = val;
                    });
                  },
                ),
              ),
              Center(
                child: Text(
                  _getProgressLabel(_progress),
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: _getProgressColor(_progress),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "Ghi chú thực hiện",
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _notesController,
                maxLines: 3,
                style: GoogleFonts.nunito(color: textColor, fontSize: 14),
                decoration: InputDecoration(
                  hintText: "Ghi nhận khó khăn, bài học hoặc kết quả thực tế...",
                  hintStyle: GoogleFonts.nunito(color: subText.withOpacity(0.6), fontSize: 13),
                  fillColor: isDark ? const Color(0xFF0D1117) : const Color(0xFFF6F8FA),
                  filled: true,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: ghGreen),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      "Hủy",
                      style: GoogleFonts.nunito(
                        color: subText,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () async {
                      final now = DateTime.now();
                      final task = widget.task;
                      
                      // 1. Cập nhật tiến độ của task
                      task.progress = _progress.toInt();
                      if (_progress == 100.0) {
                        task.status = 'completed';
                      } else {
                        task.status = 'in_progress';
                      }
                      task.updatedAt = now;
                      task.isSynced = false;
                      await task.save();

                      // 2. Tính toán thời gian thực tế thực hiện
                      final start = task.due_day;
                      final end = now;
                      final duration = end.difference(start).inMinutes;

                      // 3. Tạo Time Log lưu vào lịch sử
                      final log = Time_logs(
                        log_id: now.millisecondsSinceEpoch.toString(),
                        task_id: task.task_id,
                        start_time: start,
                        end_time: end,
                        duration_minutes: duration <= 0 ? 1 : duration,
                        notes: _notesController.text.trim().isEmpty 
                            ? "Cập nhật tiến độ thành ${_progress.toInt()}%" 
                            : _notesController.text.trim(),
                        created_at: now,
                        updated_at: now,
                      );
                      await LocalService.addLog(log);

                      // 4. Gọi callbacks tải lại dữ liệu trong TaskProvider
                      if (context.mounted) {
                        Provider.of<TaskProvider>(context, listen: false).loadTasks();
                      }

                      widget.onConfirm();
                      
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              "Đã lưu kết quả hoàn thành: ${_progress.toInt()}%",
                              style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
                            ),
                            backgroundColor: ghGreen,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ghGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      "Lưu kết quả",
                      style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
