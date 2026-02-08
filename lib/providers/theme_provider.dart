import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppTheme { men, girls }

class ThemeProvider with ChangeNotifier {
  static const _prefsKey = 'app_theme';

  AppTheme _current = AppTheme.men;

  ThemeProvider() {
    _loadFromPrefs();
  }

  AppTheme get current => _current;

  ThemeData get themeData {
    switch (_current) {
      case AppTheme.girls:
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6A1B9A),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          primaryColor: const Color(0xFF6A1B9A),
          scaffoldBackgroundColor: Colors.grey[50],
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6A1B9A),
              foregroundColor: Colors.white,
            ),
          ),
        );
      case AppTheme.men:
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF0B3D91),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          primaryColor: const Color(0xFF0B3D91),
          scaffoldBackgroundColor: Colors.grey[50],
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0B3D91),
              foregroundColor: Colors.white,
            ),
          ),
        );
    }
  }

  Future<void> setTheme(AppTheme t) async {
    _current = t;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, t.toString());
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString(_prefsKey);
    if (s != null) {
      try {
        _current = AppTheme.values.firstWhere((e) => e.toString() == s);
        notifyListeners();
      } catch (_) {}
    }
  }
}
