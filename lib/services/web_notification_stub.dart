// Stub for non-web platforms — does nothing.
class WebNotification {
  static Future<void> requestPermission() async {}
  static void show(String title, String body) {}
}
