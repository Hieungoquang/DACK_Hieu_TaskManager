import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/app_provider.dart';
import '../widgets/web_sidebar.dart';
import '../widgets/mobile_bottom_nav.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'trash_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final isDark = appProvider.themeMode == ThemeMode.dark;

    // GitHub Style Colors
    final Color ghBlue = const Color(0xFF58A6FF);
    final Color ghGreen = const Color(0xFF3FB950);
    final Color ghOrange = const Color(0xFFD29922);
    final Color ghPurple = const Color(0xFFA371F7);

    final bgColor = isDark ? const Color(0xFF0D1117) : const Color(0xFFF6F8FA);
    final cardColor = isDark ? const Color(0xFF161B22) : Colors.white;
    final textColor =
        isDark ? const Color(0xFFC9D1D9) : const Color(0xFF24292F);
    final borderColor =
        isDark ? const Color(0xFF30363D) : const Color(0xFFD0D7DE);

    double screenWidth = MediaQuery.of(context).size.width;
    bool isWeb = screenWidth > 900;

    return Scaffold(
      backgroundColor: bgColor,
      bottomNavigationBar:
          isWeb ? null : MobileBottomNav(currentRoute: 'settings'),
      body: Row(
        children: [
          if (isWeb) const WebSidebar(currentRoute: 'settings'),
          Expanded(
            child: CustomScrollView(
              slivers: [
                _buildSliverAppBar(isDark, textColor, bgColor, isWeb, context),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle("GIAO DIỆN & TRẢI NGHIỆM", textColor),
                        _buildSettingCard(isDark, cardColor, borderColor, [
                          _settingItem(
                            icon: isDark ? Icons.dark_mode : Icons.light_mode,
                            iconColor: isDark ? ghOrange : ghPurple,
                            title: "Chế độ tối",
                            subtitle: "Tối ưu hóa hiển thị vào ban đêm",
                            trailing: Switch(
                              value: isDark,
                              activeColor: ghGreen,
                              onChanged: (val) => appProvider.toggleTheme(val),
                            ),
                          ),
                          _divider(borderColor),
                          _settingItem(
                            icon: Icons.language_rounded,
                            iconColor: ghBlue,
                            title: "Ngôn ngữ",
                            subtitle: "Tiếng Việt (Mặc định)",
                            trailing: const Icon(Icons.arrow_forward_ios,
                                size: 14, color: Colors.grey),
                            onTap: () {},
                          ),
                        ]),
                        const SizedBox(height: 32),
                        _sectionTitle("THÔNG BÁO", textColor),
                        _buildSettingCard(isDark, cardColor, borderColor, [
                          _settingItem(
                            icon: Icons.notifications_active_outlined,
                            iconColor: Colors.redAccent,
                            title: "Thông báo đẩy",
                            subtitle: "Nhắc nhở công việc và cập nhật",
                            trailing: Switch(
                              value: true,
                              activeColor: ghGreen,
                              onChanged: (val) {},
                            ),
                          ),
                          _divider(borderColor),
                          _settingItem(
                            icon: Icons.mail_outline_rounded,
                            iconColor: ghGreen,
                            title: "Thông báo Email",
                            subtitle: "Gửi báo cáo công việc qua email",
                            trailing: Switch(
                              value: true,
                              activeColor: ghGreen,
                              onChanged: (val) {},
                            ),
                          ),
                        ]),
                        const SizedBox(height: 32),
                        _sectionTitle("HỆ THỐNG & BẢO MẬT", textColor),
                        _buildSettingCard(isDark, cardColor, borderColor, [
                          _settingItem(
                            icon: Icons.delete_outline,
                            iconColor: Colors.redAccent,
                            title: "Thùng rác",
                            subtitle: "Xem và khôi phục task đã xóa",
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const TrashScreen()),
                            ),
                          ),
                          _divider(borderColor),
                          _settingItem(
                            icon: Icons.security_rounded,
                            iconColor: ghBlue,
                            title: "Đổi mật khẩu",
                            subtitle: "Cập nhật mật khẩu để bảo mật hơn",
                            onTap: () => Navigator.pushNamed(
                                context, '/change-password'),
                          ),
                        ]),
                        const SizedBox(height: 40),
                        Center(
                          child: TextButton.icon(
                            onPressed: () async {
                              await AuthService().logout();
                              if (context.mounted) {
                                Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => const LoginScreen()),
                                    (r) => false);
                              }
                            },
                            icon: const Icon(Icons.logout_rounded,
                                color: Colors.redAccent),
                            label: const Text("ĐĂNG XUẤT TÀI KHOẢN",
                                style: TextStyle(
                                    color: Colors.redAccent,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
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

  Widget _buildSliverAppBar(bool isDark, Color textColor, Color bgColor,
      bool isWeb, BuildContext context) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: bgColor,
      leading: !isWeb
          ? IconButton(
              icon: Icon(Icons.arrow_back, color: textColor),
              onPressed: () => Navigator.pop(context))
          : const SizedBox(),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
        title: Text("CÀI ĐẶT",
            style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w900,
                fontSize: 22,
                letterSpacing: 1.2)),
        background: Container(color: bgColor),
      ),
    );
  }

  Widget _sectionTitle(String title, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(title,
          style: TextStyle(
              color: textColor.withOpacity(0.6),
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 1.5)),
    );
  }

  Widget _buildSettingCard(
      bool isDark, Color cardColor, Color borderColor, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _settingItem(
      {required IconData icon,
      required Color iconColor,
      required String title,
      String? subtitle,
      Widget? trailing,
      VoidCallback? onTap}) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      subtitle: subtitle != null
          ? Text(subtitle,
              style: const TextStyle(fontSize: 13, color: Colors.grey))
          : null,
      trailing: trailing,
    );
  }

  Widget _divider(Color borderColor) {
    return Divider(height: 1, indent: 60, color: borderColor);
  }
}
