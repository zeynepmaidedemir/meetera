import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../state/chat_state.dart';

class ChatScreen extends StatefulWidget {
  final String otherUserId;
  final String otherUserName;

  const ChatScreen({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final chatState = context.read<ChatState>();
    final conversationId = chatState.buildConversationId(widget.otherUserId);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.otherUserName),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: chatState.messagesStream(conversationId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;
                final currentUser = FirebaseAuth.instance.currentUser;

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final data = docs[i].data() as Map<String, dynamic>;

                    final isMe = data['senderId'] == currentUser!.uid;

                    return Align(
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blue : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          data['text'] ?? '',
                          style: TextStyle(
                            color: isMe ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: const InputDecoration(hintText: "Message..."),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {
                    if (controller.text.trim().isEmpty) return;

                    chatState.sendMessage(
                      conversationId: conversationId,
                      text: controller.text.trim(),
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
