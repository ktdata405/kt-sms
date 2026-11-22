import 'package:flutter/material.dart';

enum AppThemeMode { light, dark, amoled, system }

enum AppColorTheme {
  microsoftBlue,
  royalBlue,
  purple,
  teal,
  green,
  orange,
  red,
  pink,
  indigo,
  monochrome,
}

enum AppFontSize { small, medium, large, extraLarge }

class AppTheme {
  static Color getPrimaryColor(AppColorTheme colorTheme) {
    switch (colorTheme) {
      case AppColorTheme.microsoftBlue:
        return const Color(0xFF0078D4);
      case AppColorTheme.royalBlue:
        return const Color(0xFF2563EB);
      case AppColorTheme.purple:
        return const Color(0xFF7C3AED);
      case AppColorTheme.teal:
        return const Color(0xFF0D9488);
      case AppColorTheme.green:
        return const Color(0xFF16A34A);
      case AppColorTheme.orange:
        return const Color(0xFFEA580C);
      case AppColorTheme.red:
        return const Color(0xFFDC2626);
      case AppColorTheme.pink:
        return const Color(0xFFDB2777);
      case AppColorTheme.indigo:
        return const Color(0xFF4F46E5);
      case AppColorTheme.monochrome:
        return const Color(0xFF334155);
    }
  }

  static double getScaleFactor(AppFontSize fontSize) {
    switch (fontSize) {
      case AppFontSize.small:
        return 0.85;
      case AppFontSize.medium:
        return 1.0;
      case AppFontSize.large:
        return 1.15;
      case AppFontSize.extraLarge:
        return 1.3;
    }
  }

  static ThemeData lightTheme(AppColorTheme colorTheme, AppFontSize fontSize) {
    final primary = getPrimaryColor(colorTheme);
    final scale = getScaleFactor(fontSize);

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: Color(0xFFF8FAFC),
        surfaceTintColor: Colors.transparent,
      ),
    );

    return base.copyWith(
      textTheme: _scaledTextTheme(base.textTheme, scale),
    );
  }

  static ThemeData darkTheme(AppColorTheme colorTheme, AppFontSize fontSize) {
    final primary = getPrimaryColor(colorTheme);
    final scale = getScaleFactor(fontSize);

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xFF0F172A),
      cardTheme: CardThemeData(
        elevation: 0,
        color: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF334155), width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: Color(0xFF0F172A),
        surfaceTintColor: Colors.transparent,
      ),
    );

    return base.copyWith(
      textTheme: _scaledTextTheme(base.textTheme, scale),
    );
  }

  static ThemeData amoledTheme(AppColorTheme colorTheme, AppFontSize fontSize) {
    final primary = getPrimaryColor(colorTheme);
    final scale = getScaleFactor(fontSize);

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: Colors.black,
      cardTheme: CardThemeData(
        elevation: 0,
        color: const Color(0xFF121212),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF27272A), width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: Colors.black,
        surfaceTintColor: Colors.transparent,
      ),
    );

    return base.copyWith(
      textTheme: _scaledTextTheme(base.textTheme, scale),
    );
  }

  static TextTheme _scaledTextTheme(TextTheme base, double scale) {
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(fontSize: (base.displayLarge?.fontSize ?? 57) * scale),
      displayMedium: base.displayMedium?.copyWith(fontSize: (base.displayMedium?.fontSize ?? 45) * scale),
      displaySmall: base.displaySmall?.copyWith(fontSize: (base.displaySmall?.fontSize ?? 36) * scale),
      headlineLarge: base.headlineLarge?.copyWith(fontSize: (base.headlineLarge?.fontSize ?? 32) * scale),
      headlineMedium: base.headlineMedium?.copyWith(fontSize: (base.headlineMedium?.fontSize ?? 28) * scale),
      headlineSmall: base.headlineSmall?.copyWith(fontSize: (base.headlineSmall?.fontSize ?? 24) * scale),
      titleLarge: base.titleLarge?.copyWith(fontSize: (base.titleLarge?.fontSize ?? 22) * scale),
      titleMedium: base.titleMedium?.copyWith(fontSize: (base.titleMedium?.fontSize ?? 16) * scale),
      titleSmall: base.titleSmall?.copyWith(fontSize: (base.titleSmall?.fontSize ?? 14) * scale),
      bodyLarge: base.bodyLarge?.copyWith(fontSize: (base.bodyLarge?.fontSize ?? 16) * scale),
      bodyMedium: base.bodyMedium?.copyWith(fontSize: (base.bodyMedium?.fontSize ?? 14) * scale),
      bodySmall: base.bodySmall?.copyWith(fontSize: (base.bodySmall?.fontSize ?? 12) * scale),
      labelLarge: base.labelLarge?.copyWith(fontSize: (base.labelLarge?.fontSize ?? 14) * scale),
      labelMedium: base.labelMedium?.copyWith(fontSize: (base.labelMedium?.fontSize ?? 12) * scale),
      labelSmall: base.labelSmall?.copyWith(fontSize: (base.labelSmall?.fontSize ?? 11) * scale),
    );
  }
}
