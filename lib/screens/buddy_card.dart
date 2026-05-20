import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user_model.dart';
import '../state/app_state.dart';
import '../state/buddy_state.dart';
import '../state/chat_state.dart';
import '../services/error_handler.dart';
import 'chat_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class BuddyCard extends StatefulWidget {
  final UserModel buddy;
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
  bool _actionInProgress = false;

  Color _barColor(int percent) {
    if (percent >= 75) return const Color(0xFF10B981); // Emerald Green
    if (percent >= 45) return const Color(0xFFF59E0B); // Amber
    return const Color(0xFFEF4444); // Rose
  }

  @override
  Widget build(BuildContext context) {
    final buddyState = context.watch<BuddyState>();
    final appState = context.watch<AppState>();

    final percent = buddyState.matchPercent(
      myInterests: appState.interests.toList(),
      otherInterests: widget.buddy.interests,
    );

    final status = buddyState.getConnectionStatus(widget.buddy.uid);
    final isReallyConnected = status == ConnectionStatus.connected;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: isReallyConnected
            ? const LinearGradient(
                colors: [
                  Color(0x106366F1), // Very light Indigo
                  Color(0x108B5CF6), // Very light Purple
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        border: Border.all(
          color: isReallyConnected
              ? const Color(0xFF6366F1).withOpacity(0.3)
              : Colors.grey.withOpacity(0.08),
          width: isReallyConnected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Card(
          elevation: 0,
          color: Theme.of(context).cardColor.withOpacity(0.9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isReallyConnected
                              ? const Color(0xFF6366F1)
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 28,
                        backgroundImage: widget.buddy.photoUrl.isNotEmpty
                            ? CachedNetworkImageProvider(widget.buddy.photoUrl)
                            : null,
                        child: widget.buddy.photoUrl.isEmpty
                            ? Text(
                                widget.buddy.displayName.isNotEmpty
                                    ? widget.buddy.displayName[0].toUpperCase()
                                    : 'U',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  widget.buddy.displayName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 17,
                                    letterSpacing: -0.4,
                                  ),
                                ),
                              ),
                              if (isReallyConnected) ...[
                                const SizedBox(width: 6),
                                const Tooltip(
                                  message: "Connected Buddy",
                                  child: Icon(Icons.bolt,
                                      color: Color(0xFF6366F1), size: 20),
                                ),
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
                                    minHeight: 8,
                                    backgroundColor: Colors.grey.withOpacity(0.15),
                                    valueColor: AlwaysStoppedAnimation(
                                      _barColor(percent),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                "$percent% Match",
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
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
                const SizedBox(height: 14),
                if (widget.buddy.bio.trim().isNotEmpty)
                  Text(
                    widget.buddy.bio.trim(),
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.85),
                      height: 1.4,
                    ),
                  ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: widget.buddy.interests.take(5).map((i) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withOpacity(0.06),
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(
                          color: const Color(0xFF6366F1).withOpacity(0.12),
                        ),
                      ),
                      child: Text(
                        i,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6366F1),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                _buildActionButtons(context, status, buddyState),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    ConnectionStatus status,
    BuddyState buddyState,
  ) {
    if (_actionInProgress) {
      return const SizedBox(
        height: 44,
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      );
    }

    switch (status) {
      case ConnectionStatus.none:
        return SizedBox(
          width: double.infinity,
          height: 46,
          child: FilledButton.icon(
            onPressed: () async {
              setState(() => _actionInProgress = true);
              try {
                await buddyState.sendRequest(widget.buddy.uid);
              } catch (e) {
                if (mounted) {
                  UiHelpers.showPremiumSnackBar(
                    context,
                    message: ErrorMapper.getFriendlyMessage(e),
                    isError: true,
                  );
                }
              } finally {
                if (mounted) setState(() => _actionInProgress = false);
              }
            },
            icon: const Icon(Icons.add_rounded, size: 20),
            label: const Text(
              "Connect",
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        );

      case ConnectionStatus.sent:
        return SizedBox(
          width: double.infinity,
          height: 46,
          child: OutlinedButton.icon(
            onPressed: () async {
              setState(() => _actionInProgress = true);
              try {
                await buddyState.cancelRequest(widget.buddy.uid);
              } catch (e) {
                if (mounted) {
                  UiHelpers.showPremiumSnackBar(
                    context,
                    message: ErrorMapper.getFriendlyMessage(e),
                    isError: true,
                  );
                }
              } finally {
                if (mounted) setState(() => _actionInProgress = false);
              }
            },
            icon: const Icon(Icons.close_rounded, size: 20),
            label: const Text(
              "Cancel Request",
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey[700],
              side: BorderSide(color: Colors.grey.shade300),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        );

      case ConnectionStatus.received:
        return Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 46,
                child: OutlinedButton(
                  onPressed: () async {
                    setState(() => _actionInProgress = true);
                    try {
                      await buddyState.declineRequest(widget.buddy.uid);
                    } catch (e) {
                      if (mounted) {
                        UiHelpers.showPremiumSnackBar(
                          context,
                          message: ErrorMapper.getFriendlyMessage(e),
                          isError: true,
                        );
                      }
                    } finally {
                      if (mounted) setState(() => _actionInProgress = false);
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    "Decline",
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SizedBox(
                height: 46,
                child: FilledButton(
                  onPressed: () async {
                    setState(() => _actionInProgress = true);
                    try {
                      await buddyState.acceptRequest(widget.buddy.uid);
                    } catch (e) {
                      if (mounted) {
                        UiHelpers.showPremiumSnackBar(
                          context,
                          message: ErrorMapper.getFriendlyMessage(e),
                          isError: true,
                        );
                      }
                    } finally {
                      if (mounted) setState(() => _actionInProgress = false);
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    "Accept",
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                ),
              ),
            ),
          ],
        );

      case ConnectionStatus.connected:
        return Row(
          children: [
            SizedBox(
              height: 46,
              width: 50,
              child: IconButton(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text("Disconnect?"),
                      content: Text("Are you sure you want to disconnect from ${widget.buddy.displayName}?"),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text("Cancel"),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: TextButton.styleFrom(foregroundColor: Colors.red),
                          child: const Text("Disconnect"),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    setState(() => _actionInProgress = true);
                    try {
                      await buddyState.removeFriend(widget.buddy.uid);
                    } catch (e) {
                      if (mounted) {
                        UiHelpers.showPremiumSnackBar(
                          context,
                          message: ErrorMapper.getFriendlyMessage(e),
                          isError: true,
                        );
                      }
                    } finally {
                      if (mounted) setState(() => _actionInProgress = false);
                    }
                  }
                },
                icon: const Icon(Icons.person_remove_outlined, color: Colors.redAccent),
                style: IconButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Colors.redAccent, width: 1),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SizedBox(
                height: 46,
                child: FilledButton.icon(
                  onPressed: () async {
                    setState(() => _actionInProgress = true);
                    try {
                      final chatState = context.read<ChatState>();
                      await chatState.ensureThread(
                        otherUserId: widget.buddy.uid,
                        otherUserName: widget.buddy.displayName,
                      );
                      if (mounted) {
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
                    } catch (e) {
                      if (mounted) {
                        UiHelpers.showPremiumSnackBar(
                          context,
                          message: ErrorMapper.getFriendlyMessage(e),
                          isError: true,
                        );
                      }
                    } finally {
                      if (mounted) setState(() => _actionInProgress = false);
                    }
                  },
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                  label: const Text(
                    "Message",
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );

      case ConnectionStatus.blocked:
        return SizedBox(
          width: double.infinity,
          height: 46,
          child: OutlinedButton(
            onPressed: () async {
              setState(() => _actionInProgress = true);
              try {
                await buddyState.unblock(widget.buddy.uid);
              } catch (e) {
                if (mounted) {
                  UiHelpers.showPremiumSnackBar(
                    context,
                    message: ErrorMapper.getFriendlyMessage(e),
                    isError: true,
                  );
                }
              } finally {
                if (mounted) setState(() => _actionInProgress = false);
              }
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.blue,
              side: const BorderSide(color: Colors.blue),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              "Unblock",
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
          ),
        );
    }
  }
}
