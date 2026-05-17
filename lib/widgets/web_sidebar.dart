import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../screens/home_screen.dart';
import '../screens/calendar_screen.dart';
import '../screens/trash_screen.dart';
import '../screens/notification_screen.dart';
import '../screens/ai_suggestion_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/login_screen.dart';
import '../provider/task_provider.dart';
import '../screens/procrastination_report_screen.dart';
import '../screens/analytics_dashboard_screen.dart';

class WebSidebar extends StatefulWidget {
  final String currentRoute;
  const WebSidebar({super.key, required this.currentRoute});

  // Lưu trạng thái thu gọn tĩnh để giữ trạng thái khi chuyển trang
  static bool isCollapsed = false;

  @override
  State<WebSidebar> createState() => _WebSidebarState();
}

class _WebSidebarState extends State<WebSidebar> {
  final AuthService _auth = AuthService();
  String _displayName = "Người dùng";
  String? _photoUrl;

  final Color duoGreen = const Color(0xFF58CC02);
  final Color duoBlue = const Color(0xFF1CB0F6);
  final Color duoGray = const Color(0xFFE5E5E5);
  final Color duoText = const Color(0xFF1F1F1F);
  final Color duoSecondaryText = const Color(0xFF4B4B4B);

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  void _loadUserInfo() async {
    final firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      _photoUrl = firebaseUser.photoURL;
      final userBox = await Hive.openBox<User>('userBox');
      final user = userBox.get(firebaseUser.uid);
      if (user != null) {
        setState(() {
          _displayName = user.username.isNotEmpty
              ? user.username
              : (user.full_name.isNotEmpty ? user.full_name : "Người dùng");
        });
      }
    }
  }

  void _toggleSidebar() {
    setState(() {
      WebSidebar.isCollapsed = !WebSidebar.isCollapsed;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF37464F) : duoGray;
    final sidebarBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final bool collapsed = WebSidebar.isCollapsed;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: collapsed ? 85 : 260,
      decoration: BoxDecoration(
        color: sidebarBg,
        border: Border(right: BorderSide(color: borderColor, width: 2)),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: collapsed ? 10 : 20,
        vertical: 30,
      ),
      child: Column(
        crossAxisAlignment:
            collapsed ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          _buildHeader(collapsed),
          const SizedBox(height: 40),
          _buildSidebarItem(
            context,
            Icons.home_rounded,
            "TRANG CHỦ",
            duoGreen,
            "home",
            isDark,
            () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            ),
          ),
          _buildSidebarItem(
            context,
            Icons.calendar_month_rounded,
            "LỊCH TRÌNH",
            duoBlue,
            "calendar",
            isDark,
            () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const CalendarScreen()),
            ),
          ),
          _buildSidebarItem(
            context,
            Icons.auto_awesome_rounded,
            "AI GỢI Ý",
            Colors.purple,
            "ai",
            isDark,
            () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const AiSuggestionScreen()),
            ),
          ),
          _buildSidebarItem(
            context,
            Icons.analytics_outlined,
            "PHÂN TÍCH",
            Colors.purple,
            "analytics",
            isDark,
            () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const AnalyticsDashboardScreen()),
            ),
          ),
          _buildSidebarItem(
            context,
            Icons.psychology_alt_rounded,
            "REALITY CHECK",
            Colors.purpleAccent,
            "reality_check",
            isDark,
            () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const ProcrastinationReportScreen()),
            ),
          ),
          _buildSidebarItem(
            context,
            Icons.notifications_rounded,
            "THÔNG BÁO",
            Colors.redAccent,
            "notification",
            isDark,
            () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const NotificationScreen()),
            ),
          ),
          _buildSidebarItem(
            context,
            Icons.delete_outline,
            "THÙNG RÁC",
            isDark ? Colors.white70 : duoSecondaryText,
            "trash",
            isDark,
            () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const TrashScreen()),
            ),
          ),
          _buildSidebarItem(
            context,
            Icons.person_rounded,
            "HỒ SƠ",
            isDark ? Colors.white70 : duoSecondaryText,
            "profile",
            isDark,
            () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
          ),
          _buildSidebarItem(
            context,
            Icons.settings_rounded,
            "CÀI ĐẶT",
            isDark ? Colors.white70 : duoSecondaryText,
            "settings",
            isDark,
            () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
          const Spacer(),
          _buildSidebarUserSection(isDark, collapsed),
        ],
      ),
    );
  }

  Widget _buildHeader(bool collapsed) {
    return Row(
      mainAxisAlignment:
          collapsed ? MainAxisAlignment.center : MainAxisAlignment.spaceBetween,
      children: [
        if (!collapsed)
          Text(
            "TASKFLOW",
            style: TextStyle(
              color: duoGreen,
              fontWeight: FontWeight.w900,
              fontSize: 20,
              letterSpacing: 1.5,
            ),
          ),
        IconButton(
          onPressed: _toggleSidebar,
          icon: Icon(
            collapsed ? Icons.menu_open_rounded : Icons.menu_rounded,
            color: duoGreen,
          ),
          splashRadius: 20,
        ),
      ],
    );
  }

  Widget _buildSidebarItem(
    BuildContext context,
    IconData icon,
    String title,
    Color color,
    String route,
    bool isDark,
    VoidCallback onTap,
  ) {
    bool isSelected = widget.currentRoute == route;
    bool collapsed = WebSidebar.isCollapsed;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Tooltip(
        message: collapsed ? title : "",
        child: InkWell(
          onTap: isSelected ? null : onTap,
          borderRadius: BorderRadius.circular(15),
          child: Container(
            height: 50,
            padding: EdgeInsets.symmetric(horizontal: collapsed ? 0 : 12),
            decoration: BoxDecoration(
              color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(15),
              border: isSelected
                  ? Border.all(color: color.withOpacity(0.3), width: 1.5)
                  : null,
            ),
            child: Row(
              mainAxisAlignment: collapsed
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                Icon(
                  icon,
                  color: isSelected
                      ? color
                      : (isDark
                          ? Colors.white38
                          : duoSecondaryText.withOpacity(0.5)),
                  size: 26,
                ),
                if (!collapsed) ...[
                  const SizedBox(width: 15),
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: isSelected
                          ? color
                          : (isDark ? Colors.white70 : duoSecondaryText),
                      fontSize: 13,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarUserSection(bool isDark, bool collapsed) {
    final provider = context.watch<TaskProvider>();
    final user = provider.currentUser;
    final displayName = user?.full_name ?? user?.username ?? _displayName;
    final photoUrl = user?.avatar_url ?? _photoUrl;

    return Container(
      padding: const EdgeInsets.only(top: 20),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF37464F) : duoGray,
            width: 2,
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment:
                collapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                ),
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: duoGray,
                  backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                      ? NetworkImage(photoUrl)
                      : null,
                  child: (photoUrl == null || photoUrl.isEmpty)
                      ? const Icon(Icons.person, color: Colors.white)
                      : null,
                ),
              ),
              if (!collapsed) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    displayName.toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : duoText,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                  ),
                ),
              ],
            ],
          ),
          if (!collapsed) ...[
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: () async {
                await _auth.logout();
                if (mounted)
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
              },
              icon: const Icon(
                Icons.logout_rounded,
                color: Colors.redAccent,
                size: 18,
              ),
              label: const Text(
                "ĐĂNG XUẤT",
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                ),
              ),
            ),
          ] else
            IconButton(
              icon: const Icon(
                Icons.logout_rounded,
                color: Colors.redAccent,
                size: 22,
              ),
              onPressed: () async {
                await _auth.logout();
                if (mounted)
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
              },
            ),
        ],
      ),
    );
  }
}
