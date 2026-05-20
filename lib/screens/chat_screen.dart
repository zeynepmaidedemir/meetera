import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../state/chat_state.dart';
import '../state/buddy_state.dart';

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
  final ScrollController _scrollController = ScrollController();
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
  void dispose() {
    controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final date = timestamp.toDate();
    return "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
  }

  void _showReportDialog(BuildContext context, BuddyState buddyState) {
    final reasonController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Report User"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: "Reason (e.g. Harassment, Spam)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: "Details",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              final reason = reasonController.text.trim();
              final desc = descController.text.trim();
              if (reason.isEmpty) return;

              await buddyState.report(
                reportedUserId: widget.otherUserId,
                reason: reason,
                description: desc,
                sourceType: 'chat',
              );
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Thank you. Report submitted.")),
                );
              }
            },
            child: const Text("Submit"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatState = context.read<ChatState>();
    final buddyState = context.read<BuddyState>();
    final me = FirebaseAuth.instance.currentUser;

    if (me == null) {
      return const Scaffold(body: Center(child: Text("Not logged in")));
    }

    final conversationId = chatState.buildConversationId(widget.otherUserId);

    return StreamBuilder<bool>(
      stream: buddyState.isBlockedStream(widget.otherUserId),
      initialData: false,
      builder: (context, blockSnapshot) {
        final isBlocked = blockSnapshot.data ?? false;

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.otherUserName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                Text(
                  isBlocked ? "Blocked" : "Active connection",
                  style: TextStyle(
                    fontSize: 11,
                    color: isBlocked ? Colors.redAccent : Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            actions: [
              PopupMenuButton<String>(
                onSelected: (val) async {
                  if (val == 'disconnect') {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text("Disconnect?"),
                        content: Text("Do you want to disconnect from ${widget.otherUserName}?"),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            style: TextButton.styleFrom(foregroundColor: Colors.red),
                            child: const Text("Disconnect"),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await buddyState.removeFriend(widget.otherUserId);
                      if (context.mounted) Navigator.pop(context);
                    }
                  } else if (val == 'block') {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text("Block User?"),
                        content: Text("You will no longer be able to message ${widget.otherUserName}."),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            style: TextButton.styleFrom(foregroundColor: Colors.red),
                            child: const Text("Block"),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await buddyState.block(widget.otherUserId);
                      if (context.mounted) Navigator.pop(context);
                    }
                  } else if (val == 'report') {
                    _showReportDialog(context, buddyState);
                  } else if (val == 'delete_chat') {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text("Clear Conversation?"),
                        content: const Text("All chat messages will be permanently deleted."),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            style: TextButton.styleFrom(foregroundColor: Colors.red),
                            child: const Text("Clear"),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await chatState.deleteChat(conversationId);
                      if (context.mounted) Navigator.pop(context);
                    }
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'disconnect', child: Text("Disconnect")),
                  const PopupMenuItem(value: 'block', child: Text("Block User", style: TextStyle(color: Colors.redAccent))),
                  const PopupMenuItem(value: 'report', child: Text("Report User")),
                  const PopupMenuDivider(),
                  const PopupMenuItem(value: 'delete_chat', child: Text("Clear Chat")),
                ],
              ),
            ],
          ),
          body: !_ready
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    // Messages Area
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: chatState.messagesStream(conversationId),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          final docs = snapshot.data?.docs ?? [];

                          if (docs.isEmpty) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 32),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(18),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF6366F1).withOpacity(0.06),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.bolt, size: 36, color: Color(0xFF6366F1)),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      "Connected with ${widget.otherUserName}!",
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    const SizedBox(height: 6),
                                    const Text(
                                      "Say hello to start the adventure together! 👋",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 13, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          // Trigger auto-scroll on new message
                          WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

                          return ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            itemCount: docs.length,
                            itemBuilder: (_, i) {
                              final data = docs[i].data() as Map<String, dynamic>;
                              final isMe = data['senderId'] == me.uid;
                              final timestamp = data['createdAt'] as Timestamp?;

                              return Align(
                                alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                  constraints: BoxConstraints(
                                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                                  ),
                                  child: Column(
                                    crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        decoration: BoxDecoration(
                                          gradient: isMe
                                              ? const LinearGradient(
                                                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                )
                                              : null,
                                          color: isMe ? null : Theme.of(context).cardColor,
                                          border: isMe ? null : Border.all(color: Colors.grey.withOpacity(0.08)),
                                          borderRadius: BorderRadius.only(
                                            topLeft: const Radius.circular(20),
                                            topRight: const Radius.circular(20),
                                            bottomLeft: Radius.circular(isMe ? 20 : 4),
                                            bottomRight: Radius.circular(isMe ? 4 : 20),
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.02),
                                              blurRadius: 4,
                                              offset: const Offset(0, 1),
                                            )
                                          ],
                                        ),
                                        child: Text(
                                          (data['text'] ?? '').toString(),
                                          style: TextStyle(
                                            color: isMe ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
                                            fontSize: 14.5,
                                            height: 1.3,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 4),
                                        child: Text(
                                          _formatTime(timestamp),
                                          style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),

                    // Block State & Message Input Drawer
                    if (isBlocked)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
                        color: Colors.redAccent.withOpacity(0.05),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.lock_outline_rounded, color: Colors.redAccent, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "This conversation is locked.",
                                style: TextStyle(
                                  color: Colors.redAccent.shade700,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: controller,
                                  style: const TextStyle(fontSize: 14.5),
                                  decoration: InputDecoration(
                                    hintText: "Type a message...",
                                    filled: true,
                                    fillColor: Theme.of(context).cardColor,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(24),
                                      borderSide: BorderSide(color: Colors.grey.withOpacity(0.1)),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(24),
                                      borderSide: BorderSide(color: Colors.grey.withOpacity(0.08)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(24),
                                      borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.2),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                                  onPressed: () async {
                                    final text = controller.text.trim();
                                    if (text.isEmpty) return;

                                    try {
                                      await chatState.sendMessage(
                                        conversationId: conversationId,
                                        otherUserId: widget.otherUserId,
                                        text: text,
                                      );
                                      controller.clear();
                                      _scrollToBottom();
                                    } catch (e) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text(e.toString().replaceAll("Exception: ", ""))),
                                        );
                                      }
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
        );
      },
    );
  }
}
