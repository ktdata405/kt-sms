import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/router/app_router.dart';
import 'core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.initialize();
  runApp(const ProviderScope(child: KtSmsApp()));
}

class KtSmsApp extends ConsumerWidget {
  const KtSmsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeSettings = ref.watch(themeProvider);
    final router = ref.watch(routerProvider);

    ThemeMode mode;
    switch (themeSettings.themeMode) {
      case AppThemeMode.light:
        mode = ThemeMode.light;
        break;
      case AppThemeMode.dark:
        mode = ThemeMode.dark;
        break;
      case AppThemeMode.amoled:
        mode = ThemeMode.dark;
        break;
      case AppThemeMode.system:
        mode = ThemeMode.system;
        break;
    }

    return MaterialApp.router(
      title: 'KT - SMS Organizer',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(
        themeSettings.colorTheme,
        themeSettings.fontSize,
        uiStyle: themeSettings.uiStyle,
      ),
      darkTheme:
          themeSettings.themeMode == AppThemeMode.amoled
              ? AppTheme.amoledTheme(
                themeSettings.colorTheme,
                themeSettings.fontSize,
                uiStyle: themeSettings.uiStyle,
              )
              : AppTheme.darkTheme(
                themeSettings.colorTheme,
                themeSettings.fontSize,
                uiStyle: themeSettings.uiStyle,
              ),
      themeMode: mode,
      routerConfig: router,
    );
  }
}
