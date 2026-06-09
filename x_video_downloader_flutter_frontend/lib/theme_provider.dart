import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Available accent color options.
enum AccentColor {
  green('Green', Colors.green, Color(0xFF2E7D32)),
  blue('Blue', Colors.blue, Color(0xFF1565C0)),
  purple('Purple', Colors.purple, Color(0xFF6A1B9A)),
  orange('Orange', Colors.orange, Color(0xFFE65100)),
  red('Red', Colors.red, Color(0xFFC62828)),
  teal('Teal', Colors.teal, Color(0xFF00695C));

  final String label;
  final MaterialColor materialColor;
  final Color darkSeed;
  const AccentColor(this.label, this.materialColor, this.darkSeed);

  Color get seed => materialColor;
}

/// Manages theme mode (light/dark/system) and accent color.
class ThemeProvider extends ChangeNotifier {
  static const _keyMode = 'theme_mode';
  static const _keyAccent = 'theme_accent';

  ThemeMode _mode = ThemeMode.system;
  AccentColor _accent = AccentColor.green;

  ThemeMode get mode => _mode;
  AccentColor get accent => _accent;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMode = prefs.getString(_keyMode);
    if (savedMode != null) {
      _mode = ThemeMode.values.firstWhere(
        (m) => m.name == savedMode,
        orElse: () => ThemeMode.system,
      );
    }
    final savedAccent = prefs.getString(_keyAccent);
    if (savedAccent != null) {
      _accent = AccentColor.values.firstWhere(
        (a) => a.name == savedAccent,
        orElse: () => AccentColor.green,
      );
    }
    notifyListeners();
  }

  Future<void> setMode(ThemeMode mode) async {
    _mode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyMode, mode.name);
  }

  Future<void> setAccent(AccentColor accent) async {
    _accent = accent;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAccent, accent.name);
  }
}
