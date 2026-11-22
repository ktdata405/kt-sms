import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/native/sms_channel.dart';

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

  @override
  void initState() {
    super.initState();
    _addressController = TextEditingController(text: widget.address);
    _messageController = TextEditingController();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _messageController.dispose();
    super.dispose();
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
                  hintText: 'Enter phone number or contact',
                  border: InputBorder.none,
                ),
                style: const TextStyle(fontWeight: FontWeight.bold),
              )
            : Text(widget.address),
        actions: [
          IconButton(
            icon: const Icon(Icons.call),
            onPressed: widget.address.isEmpty ? null : () {
              // Call action
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (!isNew && widget.initialBody.isNotEmpty) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(widget.initialBody),
                    ),
                  ),
                ],
                if (isNew)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text('Compose a new message below.'),
                    ),
                  ),
              ],
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
    );
  }
}
