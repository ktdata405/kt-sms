import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/native/sms_channel.dart';
import '../../../core/services/sms_classifier.dart';
import '../../conversation/presentation/conversation_screen.dart';
import 'package:intl/intl.dart';

class RemindersScreen extends ConsumerStatefulWidget {
  const RemindersScreen({super.key});

  @override
  ConsumerState<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends ConsumerState<RemindersScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _reminders = [];
  final NumberFormat _inrFormat = NumberFormat('#,##,##0.00', 'en_IN');
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToTop = false;
  Set<String> _dismissedReminderKeys = <String>{};

  static const String _dismissedReminderStorageKey = 'dismissed_reminder_keys';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadReminders();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final shouldShow =
        _scrollController.hasClients && _scrollController.offset > 280;
    if (shouldShow != _showScrollToTop) {
      setState(() => _showScrollToTop = shouldShow);
    }
  }

  Future<void> _loadDismissedReminderKeys() async {
    final prefs = await SharedPreferences.getInstance();
    _dismissedReminderKeys =
        prefs.getStringList(_dismissedReminderStorageKey)?.toSet() ??
        <String>{};
  }

  Future<void> _dismissReminder(String reminderKey) async {
    final prefs = await SharedPreferences.getInstance();
    final updated = {..._dismissedReminderKeys, reminderKey};
    await prefs.setStringList(_dismissedReminderStorageKey, updated.toList());
    if (!mounted) return;
    setState(() {
      _dismissedReminderKeys = updated;
      _reminders.removeWhere((e) => e['reminderKey'] == reminderKey);
    });
  }

  Future<void> _loadReminders() async {
    setState(() => _isLoading = true);
    try {
      await _loadDismissedReminderKeys();
      final messages = await SmsChannel.getSmsMessages();
      final uniqueReminders = <String, Map<String, dynamic>>{};
      final thirtyDaysAgo =
          DateTime.now()
              .subtract(const Duration(days: 30))
              .millisecondsSinceEpoch;

      for (var msg in messages) {
        if (msg.date < thirtyDaysAgo) continue;
        final classified = SmsClassifier.classify(msg.address, msg.body);
        if (classified.category == 'Bills') {
          final dueDate =
              classified.dueDate ?? DateTime.now().add(const Duration(days: 3));
          final normalizedSender = msg.address.trim().toUpperCase();
          final normalizedBody = msg.body.toLowerCase().replaceAll(
            RegExp(r'\s+'),
            ' ',
          );
          final amountKey =
              classified.amount?.toStringAsFixed(2) ?? 'no-amount';
          final dedupeKey =
              '$normalizedSender|$amountKey|${dueDate.year}-${dueDate.month}-${dueDate.day}|${normalizedBody.substring(0, normalizedBody.length > 24 ? 24 : normalizedBody.length)}';
          if (_dismissedReminderKeys.contains(dedupeKey)) continue;

          final current = {
            'address': msg.address,
            'threadId': msg.threadId,
            'sender': msg.contactName ?? msg.address,
            'body': msg.body,
            'amount': classified.amount,
            'dueDate': dueDate,
            'date': msg.date,
            'reminderKey': dedupeKey,
          };

          final existing = uniqueReminders[dedupeKey];
          if (existing == null ||
              (current['date'] as int) > (existing['date'] as int)) {
            uniqueReminders[dedupeKey] = current;
          }
        }
      }

      final rems =
          uniqueReminders.values.toList()..sort((a, b) {
            final dueA = a['dueDate'] as DateTime;
            final dueB = b['dueDate'] as DateTime;
            final byDue = dueA.compareTo(dueB);
            if (byDue != 0) return byDue;
            return (b['date'] as int).compareTo(a['date'] as int);
          });

      setState(() {
        _reminders = rems;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Reminders & Bills'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReminders,
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Upcoming Bills & Deadlines (${_reminders.length})',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  if (_reminders.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(
                        child: Text('No bill reminders detected from SMS.'),
                      ),
                    )
                  else
                    ..._reminders.map((rem) {
                      final dueDate = rem['dueDate'] as DateTime;
                      final amount = rem['amount'] as double?;
                      final dateStr = DateFormat('MMM d, yyyy').format(dueDate);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Chip(
                                    label: Text(rem['sender'] as String),
                                    backgroundColor:
                                        theme.colorScheme.primaryContainer,
                                  ),
                                  Text(
                                    'Due: $dateStr',
                                    style: TextStyle(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                amount != null
                                    ? 'Amount Due: Rs. ${_inrFormat.format(amount)}'
                                    : 'Bill Payment Reminder',
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                rem['body'] as String,
                                style: theme.textTheme.bodySmall,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton.icon(
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder:
                                              (context) => ConversationScreen(
                                                address:
                                                    rem['address'] as String,
                                                contactName:
                                                    rem['sender'] as String,
                                                threadId:
                                                    rem['threadId'] as String?,
                                                initialBody:
                                                    rem['body'] as String,
                                              ),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.chat_bubble_outline),
                                    label: const Text('Open Message'),
                                  ),
                                  TextButton.icon(
                                    onPressed:
                                        () => _dismissReminder(
                                          rem['reminderKey'] as String,
                                        ),
                                    icon: const Icon(
                                      Icons.visibility_off_outlined,
                                    ),
                                    label: const Text('Dismiss'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                ],
              ),
      floatingActionButton:
          _showScrollToTop
              ? FloatingActionButton.small(
                heroTag: 'reminders-top',
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
