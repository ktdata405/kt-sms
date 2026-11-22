import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/native/sms_channel.dart';
import '../../../core/services/sms_classifier.dart';
import 'package:intl/intl.dart';

class RemindersScreen extends ConsumerStatefulWidget {
  const RemindersScreen({super.key});

  @override
  ConsumerState<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends ConsumerState<RemindersScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _reminders = [];

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    setState(() => _isLoading = true);
    try {
      final messages = await SmsChannel.getSmsMessages();
      final rems = <Map<String, dynamic>>[];

      for (var msg in messages) {
        final classified = SmsClassifier.classify(msg.address, msg.body);
        if (classified.category == 'Bills') {
          rems.add({
            'sender': msg.address,
            'body': msg.body,
            'amount': classified.amount,
            'dueDate': classified.dueDate ?? DateTime.now().add(const Duration(days: 3)),
          });
        }
      }

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
    final currencyFormat = NumberFormat.currency(symbol: '\$');

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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('Upcoming Bills & Deadlines (${_reminders.length})', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                if (_reminders.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(child: Text('No bill reminders detected from SMS.')),
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Chip(
                                  label: Text(rem['sender']),
                                  backgroundColor: theme.colorScheme.primaryContainer,
                                ),
                                Text(
                                  'Due: $dateStr',
                                  style: TextStyle(
                                    color: theme.colorScheme.error,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              amount != null ? 'Amount Due: ${currencyFormat.format(amount)}' : 'Bill Payment Reminder',
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              rem['body'],
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
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Reminder snoozed for 1 day')),
                                    );
                                  },
                                  icon: const Icon(Icons.snooze),
                                  label: const Text('Snooze'),
                                ),
                                const SizedBox(width: 8),
                                FilledButton.icon(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Marked as paid')),
                                    );
                                  },
                                  icon: const Icon(Icons.check),
                                  label: const Text('Mark Paid'),
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
    );
  }
}
