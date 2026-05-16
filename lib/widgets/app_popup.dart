import 'package:flutter/material.dart';

class AppPopup {
  static Future<void> show(
    BuildContext context, {
    required String message,
    String title = 'Thông báo',
    Color color = const Color(0xFF238636),
    IconData icon = Icons.info_outline,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 360,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Theme.of(ctx).brightness == Brightness.dark
                  ? const Color(0xFF161B22)
                  : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Theme.of(ctx).brightness == Brightness.dark
                    ? const Color(0xFF30363D)
                    : const Color(0xFFD0D7DE),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 30,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 30),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(ctx).brightness == Brightness.dark
                        ? const Color(0xFFC9D1D9)
                        : const Color(0xFF24292F),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(ctx).brightness == Brightness.dark
                        ? const Color(0xFF8B949E)
                        : const Color(0xFF57606A),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'OK',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Future<void> success(BuildContext context, String message) {
    return show(
      context,
      title: 'Thành công',
      message: message,
      color: const Color(0xFF238636),
      icon: Icons.check_circle_outline,
    );
  }

  static Future<void> error(BuildContext context, String message) {
    return show(
      context,
      title: 'Có lỗi xảy ra',
      message: message,
      color: Colors.redAccent,
      icon: Icons.error_outline,
    );
  }
}
