import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/buddy_user.dart';
import '../state/app_state.dart';
import '../state/buddy_state.dart';
import '../state/chat_state.dart';
import 'chat_screen.dart';

class BuddyCard extends StatefulWidget {
  final BuddyUser buddy;
  final bool isConnected;

  const BuddyCard({
    super.key,
    required this.buddy,
    required this.isConnected,
  });

  @override
  State<BuddyCard> createState() => _BuddyCardState();
}

class _BuddyCardState extends State<BuddyCard> {
  bool _connecting = false;

  Color _barColor(int percent) {
    if (percent >= 75) return Colors.green;
    if (percent >= 45) return Colors.orange;
    return Colors.redAccent;
  }

  @override
  Widget build(BuildContext context) {
    final buddyState = context.watch<BuddyState>();
    final appState = context.watch<AppState>();

    final percent = buddyState.matchPercent(
      myInterests: appState.interests.toList(),
      otherInterests: widget.buddy.interests,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: widget.isConnected
            ? Border.all(color: Colors.green, width: 2)
            : null,
      ),
      child: Card(
        elevation: widget.isConnected ? 6 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: widget.buddy.photoUrl.isNotEmpty
                        ? NetworkImage(widget.buddy.photoUrl)
                        : null,
                    child: widget.buddy.photoUrl.isEmpty
                        ? Text(
                            widget.buddy.displayName.isNotEmpty
                                ? widget.buddy.displayName[0].toUpperCase()
                                : 'U',
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              widget.buddy.displayName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                            if (widget.isConnected) ...[
                              const SizedBox(width: 6),
                              const Icon(Icons.verified,
                                  color: Colors.green, size: 18),
                            ]
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(999),
                                child: LinearProgressIndicator(
                                  value: percent / 100,
                                  minHeight: 9,
                                  backgroundColor: Colors.black12,
                                  valueColor: AlwaysStoppedAnimation(
                                    _barColor(percent),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              "$percent%",
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: _barColor(percent),
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
              if (widget.buddy.bio.trim().isNotEmpty)
                Text(widget.buddy.bio.trim()),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.buddy.interests.take(8).map((i) {
                  return Chip(
                    label: Text(i),
                    visualDensity: VisualDensity.compact,
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _connecting
                      ? null
                      : () async {
                          setState(() => _connecting = true);

                          if (!widget.isConnected) {
                            await buddyState.connect(widget.buddy.uid);
                          }

                          final chatState = context.read<ChatState>();
                          await chatState.ensureThread(
                            otherUserId: widget.buddy.uid,
                            otherUserName: widget.buddy.displayName,
                          );

                          setState(() => _connecting = false);

                          if (context.mounted) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatScreen(
                                  otherUserId: widget.buddy.uid,
                                  otherUserName: widget.buddy.displayName,
                                ),
                              ),
                            );
                          }
                        },
                  child: Text(widget.isConnected ? "Message" : "Connect"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
