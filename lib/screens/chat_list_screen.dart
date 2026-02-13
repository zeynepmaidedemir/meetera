import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/chat_state.dart';
import '../state/app_state.dart';
import '../data/buddy_data.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final chatState = context.watch<ChatState>();
    final appState = context.watch<AppState>();

    // Sadece connected buddy'ler
    final connectedBuddies = mockBuddies
        .where((b) => appState.isConnected(b.id))
        .toList();

    if (connectedBuddies.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chats')),
        body: const Center(
          child: Text(
            'No chats yet 💬\nConnect with buddies to start chatting',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Chats')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: connectedBuddies.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          final buddy = connectedBuddies[i];

          final threadId = chatState.getOrCreateThread(
            userId: 'me',
            buddyId: buddy.id,
          );

          final messages = chatState.messagesFor(threadId);
          final lastMessage = messages.isNotEmpty
              ? messages.last.text
              : 'Say hi 👋';

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            tileColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            leading: CircleAvatar(
              child: Text(
                buddy.name.substring(0, 1),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(buddy.name),
            subtitle: Text(
              lastMessage,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatScreen(buddy: buddy, threadId: threadId),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
