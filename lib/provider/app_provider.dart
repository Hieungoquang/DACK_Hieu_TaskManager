import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class AppProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  Locale _locale = const Locale('vi');

  bool _isSleepModeEnabled = true;
  int _sleepStartHour = 22;
  int _sleepStartMinute = 0;
  int _sleepEndHour = 6;
  int _sleepEndMinute = 0;
  int _silencedAlarmsCount = 0;

  AppProvider() {
    _loadSettings();
  }

  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;

  bool get isSleepModeEnabled => _isSleepModeEnabled;
  int get sleepStartHour => _sleepStartHour;
  int get sleepStartMinute => _sleepStartMinute;
  int get sleepEndHour => _sleepEndHour;
  int get sleepEndMinute => _sleepEndMinute;
  int get silencedAlarmsCount => _silencedAlarmsCount;

  void _loadSettings() {
    if (Hive.isBoxOpen('settingsBox')) {
      final box = Hive.box('settingsBox');
      _isSleepModeEnabled = box.get('isSleepModeEnabled') ?? true;
      _sleepStartHour = box.get('sleepStartHour') ?? 22;
      _sleepStartMinute = box.get('sleepStartMinute') ?? 0;
      _sleepEndHour = box.get('sleepEndHour') ?? 6;
      _sleepEndMinute = box.get('sleepEndMinute') ?? 0;
      _silencedAlarmsCount = box.get('silencedAlarmsCount') ?? 0;
      
      final isDark = box.get('isDarkTheme') ?? false;
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    }
  }

  void toggleTheme(bool isDark) {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    if (Hive.isBoxOpen('settingsBox')) {
      Hive.box('settingsBox').put('isDarkTheme', isDark);
    }
    notifyListeners();
  }

  void changeLanguage(String langCode) {
    _locale = Locale(langCode);
    notifyListeners();
  }

  void updateSleepMode(bool enabled) {
    _isSleepModeEnabled = enabled;
    if (Hive.isBoxOpen('settingsBox')) {
      Hive.box('settingsBox').put('isSleepModeEnabled', enabled);
    }
    notifyListeners();
  }

  void updateSleepTime(int startH, int startM, int endH, int endM) {
    _sleepStartHour = startH;
    _sleepStartMinute = startM;
    _sleepEndHour = endH;
    _sleepEndMinute = endM;
    if (Hive.isBoxOpen('settingsBox')) {
      final box = Hive.box('settingsBox');
      box.put('sleepStartHour', startH);
      box.put('sleepStartMinute', startM);
      box.put('sleepEndHour', endH);
      box.put('sleepEndMinute', endM);
    }
    notifyListeners();
  }

  void incrementSilencedAlarms() {
    _silencedAlarmsCount++;
    if (Hive.isBoxOpen('settingsBox')) {
      Hive.box('settingsBox').put('silencedAlarmsCount', _silencedAlarmsCount);
    }
    notifyListeners();
  }

  void clearSilencedAlarms() {
    _silencedAlarmsCount = 0;
    if (Hive.isBoxOpen('settingsBox')) {
      Hive.box('settingsBox').put('silencedAlarmsCount', 0);
    }
    notifyListeners();
  }
}
