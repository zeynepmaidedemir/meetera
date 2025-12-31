import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/ai_chat_state.dart';
import 'ai_screen.dart';

class AiChatListScreen extends StatelessWidget {
  const AiChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final aiState = context.watch<AiChatState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('MeetEra AI'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'New chat',
            onPressed: () {
              aiState.createNewChat();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AiScreen()),
              );
            },
          ),
        ],
      ),
      body: aiState.chats.isEmpty
          ? const Center(child: Text('No chats yet 🤖'))
          : ListView.builder(
              itemCount: aiState.chats.length,
              itemBuilder: (_, i) {
                final chat = aiState.chats[i];

                return ListTile(
                  title: Text(chat.title),
                  leading: const Icon(Icons.chat_bubble_outline),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () {
                      aiState.deleteChat(chat.id);
                    },
                  ),
                  onTap: () {
                    aiState.openChat(chat.id);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AiScreen()),
                    );
                  },
                );
              },
            ),
    );
  }
}
