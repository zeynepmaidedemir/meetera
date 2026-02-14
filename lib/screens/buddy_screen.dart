import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/buddy_state.dart';
import '../state/app_state.dart';
import '../state/chat_state.dart';
import '../models/buddy_user.dart';
import 'chat_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BuddyScreen extends StatefulWidget {
  const BuddyScreen({super.key});

  @override
  State<BuddyScreen> createState() => _BuddyScreenState();
}

class _BuddyScreenState extends State<BuddyScreen> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final cityId = context.read<AppState>().cityId;
    if (cityId != null) {
      context.read<BuddyState>().loadUsersByCity(cityId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final buddyState = context.watch<BuddyState>();
    final appState = context.watch<AppState>();
    final chatState = context.read<ChatState>();
    final currentUser = FirebaseAuth.instance.currentUser;

    final myInterests = appState.interests.toList();

    final users = buddyState.users;

    return Scaffold(
      appBar: AppBar(title: const Text("Buddies")),
      body: users.isEmpty
          ? const Center(child: Text("No users in this city yet 👀"))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: users.length,
              itemBuilder: (_, i) {
                final user = users[i];

                final match = buddyState.matchPercent(
                  myInterests: myInterests,
                  otherInterests: user.interests,
                );

                final percent = (match * 100).round();
                final isConnected = buddyState.isConnected(user.uid);

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundImage: user.photoUrl.isNotEmpty
                                  ? NetworkImage(user.photoUrl)
                                  : null,
                              child: user.photoUrl.isEmpty
                                  ? Text(user.displayName[0].toUpperCase())
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(user.displayName,
                                  style:
                                      Theme.of(context).textTheme.titleMedium),
                            ),
                            Text("$percent%"),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(user.bio),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton(
                                onPressed: isConnected
                                    ? null
                                    : () => buddyState.connect(user.uid),
                                child:
                                    Text(isConnected ? "Connected" : "Connect"),
                              ),
                            ),
                            if (isConnected) ...[
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.chat),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ChatScreen(
                                        otherUserId: user.uid,
                                        otherUserName: user.displayName,
                                      ),
                                    ),
                                  );

                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ChatScreen(
                                        otherUserId: user.uid,
                                        otherUserName: user.displayName,
                                      ),
                                    ),
                                  );
                                },
                              )
                            ]
                          ],
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
