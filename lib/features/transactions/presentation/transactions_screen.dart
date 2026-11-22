import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/native/sms_channel.dart';
import '../../../core/services/sms_classifier.dart';
import 'package:intl/intl.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _transactions = [];
  double _totalSpent = 0.0;
  double _totalCredited = 0.0;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);
    try {
      final messages = await SmsChannel.getSmsMessages();
      final txs = <Map<String, dynamic>>[];
      double spent = 0.0;
      double credited = 0.0;

      for (var msg in messages) {
        final classified = SmsClassifier.classify(msg.address, msg.body);
        if (classified.category == 'Transactions' && classified.amount != null) {
          final isDebit = msg.body.toLowerCase().contains('debited') ||
              msg.body.toLowerCase().contains('spent');
          if (isDebit) {
            spent += classified.amount!;
          } else {
            credited += classified.amount!;
          }

          txs.add({
            'address': msg.address,
            'body': msg.body,
            'amount': classified.amount,
            'isDebit': isDebit,
            'date': msg.date,
          });
        }
      }

      setState(() {
        _transactions = txs;
        _totalSpent = spent;
        _totalCredited = credited;
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
        title: const Text('Transactions & Expenses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTransactions,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Extracted Expenses Summary', style: theme.textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Text(
                          currencyFormat.format(_totalSpent),
                          style: theme.textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Credited', style: TextStyle(color: Colors.green)),
                                Text(currencyFormat.format(_totalCredited), style: const TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text('Debited', style: TextStyle(color: Colors.red)),
                                Text(currencyFormat.format(_totalSpent), style: const TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Transaction Messages (${_transactions.length})', style: theme.textTheme.titleLarge),
                const SizedBox(height: 8),
                if (_transactions.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(child: Text('No bank or transaction SMS found.')),
                  )
                else
                  ..._transactions.map((tx) {
                    final isDebit = tx['isDebit'] as bool;
                    final amount = tx['amount'] as double;
                    final dateStr = DateFormat('MMM d, yyyy • h:mm a').format(
                      DateTime.fromMillisecondsSinceEpoch(tx['date'] as int),
                    );

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isDebit ? Colors.red.withValues(alpha: 0.1) : Colors.green.withValues(alpha: 0.1),
                          child: Icon(
                            isDebit ? Icons.arrow_upward : Icons.arrow_downward,
                            color: isDebit ? Colors.red : Colors.green,
                          ),
                        ),
                        title: Text(tx['address']),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(tx['body'], maxLines: 2, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Text(dateStr, style: theme.textTheme.bodySmall),
                          ],
                        ),
                        trailing: Text(
                          '${isDebit ? '-' : '+'}${currencyFormat.format(amount)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDebit ? Colors.red : Colors.green,
                          ),
                        ),
                      ),
                    );
                  }),
              ],
            ),
    );
  }
}
