import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppTheme {
  static const _key = 'appearance_theme';
  static final _preferences = SharedPreferencesAsync();
  static final mode = ValueNotifier(ThemeMode.system);

  static Future<void> load() async {
    final stored = await _preferences.getString(_key);
    mode.value = switch (stored) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  static Future<void> save(ThemeMode selection) async {
    await _preferences.setString(_key, selection.name);
    mode.value = selection;
  }

  static final light = _theme(Brightness.light);
  static final dark = _theme(Brightness.dark);

  static ThemeData _theme(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final colors = ColorScheme.fromSeed(
      seedColor: const Color(0xFF5288DA),
      brightness: brightness,
    );
    return ThemeData(
      useMaterial3: false,
      colorScheme: colors,
      primarySwatch: Colors.blue,
      scaffoldBackgroundColor: dark ? colors.surface : Colors.white,
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }
}

extension NoticeboardTheme on BuildContext {
  ColorScheme get colors => Theme.of(this).colorScheme;
  Color get pageSurface => Theme.of(this).scaffoldBackgroundColor;
  bool get isDark => colors.brightness == Brightness.dark;
  Color get noticeTint =>
      isDark ? colors.surfaceContainerHigh : const Color(0xFFEDF4FF);
  Color get mutedText => isDark ? colors.onSurfaceVariant : Colors.black54;
}
