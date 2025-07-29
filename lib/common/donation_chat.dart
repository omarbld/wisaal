
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DonationChatScreen extends StatefulWidget {
  final String donationId;
  const DonationChatScreen({super.key, required this.donationId});

  @override
  State<DonationChatScreen> createState() => _DonationChatScreenState();
}

class _DonationChatScreenState extends State<DonationChatScreen> {
  late final Stream<List<Map<String, dynamic>>> _messagesStream;
  final TextEditingController _messageController = TextEditingController();
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _messagesStream = supabase
        .from('chat_messages')
        .stream(primaryKey: ['id'])
        .eq('donation_id', widget.donationId)
        .order('created_at');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المحادثة'),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _messagesStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('خطأ: ${snapshot.error}'));
                }
                final messages = snapshot.data!;
                return ListView.builder(
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMine = message['sender_id'] == supabase.auth.currentUser!.id;
                    return Align(
                      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
                      child: Card(
                        color: isMine ? Theme.of(context).colorScheme.primaryContainer : null,
                        margin: const EdgeInsets.all(8.0),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Text(message['content']),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'اكتب رسالتك...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isNotEmpty) {
      await supabase.from('chat_messages').insert({
        'donation_id': widget.donationId,
        'sender_id': supabase.auth.currentUser!.id,
        'content': content,
      });
      _messageController.clear();
    }
  }
}
