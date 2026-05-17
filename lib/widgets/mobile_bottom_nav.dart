import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/calendar_screen.dart';
import '../screens/ai_suggestion_screen.dart';
import '../screens/notification_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/analytics_dashboard_screen.dart';

/// Thanh điều hướng phía dưới (dock) chỉ hiển thị trên mobile.
/// Cho phép truy cập nhanh: Trang chủ, Lịch, AI, Thông báo, Cài đặt.
class MobileBottomNav extends StatelessWidget {
  /// route hiện tại để highlight: 'home' | 'calendar' | 'ai' | 'notification' | 'settings'
  final String currentRoute;

  const MobileBottomNav({super.key, required this.currentRoute});

  static const Color _green = Color(0xFF58CC02);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF161B22) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF30363D) : const Color(0xFFE5E5E5);
    final inactive = isDark ? Colors.white54 : const Color(0xFF8B949E);

    final items = <_NavItem>[
      _NavItem(
        route: 'home',
        icon: Icons.home_rounded,
        label: 'Trang chủ',
        builder: () => const HomeScreen(),
      ),
      _NavItem(
        route: 'calendar',
        icon: Icons.calendar_month_rounded,
        label: 'Lịch',
        builder: () => const CalendarScreen(),
      ),
      _NavItem(
        route: 'ai',
        icon: Icons.auto_awesome_rounded,
        label: 'AI',
        builder: () => const AiSuggestionScreen(),
      ),
      _NavItem(
        route: 'analytics',
        icon: Icons.analytics_outlined,
        label: 'Phân tích',
        builder: () => const AnalyticsDashboardScreen(),
      ),
      _NavItem(
        route: 'notification',
        icon: Icons.notifications_rounded,
        label: 'Thông báo',
        builder: () => const NotificationScreen(),
      ),
      _NavItem(
        route: 'settings',
        icon: Icons.settings_rounded,
        label: 'Cài đặt',
        builder: () => const SettingsScreen(),
      ),
    ];

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          border: Border(top: BorderSide(color: borderColor)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: items.map((item) {
            final active = item.route == currentRoute;
            return Expanded(
              child: InkWell(
                onTap: active
                    ? null
                    : () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => item.builder()),
                        ),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item.icon,
                        size: 22,
                        color: active ? _green : inactive,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight:
                              active ? FontWeight.w700 : FontWeight.w500,
                          color: active ? _green : inactive,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _NavItem {
  final String route;
  final IconData icon;
  final String label;
  final Widget Function() builder;

  _NavItem({
    required this.route,
    required this.icon,
    required this.label,
    required this.builder,
  });
}
