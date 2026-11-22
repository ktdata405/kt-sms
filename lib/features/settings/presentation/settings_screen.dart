import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/services/backup_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeSettings = ref.watch(themeProvider);
    final themeNotifier = ref.read(themeProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Appearance', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary)),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('Theme Mode'),
                  subtitle: Text(themeSettings.themeMode.name.toUpperCase()),
                  trailing: DropdownButton<AppThemeMode>(
                    value: themeSettings.themeMode,
                    onChanged: (mode) {
                      if (mode != null) themeNotifier.setThemeMode(mode);
                    },
                    items: AppThemeMode.values.map((mode) {
                      return DropdownMenuItem(
                        value: mode,
                        child: Text(mode.name.toUpperCase()),
                      );
                    }).toList(),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Color Theme'),
                  subtitle: Text(themeSettings.colorTheme.name),
                  trailing: DropdownButton<AppColorTheme>(
                    value: themeSettings.colorTheme,
                    onChanged: (color) {
                      if (color != null) themeNotifier.setColorTheme(color);
                    },
                    items: AppColorTheme.values.map((color) {
                      return DropdownMenuItem(
                        value: color,
                        child: Text(color.name),
                      );
                    }).toList(),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Font Size'),
                  subtitle: Text(themeSettings.fontSize.name.toUpperCase()),
                  trailing: DropdownButton<AppFontSize>(
                    value: themeSettings.fontSize,
                    onChanged: (size) {
                      if (size != null) themeNotifier.setFontSize(size);
                    },
                    items: AppFontSize.values.map((size) {
                      return DropdownMenuItem(
                        value: size,
                        child: Text(size.name.toUpperCase()),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Smart Features & Inbox', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary)),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Automatic Categorization'),
                  subtitle: const Text('Sort messages into Personal, Transactions, OTP, Offers'),
                  value: true,
                  onChanged: (val) {},
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Smart Reminders Detection'),
                  subtitle: const Text('Extract bills and deadlines from SMS'),
                  value: true,
                  onChanged: (val) {},
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Spam Protection'),
                  subtitle: const Text('Automatically filter promotional spam'),
                  value: true,
                  onChanged: (val) {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Privacy & Backup', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary)),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('App Lock'),
                  subtitle: const Text('Protect SMS with biometric authentication'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Backup & Restore'),
                  subtitle: const Text('Local JSON backup & export'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    showDialog(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        title: const Text('Backup & Restore'),
                        content: const Text('Would you like to create a local backup of your messages and settings?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () async {
                              Navigator.pop(dialogContext);
                              final path = await BackupService.createBackup();
                              if (!context.mounted) return;
                              if (path != null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Backup created successfully at: $path')),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Failed to create backup')),
                                );
                              }
                            },
                            child: const Text('Create Backup'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('About', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary)),
          const SizedBox(height: 8),
          const Card(
            child: Column(
              children: [
                ListTile(
                  title: Text('Version'),
                  trailing: Text('1.0.0+1'),
                ),
                Divider(height: 1),
                ListTile(
                  title: Text('Microsoft SMS Organizer Inspired'),
                  subtitle: Text('Production-quality Android SMS app'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
