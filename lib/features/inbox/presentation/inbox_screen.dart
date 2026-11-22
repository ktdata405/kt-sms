import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/native/sms_channel.dart';
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
    'Spam'
  ];

  bool _isLoading = true;
  List<SmsMessageModel> _messages = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSmsInbox();
  }

  Future<void> _loadSmsInbox() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final status = await Permission.sms.status;
    if (!status.isGranted) {
      final result = await Permission.sms.request();
      if (!result.isGranted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'SMS permission is required to view messages.';
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

    // Filter messages based on _selectedFilter
    final filteredMessages = _messages.where((msg) {
      if (_selectedFilter == 'All') return true;
      if (_selectedFilter == 'Unread') return !msg.read;
      // Other categories can be classified or simulated
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('KT - SMS Organizer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSmsInbox,
            tooltip: 'Refresh SMS',
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Global search
            },
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
      body: _isLoading
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
                          child: const Text('Grant Permission & Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : filteredMessages.isEmpty
                  ? const Center(child: Text('No messages found.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredMessages.length,
                      itemBuilder: (context, index) {
                        final msg = filteredMessages[index];
                        final dateStr = DateFormat('MMM d, h:mm a').format(
                          DateTime.fromMillisecondsSinceEpoch(msg.date),
                        );

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: CircleAvatar(
                              backgroundColor: theme.colorScheme.primaryContainer,
                              foregroundColor: theme.colorScheme.onPrimaryContainer,
                              child: Text(msg.address.isNotEmpty ? msg.address[0].toUpperCase() : '?'),
                            ),
                            title: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    msg.address,
                                    style: TextStyle(
                                      fontWeight: msg.read ? FontWeight.normal : FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  dateStr,
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                msg.body,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: msg.read ? FontWeight.normal : FontWeight.bold,
                                ),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Open compose screen
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
