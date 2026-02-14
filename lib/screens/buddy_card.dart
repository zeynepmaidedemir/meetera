import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/buddy_state.dart';
import '../state/app_state.dart';
import 'chat_screen.dart';
import '../models/buddy_user.dart';

class BuddyCard extends StatelessWidget {
  final BuddyUser buddy;

  const BuddyCard({super.key, required this.buddy});

  @override
  Widget build(BuildContext context) {
    final buddyState = context.watch<BuddyState>();
    final appState = context.watch<AppState>();

    final myInterests = appState.interests.toList();

    final match = buddyState.matchPercent(
      myInterests: myInterests,
      otherInterests: buddy.interests,
    );

    final isConnected = buddyState.isConnected(buddy.uid);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: buddy.photoUrl.isNotEmpty
                      ? NetworkImage(buddy.photoUrl)
                      : null,
                  child: buddy.photoUrl.isEmpty
                      ? Text(buddy.displayName[0].toUpperCase())
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        buddy.displayName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text("$match% match"),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Text(buddy.bio),

            const SizedBox(height: 10),

            Wrap(
              spacing: 6,
              children:
                  buddy.interests.map((i) => Chip(label: Text(i))).toList(),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: isConnected
                        ? null
                        : () => buddyState.connect(buddy.uid),
                    child: Text(isConnected ? "Connected" : "Connect"),
                  ),
                ),
                if (isConnected) ...[
                  const SizedBox(width: 12),
                  IconButton(
                    icon: const Icon(Icons.chat_bubble_outline),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            otherUserId: buddy.uid,
                            otherUserName: buddy.displayName,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
