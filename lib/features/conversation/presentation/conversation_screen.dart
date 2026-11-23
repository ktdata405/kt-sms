import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/native/sms_channel.dart';
import 'package:intl/intl.dart';

class ConversationScreen extends ConsumerStatefulWidget {
  final String address;
  final String initialBody;

  const ConversationScreen({
    super.key,
    required this.address,
    required this.initialBody,
  });

  @override
  ConsumerState<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends ConsumerState<ConversationScreen> {
  late final TextEditingController _addressController;
  late final TextEditingController _messageController;
  bool _isSending = false;
  bool _isLoadingHistory = false;
  List<SmsMessageModel> _messages = [];
  Map<String, String> _contactsMap = {};
  List<MapEntry<String, String>> _filteredContacts = [];
  bool _showContactSuggestions = false;

  @override
  void initState() {
    super.initState();
    _addressController = TextEditingController(text: widget.address);
    _messageController = TextEditingController();

    if (widget.address.isNotEmpty) {
      _loadChatHistory(widget.address);
    }

    _loadContacts();

    _addressController.addListener(_onAddressChanged);
  }

  @override
  void dispose() {
    _addressController.removeListener(_onAddressChanged);
    _addressController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    final contacts = await SmsChannel.getContacts();
    if (mounted) {
      setState(() {
        _contactsMap = contacts;
      });
    }
  }

  void _onAddressChanged() {
    final query = _addressController.text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _filteredContacts = [];
        _showContactSuggestions = false;
      });
      return;
    }

    final matches = _contactsMap.entries.where((entry) {
      final name = entry.value.toLowerCase();
      final number = entry.key.toLowerCase();
      return name.contains(query) || number.contains(query);
    }).toList();

    setState(() {
      _filteredContacts = matches;
      _showContactSuggestions = matches.isNotEmpty;
    });
  }

  Future<void> _loadChatHistory(String address) async {
    setState(() => _isLoadingHistory = true);
    try {
      final history = await SmsChannel.getThreadMessages(threadId: '', address: address);
      if (mounted) {
        setState(() {
          _messages = history;
          _isLoadingHistory = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingHistory = false);
      }
    }
  }

  Future<void> _sendSms() async {
    final address = _addressController.text.trim();
    final body = _messageController.text.trim();

    if (address.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter recipient and message body')),
      );
      return;
    }

    setState(() {
      _isSending = true;
    });

    final success = await SmsChannel.sendSms(address, body);

    if (!mounted) return;

    setState(() {
      _isSending = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('SMS sent successfully')),
      );
      _messageController.clear();
      // Reload history for this address
      _loadChatHistory(address);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send SMS')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isNew = widget.address.isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: isNew
            ? TextField(
                controller: _addressController,
                decoration: const InputDecoration(
                  hintText: 'Type contact name or number...',
                  border: InputBorder.none,
                ),
                style: const TextStyle(fontWeight: FontWeight.bold),
              )
            : Text(_contactsMap[widget.address] ?? widget.address),
        actions: [
          IconButton(
            icon: const Icon(Icons.call),
            onPressed: widget.address.isEmpty ? null : () {},
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: _isLoadingHistory
                    ? const Center(child: CircularProgressIndicator())
                    : _messages.isEmpty
                        ? Center(
                            child: Text(
                              isNew ? 'Search or select a contact to start messaging' : 'No previous chat history found.',
                              style: theme.textTheme.bodyMedium,
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _messages.length,
                            itemBuilder: (context, index) {
                              final msg = _messages[index];
                              final isIncoming = msg.type == 1;
                              final timeStr = DateFormat('MMM d, h:mm a').format(
                                DateTime.fromMillisecondsSinceEpoch(msg.date),
                              );

                              return Align(
                                alignment: isIncoming ? Alignment.centerLeft : Alignment.centerRight,
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(12),
                                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                                  decoration: BoxDecoration(
                                    color: isIncoming
                                        ? theme.colorScheme.surfaceContainerHighest
                                        : theme.colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        msg.body,
                                        style: TextStyle(
                                          color: isIncoming
                                              ? theme.colorScheme.onSurfaceVariant
                                              : theme.colorScheme.onPrimaryContainer,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        timeStr,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: (isIncoming
                                                  ? theme.colorScheme.onSurfaceVariant
                                                  : theme.colorScheme.onPrimaryContainer)
                                              .withValues(alpha: 0.7),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                color: theme.cardColor,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: () {},
                    ),
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          hintText: 'Type a message...',
                          border: InputBorder.none,
                        ),
                        maxLines: 4,
                        minLines: 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    FloatingActionButton(
                      mini: true,
                      onPressed: _isSending ? null : _sendSms,
                      child: _isSending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_showContactSuggestions)
            Positioned(
              top: 0,
              left: 16,
              right: 16,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _filteredContacts.length,
                    itemBuilder: (context, index) {
                      final contact = _filteredContacts[index];
                      final name = contact.value;
                      final number = contact.key;

                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?'),
                        ),
                        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(number),
                        onTap: () {
                          _addressController.text = number;
                          setState(() {
                            _showContactSuggestions = false;
                          });
                          _loadChatHistory(number);
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
