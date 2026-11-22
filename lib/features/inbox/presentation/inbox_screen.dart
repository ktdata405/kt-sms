import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/native/sms_channel.dart';
import '../../../core/services/sms_classifier.dart';
import '../../conversation/presentation/conversation_screen.dart';
import 'package:intl/intl.dart';

class InboxScreen extends ConsumerStatefulWidget {
  const InboxScreen({super.key});

  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends ConsumerState<InboxScreen> {
  String _selectedFilter = 'All';
  final List<String> _filters = [
    'All',
    'Unread',
    'Starred',
    'Personal',
    'Transactions',
    'OTPs',
    'Promotions',
    'Bills'
  ];

  bool _isLoading = true;
  bool _isDefaultSms = true;
  List<SmsMessageModel> _messages = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkDefaultSms();
    _loadSmsInbox();
  }

  Future<void> _checkDefaultSms() async {
    final isDefault = await SmsChannel.isDefaultSmsApp();
    setState(() {
      _isDefaultSms = isDefault;
    });
  }

  Future<void> _loadSmsInbox() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final smsStatus = await Permission.sms.status;
    final contactsStatus = await Permission.contacts.status;

    if (!smsStatus.isGranted || !contactsStatus.isGranted) {
      final statuses = await [Permission.sms, Permission.contacts].request();
      if (statuses[Permission.sms]?.isGranted != true) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'SMS and Contacts permissions are required.';
        });
        return;
      }
    }

    try {
      final messages = await SmsChannel.getSmsMessages();
      setState(() {
        _messages = messages;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load SMS messages: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final filteredMessages = _messages.where((msg) {
      if (_selectedFilter == 'All') return true;
      if (_selectedFilter == 'Unread') return !msg.read;
      if (_selectedFilter == 'Starred') return false;

      final classified = SmsClassifier.classify(msg.address, msg.body);
      return classified.category == _selectedFilter;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('KT - SMS Organizer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _checkDefaultSms();
              _loadSmsInbox();
            },
            tooltip: 'Refresh SMS',
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: _filters.map((filter) {
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedFilter = filter;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          if (!_isDefaultSms)
            Container(
              color: theme.colorScheme.errorContainer,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: theme.colorScheme.onErrorContainer),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'KT-SMS is not your default SMS app.',
                      style: TextStyle(color: theme.colorScheme.onErrorContainer, fontWeight: FontWeight.bold),
                    ),
                  ),
                  FilledButton.tonal(
                    onPressed: () async {
                      await SmsChannel.requestDefaultSmsApp();
                      await _checkDefaultSms();
                    },
                    child: const Text('Set as Default'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
                              const SizedBox(height: 16),
                              Text(_errorMessage!, textAlign: TextAlign.center),
                              const SizedBox(height: 16),
                              FilledButton(
                                onPressed: _loadSmsInbox,
                                child: const Text('Grant Permissions & Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : filteredMessages.isEmpty
                        ? const Center(child: Text('No messages found in this category.'))
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredMessages.length,
                            itemBuilder: (context, index) {
                              final msg = filteredMessages[index];
                              final displayName = msg.contactName ?? msg.address;
                              final dateStr = DateFormat('MMM d, h:mm a').format(
                                DateTime.fromMillisecondsSinceEpoch(msg.date),
                              );
                              final classified = SmsClassifier.classify(msg.address, msg.body);

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(16),
                                  leading: CircleAvatar(
                                    backgroundColor: theme.colorScheme.primaryContainer,
                                    foregroundColor: theme.colorScheme.onPrimaryContainer,
                                    child: Text(displayName.isNotEmpty ? displayName[0].toUpperCase() : '?'),
                                  ),
                                  title: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          displayName,
                                          style: TextStyle(
                                            fontWeight: msg.read ? FontWeight.normal : FontWeight.bold,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.secondaryContainer,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          classified.category,
                                          style: TextStyle(fontSize: 10, color: theme.colorScheme.onSecondaryContainer),
                                        ),
                                      ),
                                    ],
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          msg.body,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontWeight: msg.read ? FontWeight.normal : FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(dateStr, style: theme.textTheme.bodySmall),
                                      ],
                                    ),
                                  ),
                                  trailing: Icon(
                                    msg.read ? Icons.done_all : Icons.circle,
                                    size: msg.read ? 20 : 12,
                                    color: msg.read ? theme.colorScheme.primary : theme.colorScheme.error,
                                  ),
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => ConversationScreen(
                                          address: msg.address,
                                          initialBody: msg.body,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const ConversationScreen(address: '', initialBody: ''),
            ),
          );
        },
        icon: const Icon(Icons.edit),
        label: const Text('Compose'),
      ),
    );
  }
}
