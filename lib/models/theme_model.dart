import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeModel extends ChangeNotifier {
  static const String _themeKey = 'isDarkMode';

  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  ThemeMode get themeMode {
    return _isDarkMode ? ThemeMode.dark : ThemeMode.light;
  }

  // Загружаем сохранённую тему.
  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();

    _isDarkMode = prefs.getBool(_themeKey) ?? false;

    notifyListeners();
  }

  // Переключаем тему и сохраняем выбор.
  Future<void> setDarkMode(bool value) async {
    _isDarkMode = value;

    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, value);
  }
}
