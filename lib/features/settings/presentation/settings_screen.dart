import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/services/backup_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _selectedAppIcon = 'Default';
  final List<String> _iconOptions = [
    'Default',
    'Crimson Red',
    'Classic Blue',
    'Dark Minimal',
  ];
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToTop = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadAppIconPreference();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final shouldShow =
        _scrollController.hasClients && _scrollController.offset > 320;
    if (shouldShow != _showScrollToTop) {
      setState(() => _showScrollToTop = shouldShow);
    }
  }

  Future<void> _loadAppIconPreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedAppIcon = prefs.getString('pref_app_icon') ?? 'Default';
    });
  }

  Future<void> _saveAppIconPreference(String icon) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pref_app_icon', icon);
    setState(() {
      _selectedAppIcon = icon;
    });
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('App icon style updated to: $icon')));
  }

  @override
  Widget build(BuildContext context) {
    final themeSettings = ref.watch(themeProvider);
    final themeNotifier = ref.read(themeProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Appearance & Branding',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
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
                    items:
                        AppThemeMode.values.map((mode) {
                          return DropdownMenuItem(
                            value: mode,
                            child: Text(mode.name.toUpperCase()),
                          );
                        }).toList(),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('UI Style'),
                  subtitle: Text(
                    themeSettings.uiStyle == AppUiStyle.clearSms
                        ? 'Clear SMS'
                        : 'Org',
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: SegmentedButton<AppUiStyle>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment<AppUiStyle>(
                        value: AppUiStyle.clearSms,
                        label: Text('Clear SMS'),
                      ),
                      ButtonSegment<AppUiStyle>(
                        value: AppUiStyle.organizer,
                        label: Text('Org'),
                      ),
                    ],
                    selected: {themeSettings.uiStyle},
                    onSelectionChanged: (selection) {
                      if (selection.isNotEmpty) {
                        themeNotifier.setUiStyle(selection.first);
                      }
                    },
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
                    items:
                        AppColorTheme.values.map((color) {
                          return DropdownMenuItem(
                            value: color,
                            child: Text(color.name),
                          );
                        }).toList(),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('App Icon Style'),
                  subtitle: Text(_selectedAppIcon),
                  trailing: DropdownButton<String>(
                    value: _selectedAppIcon,
                    onChanged: (icon) {
                      if (icon != null) _saveAppIconPreference(icon);
                    },
                    items:
                        _iconOptions.map((icon) {
                          return DropdownMenuItem(
                            value: icon,
                            child: Text(icon),
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
                    items:
                        AppFontSize.values.map((size) {
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
          Text(
            'Smart Features & Inbox',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Automatic Categorization'),
                  subtitle: const Text(
                    'Sort messages into Personal, Transactions, OTP, Offers',
                  ),
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
          Text(
            'Privacy & Backup',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('App Lock'),
                  subtitle: const Text(
                    'Protect SMS with biometric authentication',
                  ),
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
                      builder:
                          (dialogContext) => AlertDialog(
                            title: const Text('Backup & Restore'),
                            content: const Text(
                              'Would you like to create a local backup of your messages and settings?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(dialogContext),
                                child: const Text('Cancel'),
                              ),
                              FilledButton(
                                onPressed: () async {
                                  Navigator.pop(dialogContext);
                                  final path =
                                      await BackupService.createBackup();
                                  if (!context.mounted) return;
                                  if (path != null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Backup created successfully at: $path',
                                        ),
                                      ),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Failed to create backup',
                                        ),
                                      ),
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
          Text(
            'About',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          const Card(
            child: Column(
              children: [
                ListTile(title: Text('Version'), trailing: Text('1.0.0+1')),
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
      floatingActionButton:
          _showScrollToTop
              ? FloatingActionButton.small(
                heroTag: 'settings-top',
                onPressed: () {
                  _scrollController.animateTo(
                    0,
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutCubic,
                  );
                },
                child: const Icon(Icons.vertical_align_top),
              )
              : null,
    );
  }
}
