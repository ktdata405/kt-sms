import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/native/sms_channel.dart';

class ConversationScreen extends ConsumerStatefulWidget {
  final String address;
  final String initialBody;
  final String? threadId;
  final String? contactName;

  const ConversationScreen({
    super.key,
    required this.address,
    required this.initialBody,
    this.threadId,
    this.contactName,
  });

  @override
  ConsumerState<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends ConsumerState<ConversationScreen> {
  late final TextEditingController _addressController;
  late final TextEditingController _messageController;
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;
  bool _isLoading = false;
  List<SmsMessageModel> _messages = [];

  @override
  void initState() {
    super.initState();
    _addressController = TextEditingController(text: widget.address);
    _messageController = TextEditingController();
    if (widget.address.isNotEmpty || (widget.threadId?.isNotEmpty ?? false)) {
      _loadConversation();
      _markThreadAsRead();
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadConversation() async {
    setState(() => _isLoading = true);
    try {
      final messages = await SmsChannel.getThreadMessages(
        threadId: widget.threadId ?? '',
        address: widget.address,
      );
      if (!mounted) return;
      setState(() {
        _messages = messages;
        _isLoading = false;
      });
      _jumpToBottom();
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markThreadAsRead() async {
    await SmsChannel.markThreadAsRead(
      threadId: widget.threadId,
      address: widget.address,
    );
  }

  void _jumpToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _sendSms() async {
    final enteredAddress = _addressController.text.trim();
    final body = _messageController.text.trim();
    final address = enteredAddress.isNotEmpty ? enteredAddress : widget.address;

    if (address.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter recipient and message body'),
        ),
      );
      return;
    }

    setState(() => _isSending = true);
    final success = await SmsChannel.sendSms(address, body);
    if (!mounted) return;
    setState(() => _isSending = false);

    if (success) {
      _messageController.clear();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('SMS sent successfully')));
      await _loadConversation();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to send SMS')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isNew = widget.address.isEmpty;
    final titleText =
        widget.contactName?.trim().isNotEmpty == true
            ? widget.contactName!.trim()
            : (widget.address.isNotEmpty ? widget.address : 'New message');

    return Scaffold(
      appBar: AppBar(
        title:
            isNew
                ? TextField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    hintText: 'Enter phone number or contact',
                    border: InputBorder.none,
                  ),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                )
                : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titleText),
                    if ((widget.contactName?.isNotEmpty ?? false) &&
                        widget.address.isNotEmpty)
                      Text(
                        widget.address,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                  ],
                ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call),
            onPressed: isNew ? null : () {},
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadConversation,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                      itemCount:
                          _messages.isEmpty && widget.initialBody.isNotEmpty
                              ? 1
                              : _messages.length,
                      itemBuilder: (context, index) {
                        if (_messages.isEmpty &&
                            widget.initialBody.isNotEmpty) {
                          return Align(
                            alignment: Alignment.centerLeft,
                            child: _bubble(
                              context,
                              body: widget.initialBody,
                              date: null,
                              isOutgoing: false,
                            ),
                          );
                        }
                        final msg = _messages[index];
                        final isOutgoing = msg.type == 2;
                        final date = DateTime.fromMillisecondsSinceEpoch(
                          msg.date,
                        );
                        return Align(
                          alignment:
                              isOutgoing
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                          child: _bubble(
                            context,
                            body: msg.body,
                            date: date,
                            isOutgoing: isOutgoing,
                          ),
                        );
                      },
                    ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            color: theme.cardColor,
            child: Row(
              children: [
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
                  child:
                      _isSending
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
    );
  }

  Widget _bubble(
    BuildContext context, {
    required String body,
    required DateTime? date,
    required bool isOutgoing,
  }) {
    final theme = Theme.of(context);
    final bubbleColor =
        isOutgoing
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceContainerHighest;
    final dateText =
        date != null ? DateFormat('MMM d, h:mm a').format(date) : '';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.78,
      ),
      decoration: BoxDecoration(
        color: bubbleColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(body),
          if (dateText.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              dateText,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
