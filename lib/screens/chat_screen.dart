import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/chat_models.dart';
import '../state/chat_state.dart';
import '../data/buddy_data.dart';

class ChatScreen extends StatefulWidget {
  final Buddy buddy;
  final String threadId;

  const ChatScreen({super.key, required this.buddy, required this.threadId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final chatState = context.watch<ChatState>();
    final messages = chatState.messagesFor(widget.threadId);

    return Scaffold(
      appBar: AppBar(title: Text(widget.buddy.name)),
      body: Column(
        children: [
          // 📨 MESSAGE LIST
          Expanded(
            child: messages.isEmpty
                ? const Center(child: Text('No messages yet'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (_, i) {
                      final m = messages[i];
                      return Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(m.text),
                        ),
                      );
                    },
                  ),
          ),

          // ✏️ INPUT
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      hintText: 'Message…',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {
                    if (controller.text.trim().isEmpty) return;

                    chatState.sendMessage(
                      threadId: widget.threadId,
                      message: ChatMessage(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        senderId: 'me',
                        text: controller.text.trim(),
                        createdAt: DateTime.now(),
                      ),
                    );

                    controller.clear();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
