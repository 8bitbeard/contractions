import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const prefKey = 'theme_mode_dark';

  ThemeMode _mode;

  ThemeProvider({bool initialDark = false})
      : _mode = initialDark ? ThemeMode.dark : ThemeMode.light;

  ThemeMode get mode => _mode;
  bool get isDark => _mode == ThemeMode.dark;

  Future<void> toggle() async {
    _mode = _mode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefKey, _mode == ThemeMode.dark);
  }
}
