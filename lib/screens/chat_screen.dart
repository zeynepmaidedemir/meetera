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
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final chatState = context.read<ChatState>();
      await chatState.ensureThread(
        otherUserId: widget.otherUserId,
        otherUserName: widget.otherUserName,
      );
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatState = context.read<ChatState>();
    final me = FirebaseAuth.instance.currentUser;

    if (me == null) {
      return const Scaffold(body: Center(child: Text("Not logged in")));
    }

    final conversationId = chatState.buildConversationId(widget.otherUserId);

    return Scaffold(
      appBar: AppBar(title: Text(widget.otherUserName)),
      body: !_ready
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: StreamBuilder(
                    stream: chatState.messagesStream(conversationId),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final docs = snapshot.data!.docs;

                      if (docs.isEmpty) {
                        return const Center(
                          child: Text("Say hi 👋\nStart the conversation!"),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: docs.length,
                        itemBuilder: (_, i) {
                          final data = docs[i].data() as Map<String, dynamic>;
                          final isMe = data['senderId'] == me.uid;

                          return Align(
                            alignment: isMe
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isMe
                                    ? Colors.blueAccent
                                    : Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                (data['text'] ?? '').toString(),
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
                          decoration: const InputDecoration(
                            hintText: "Message…",
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: () async {
                          final text = controller.text.trim();
                          if (text.isEmpty) return;

                          await chatState.sendMessage(
                            conversationId: conversationId,
                            otherUserId: widget.otherUserId,
                            text: text,
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
