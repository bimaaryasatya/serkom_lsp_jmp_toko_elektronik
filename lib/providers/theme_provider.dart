import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _keyIsDarkMode = 'isDarkMode';
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  ThemeProvider() {
    _loadThemeFromPrefs();
  }

  // Load status Dark Mode dari SharedPreferences saat aplikasi dibuka
  Future<void> _loadThemeFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isDarkMode = prefs.getBool(_keyIsDarkMode) ?? false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading theme preference: $e');
    }
  }

  // Toggle mode Terang / Gelap dan simpan ke SharedPreferences
  Future<void> toggleTheme(bool isOn) async {
    _isDarkMode = isOn;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyIsDarkMode, isOn);
    } catch (e) {
      debugPrint('Error saving theme preference: $e');
    }
  }
}
