// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// class ThemeModel with ChangeNotifier {
//   bool _isDarkMode = false;

//   bool get isDarkMode => _isDarkMode;

//   set isDarkMode(bool value) {
//     _isDarkMode = value;
//     notifyListeners();
//     _saveThemeMode();
//   }

//   Future<void> _loadThemeMode() async {
//     final prefs = await SharedPreferences.getInstance();
//     _isDarkMode = prefs.getBool('isDarkMode') ?? false;
//     notifyListeners();
//   }

//   Future<void> _saveThemeMode() async {
//     final prefs = await SharedPreferences.getInstance();
//     prefs.setBool('isDarkMode', _isDarkMode);
//   }

//   ThemeModel() {
//     _loadThemeMode();
//   }

//   void toggleTheme() {
//     _isDarkMode = !_isDarkMode;
//     notifyListeners();
//     _saveThemeMode();
//   }
// }