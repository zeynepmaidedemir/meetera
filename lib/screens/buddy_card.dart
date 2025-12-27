import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/buddy_data.dart';
import '../state/app_state.dart';
import '../state/chat_state.dart';
import 'chat_screen.dart';

class BuddyCard extends StatelessWidget {
  final Buddy buddy;

  const BuddyCard({super.key, required this.buddy});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final chatState = context.read<ChatState>();

    final userInterests = appState.interests;
    final isConnected = appState.isConnected(buddy.id);

    // 🎯 MATCH CALCULATION
    final commonCount = buddy.interests.where(userInterests.contains).length;
    final matchRatio = buddy.interests.isEmpty
        ? 0.0
        : commonCount / buddy.interests.length;
    final matchPercent = (matchRatio * 100).round();

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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 22,
                  child: Text(
                    buddy.name.substring(0, 1),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        buddy.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        buddy.city,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 6),

                      // 🎯 MATCH BAR
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: matchRatio,
                                minHeight: 6,
                                backgroundColor: Colors.grey.withOpacity(0.2),
                                color: matchPercent >= 70
                                    ? Colors.green
                                    : Colors.orange,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$matchPercent%',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // BIO
            Text(buddy.bio),

            const SizedBox(height: 10),

            // INTERESTS
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: buddy.interests
                  .map(
                    (i) => Chip(
                      label: Text(i),
                      visualDensity: VisualDensity.compact,
                    ),
                  )
                  .toList(),
            ),

            const SizedBox(height: 14),

            // ACTIONS
            Row(
              children: [
                // 🤝 CONNECT
                Expanded(
                  child: FilledButton.icon(
                    icon: Icon(isConnected ? Icons.check : Icons.handshake),
                    label: Text(isConnected ? 'Connected' : 'Connect'),
                    onPressed: isConnected
                        ? null
                        : () {
                            context.read<AppState>().connectBuddy(buddy.id);
                          },
                  ),
                ),

                // 💬 MESSAGE (SADECE CONNECTED)
                if (isConnected) ...[
                  const SizedBox(width: 12),
                  IconButton(
                    icon: const Icon(Icons.chat_bubble_outline),
                    tooltip: 'Message',
                    onPressed: () {
                      final threadId = chatState.getOrCreateThread(
                        userId: 'me',
                        buddyId: buddy.id,
                      );

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ChatScreen(buddy: buddy, threadId: threadId),
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
