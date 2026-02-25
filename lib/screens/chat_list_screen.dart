import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../state/chat_state.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final me = FirebaseAuth.instance.currentUser;

    if (me == null) {
      return const Scaffold(body: Center(child: Text("Not logged in")));
    }

    final chatState = context.watch<ChatState>();

    return Scaffold(
      appBar: AppBar(title: const Text("Chats")),
      body: StreamBuilder<List<ChatThreadModel>>(
        stream: chatState.myThreadsStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final threads = snapshot.data!;
          if (threads.isEmpty) {
            return const Center(
              child: Text(
                "No chats yet 💬\nConnect with buddies to start chatting",
                textAlign: TextAlign.center,
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: threads.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final t = threads[i];
              final otherId = t.participants.firstWhere((id) => id != me.uid);

              return FutureBuilder(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(otherId)
                    .get(),
                builder: (context, userSnap) {
                  if (!userSnap.hasData) return const SizedBox();

                  final userData =
                      userSnap.data!.data() as Map<String, dynamic>? ?? {};

                  final name =
                      (userData['displayName'] ?? userData['email'] ?? 'User')
                          .toString();
                  final photoUrl = (userData['photoUrl'] ?? '').toString();

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage:
                          photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                      child: photoUrl.isEmpty
                          ? Text(name.isNotEmpty ? name[0].toUpperCase() : 'U')
                          : null,
                    ),
                    title: Text(name),
                    subtitle: Text(
                      t.lastMessage.isEmpty ? 'Say hi 👋' : t.lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            otherUserId: otherId,
                            otherUserName: name,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
