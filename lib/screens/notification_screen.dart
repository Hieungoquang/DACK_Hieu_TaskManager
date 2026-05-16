import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/notification_model.dart' as model;
import '../widgets/web_sidebar.dart';
import '../widgets/mobile_bottom_nav.dart';
import '../services/local_service.dart';
import '../provider/task_provider.dart';
import '../widgets/app_popup.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  // GitHub Style Colors
  static const Color ghDarkBg = Color(0xFF0D1117);
  static const Color ghDarkCard = Color(0xFF161B22);
  static const Color ghDarkBorder = Color(0xFF30363D);
  static const Color ghDarkText = Color(0xFFC9D1D9);
  static const Color ghDarkSubText = Color(0xFF8B949E);

  static const Color ghLightBg = Color(0xFFF6F8FA);
  static const Color ghLightCard = Color(0xFFFFFFFF);
  static const Color ghLightBorder = Color(0xFFD0D7DE);
  static const Color ghLightText = Color(0xFF24292F);
  static const Color ghLightSubText = Color(0xFF57606A);

  static const Color ghBlue = Color(0xFF58A6FF);
  static const Color ghGreen = Color(0xFF3FB950);
  static const Color ghOrange = Color(0xFFD29922);
  static const Color ghPurple = Color(0xFFA371F7);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final scaffoldBg = isDark ? ghDarkBg : ghLightBg;
    final textColor = isDark ? ghDarkText : ghLightText;
    final subTextColor = isDark ? ghDarkSubText : ghLightSubText;
    final borderColor = isDark ? ghDarkBorder : ghLightBorder;
    final cardColor = isDark ? ghDarkCard : ghLightCard;

    double width = MediaQuery.of(context).size.width;
    bool isWeb = width > 900;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: isWeb
          ? null
          : AppBar(
              backgroundColor: scaffoldBg,
              elevation: 0,
              centerTitle: false,
              title: Text(
                "Thông báo",
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: textColor, size: 24),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                IconButton(
                  icon: Icon(Icons.done_all, color: ghBlue, size: 22),
                  onPressed: () => _markAllAsRead(),
                  tooltip: "Đánh dấu tất cả là đã đọc",
                ),
                const SizedBox(width: 8),
              ],
            ),
      bottomNavigationBar:
          isWeb ? null : MobileBottomNav(currentRoute: 'notification'),
      body: Row(
        children: [
          if (isWeb) const WebSidebar(currentRoute: 'notification'),
          Expanded(
            child: Column(
              children: [
                if (isWeb) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(40, 30, 40, 20),
                    child: Row(
                      children: [
                        Text(
                          "Thông báo",
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const Spacer(),
                        ElevatedButton.icon(
                          onPressed: () => _markAllAsRead(),
                          icon: const Icon(Icons.done_all, size: 18),
                          label: const Text("Đánh dấu đã đọc"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ghBlue.withOpacity(0.1),
                            foregroundColor: ghBlue,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                Expanded(
                  child: ValueListenableBuilder(
                    valueListenable: Hive.box<model.Notification>(
                      'notificationsBox',
                    ).listenable(),
                    builder: (context, Box<model.Notification> box, _) {
                      final notifications = box.values.toList()
                        ..sort((a, b) => b.created_at.compareTo(a.created_at));

                      if (notifications.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.notifications_none_outlined,
                                size: 80,
                                color: subTextColor.withOpacity(0.3),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                "Không có thông báo nào",
                                style: TextStyle(
                                  color: subTextColor,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: EdgeInsets.symmetric(
                          horizontal: isWeb ? 40 : 16,
                          vertical: 10,
                        ),
                        itemCount: notifications.length,
                        itemBuilder: (context, index) {
                          final notif = notifications[index];
                          return _buildNotificationCard(
                            context,
                            notif,
                            isDark,
                            cardColor,
                            borderColor,
                            textColor,
                            subTextColor,
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    model.Notification notif,
    bool isDark,
    Color cardColor,
    Color borderColor,
    Color textColor,
    Color subTextColor,
  ) {
    IconData icon;
    Color iconColor;

    switch (notif.type) {
      case 'project_invitation':
        icon = Icons.folder_shared_outlined;
        iconColor = ghBlue;
        break;
      case 'task_assignment':
        icon = Icons.assignment_ind_outlined;
        iconColor = ghGreen;
        break;
      case 'ai_suggestion':
        icon = Icons.auto_awesome;
        iconColor = ghPurple;
        break;
      case 'daily_summary':
        icon = Icons.analytics_outlined;
        iconColor = ghOrange;
        break;
      default:
        icon = Icons.notifications_outlined;
        iconColor = subTextColor;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
        boxShadow: !isDark
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: () => _handleNotifClick(context, notif),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notif.title,
                              style: TextStyle(
                                color: textColor,
                                fontWeight: notif.isRead
                                    ? FontWeight.normal
                                    : FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Text(
                            _formatTime(notif.created_at),
                            style: TextStyle(color: subTextColor, fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        notif.message,
                        style: TextStyle(
                          color: notif.isRead
                              ? subTextColor
                              : textColor.withOpacity(0.9),
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                if (notif.type == 'project_invitation' &&
                    notif.task_id.isNotEmpty)
                  TextButton.icon(
                    onPressed: () => _acceptProjectInvitation(context, notif),
                    icon: const Icon(Icons.check_circle_outline, size: 16),
                    label: const Text("Tham gia"),
                    style: TextButton.styleFrom(foregroundColor: ghGreen),
                  )
                else if (!notif.isRead)
                  Container(
                    margin: const EdgeInsets.only(left: 10, top: 4),
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: ghBlue,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  void _markAllAsRead() {
    final box = Hive.box<model.Notification>('notificationsBox');
    for (var notif in box.values) {
      if (!notif.isRead) {
        notif.isRead = true;
        notif.updated_at = DateTime.now();
        notif.save();
      }
    }
  }

  void _handleNotifClick(BuildContext context, model.Notification notif) {
    notif.isRead = true;
    notif.updated_at = DateTime.now();
    notif.save();
  }

  Future<void> _acceptProjectInvitation(
    BuildContext context,
    model.Notification notif,
  ) async {
    final ok = await context.read<TaskProvider>().acceptProjectInvitation(
          notif.task_id,
        );
    notif.isRead = true;
    notif.updated_at = DateTime.now();
    await notif.save();

    if (!context.mounted) return;
    if (ok) {
      AppPopup.success(context, "Đã tham gia dự án thành công!");
    } else {
      AppPopup.error(context, "Không thể tham gia dự án này.");
    }
  }
}
