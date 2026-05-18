// Web implementation using browser Notification API.
import 'dart:html' as html;

class WebNotification {
  static Future<void> requestPermission() async {
    if (html.Notification.supported) {
      final permission = html.Notification.permission;
      if (permission != 'granted' && permission != 'denied') {
        await html.Notification.requestPermission();
      }
    }
  }

  static void show(String title, String body) {
    if (!html.Notification.supported) return;
    if (html.Notification.permission != 'granted') return;
    html.Notification(title, body: body);
  }
}
