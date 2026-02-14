import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../state/buddy_state.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final buddyState = context.watch<BuddyState>();
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text("Not logged in")));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Chats")),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('connections')
            .where('participants', arrayContains: currentUser.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final connections = snapshot.data!.docs;

          if (connections.isEmpty) {
            return const Center(
              child: Text(
                "No chats yet 💬\nConnect with buddies to start chatting",
                textAlign: TextAlign.center,
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: connections.length,
            itemBuilder: (_, i) {
              final data = connections[i].data();
              final participants = List<String>.from(data['participants']);

              final otherUserId = participants.firstWhere(
                (id) => id != currentUser.uid,
              );

              return FutureBuilder(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(otherUserId)
                    .get(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) {
                    return const SizedBox();
                  }

                  final userData =
                      userSnapshot.data!.data() as Map<String, dynamic>;

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage:
                          userData['photoUrl'] != null &&
                              userData['photoUrl'].isNotEmpty
                          ? NetworkImage(userData['photoUrl'])
                          : null,
                      child:
                          userData['photoUrl'] == null ||
                              userData['photoUrl'].isEmpty
                          ? Text(userData['displayName'][0].toUpperCase())
                          : null,
                    ),
                    title: Text(userData['displayName'] ?? "User"),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            otherUserId: otherUserId,
                            otherUserName: userData['displayName'] ?? "User",
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
