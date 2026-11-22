import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme.dart';

class ThemeSettings {
  final AppThemeMode themeMode;
  final AppColorTheme colorTheme;
  final AppFontSize fontSize;

  ThemeSettings({
    required this.themeMode,
    required this.colorTheme,
    required this.fontSize,
  });

  ThemeSettings copyWith({
    AppThemeMode? themeMode,
    AppColorTheme? colorTheme,
    AppFontSize? fontSize,
  }) {
    return ThemeSettings(
      themeMode: themeMode ?? this.themeMode,
      colorTheme: colorTheme ?? this.colorTheme,
      fontSize: fontSize ?? this.fontSize,
    );
  }
}

class ThemeNotifier extends StateNotifier<ThemeSettings> {
  ThemeNotifier()
      : super(
          ThemeSettings(
            themeMode: AppThemeMode.system,
            colorTheme: AppColorTheme.microsoftBlue,
            fontSize: AppFontSize.medium,
          ),
        ) {
    _loadPreferences();
  }

  static const String _kThemeModeKey = 'pref_theme_mode';
  static const String _kColorThemeKey = 'pref_color_theme';
  static const String _kFontSizeKey = 'pref_font_size';

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    final modeIndex = prefs.getInt(_kThemeModeKey);
    final colorIndex = prefs.getInt(_kColorThemeKey);
    final fontIndex = prefs.getInt(_kFontSizeKey);

    state = ThemeSettings(
      themeMode: modeIndex != null ? AppThemeMode.values[modeIndex] : AppThemeMode.system,
      colorTheme: colorIndex != null ? AppColorTheme.values[colorIndex] : AppColorTheme.microsoftBlue,
      fontSize: fontIndex != null ? AppFontSize.values[fontIndex] : AppFontSize.medium,
    );
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kThemeModeKey, mode.index);
  }

  Future<void> setColorTheme(AppColorTheme colorTheme) async {
    state = state.copyWith(colorTheme: colorTheme);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kColorThemeKey, colorTheme.index);
  }

  Future<void> setFontSize(AppFontSize fontSize) async {
    state = state.copyWith(fontSize: fontSize);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kFontSizeKey, fontSize.index);
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeSettings>((ref) {
  return ThemeNotifier();
});
