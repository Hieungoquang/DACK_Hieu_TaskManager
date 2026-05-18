import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../models/task_model.dart';
import '../provider/app_provider.dart';
import 'completion_confirm_dialog.dart';
import 'quick_edit_task_dialog.dart';

class ActiveTaskTrackerWidget extends StatefulWidget {
  final Task task;
  final VoidCallback onRefresh;

  const ActiveTaskTrackerWidget({
    super.key,
    required this.task,
    required this.onRefresh,
  });

  @override
  State<ActiveTaskTrackerWidget> createState() =>
      _ActiveTaskTrackerWidgetState();
}

class _ActiveTaskTrackerWidgetState extends State<ActiveTaskTrackerWidget> {
  Timer? _timer;
  late Duration _remaining;
  late double _timeProgress;
  bool _isOverdue = false;
  bool _isSleeping = false;

  bool _isInSleepWindow(AppProvider app, DateTime now) {
    if (!app.isSleepModeEnabled) return false;
    final start = app.sleepStartHour * 60 + app.sleepStartMinute;
    final end = app.sleepEndHour * 60 + app.sleepEndMinute;
    final cur = now.hour * 60 + now.minute;
    if (start == end) return false;
    if (start < end) {
      return cur >= start && cur < end;
    }
    // Cross midnight (e.g. 22:00 -> 06:00)
    return cur >= start || cur < end;
  }

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _updateTime();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateTime() {
    final now = DateTime.now();
    final app = context.read<AppProvider>();
    _isSleeping = _isInSleepWindow(app, now);

    if (_isSleeping) {
      // Trong giờ ngủ: đóng băng đếm ngược, không tính trễ hạn.
      _isOverdue = false;
      _remaining = widget.task.deadline.isAfter(now)
          ? widget.task.deadline.difference(now)
          : Duration.zero;
      final total =
          widget.task.deadline.difference(widget.task.due_day).inSeconds;
      _timeProgress = total <= 0
          ? 0.0
          : (now.difference(widget.task.due_day).inSeconds / total)
              .clamp(0.0, 1.0);
      return;
    }

    if (now.isAfter(widget.task.deadline)) {
      _remaining = Duration.zero;
      _timeProgress = 1.0;
      _isOverdue = true;
    } else {
      _remaining = widget.task.deadline.difference(now);
      _isOverdue = false;

      final total =
          widget.task.deadline.difference(widget.task.due_day).inSeconds;
      if (total <= 0) {
        _timeProgress = 0.0;
      } else {
        final elapsed = now.difference(widget.task.due_day).inSeconds;
        _timeProgress = (elapsed / total).clamp(0.0, 1.0);
      }
    }
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(d.inHours);
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final ghGreen = const Color(0xFF3FB950);
    final ghOrange = const Color(0xFFD29922);

    final cardBg = isDark ? const Color(0xFF161B22) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF30363D) : const Color(0xFFD0D7DE);
    final textColor =
        isDark ? const Color(0xFFC9D1D9) : const Color(0xFF24292F);
    final subText = isDark ? const Color(0xFF8B949E) : const Color(0xFF57606A);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: _isOverdue ? Colors.redAccent.withOpacity(0.6) : borderColor,
            width: 1.5),
        boxShadow: [
          BoxShadow(
            color: (_isSleeping
                    ? Colors.indigoAccent
                    : (_isOverdue ? Colors.redAccent : ghOrange))
                .withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (_isSleeping
                          ? Colors.indigoAccent
                          : (_isOverdue ? Colors.redAccent : ghOrange))
                      .withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isSleeping
                          ? Icons.bedtime_rounded
                          : (_isOverdue
                              ? Icons.warning_amber_rounded
                              : Icons.bolt_rounded),
                      color: _isSleeping
                          ? Colors.indigoAccent
                          : (_isOverdue ? Colors.redAccent : ghOrange),
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isSleeping
                          ? "GIỜ NGỦ - TẠM DỪNG"
                          : (_isOverdue
                              ? "ĐÃ HẾT KHUNG GIỜ"
                              : "ĐANG THỰC HIỆN"),
                      style: GoogleFonts.nunito(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: _isSleeping
                            ? Colors.indigoAccent
                            : (_isOverdue ? Colors.redAccent : ghOrange),
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                "Khung giờ: ${DateFormat('HH:mm').format(widget.task.due_day)} - ${DateFormat('HH:mm').format(widget.task.deadline)}",
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  color: subText,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 6),
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (_) => QuickEditTaskDialog(task: widget.task),
                  ).then((_) => widget.onRefresh());
                },
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(Icons.edit_outlined, size: 16, color: subText),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            widget.task.title,
            style: GoogleFonts.nunito(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.label_outline, size: 14, color: subText),
              const SizedBox(width: 6),
              Text(
                widget.task.category.isEmpty ? "Cá nhân" : widget.task.category,
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  color: subText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isSleeping
                          ? "Đang tạm dừng (giờ ngủ)"
                          : (_isOverdue
                              ? "Thời gian trễ hạn"
                              : "Thời gian còn lại"),
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        color: subText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isOverdue
                          ? "Đã quá ${_formatDuration(DateTime.now().difference(widget.task.deadline))}"
                          : _formatDuration(_remaining),
                      style: GoogleFonts.nunito(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: _isOverdue ? Colors.redAccent : textColor,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => CompletionConfirmDialog(
                      task: widget.task,
                      onConfirm: widget.onRefresh,
                    ),
                  );
                },
                icon: const Icon(Icons.done_all_rounded, size: 18),
                label: Text(
                  "Xác nhận kết quả",
                  style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ghGreen,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _timeProgress,
              minHeight: 6,
              backgroundColor: borderColor,
              valueColor: AlwaysStoppedAnimation(
                  _isOverdue ? Colors.redAccent : ghOrange),
            ),
          ),
        ],
      ),
    );
  }
}
