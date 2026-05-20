import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/ai_chat_state.dart';
import 'ai_screen.dart';

class AiChatListScreen extends StatefulWidget {
  const AiChatListScreen({super.key});

  @override
  State<AiChatListScreen> createState() => _AiChatListScreenState();
}

class _AiChatListScreenState extends State<AiChatListScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _isCreating = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
    } else if (difference.inDays == 1) {
      return "Yesterday";
    } else if (difference.inDays < 7) {
      final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return weekdays[dateTime.weekday - 1];
    } else {
      return "${dateTime.day} ${_getMonthName(dateTime.month)}";
    }
  }

  String _getMonthName(int month) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  Future<void> _handleCreateChat(AiChatState aiState) async {
    if (_isCreating) return;
    setState(() => _isCreating = true);

    try {
      await aiState.createNewChat();
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AiScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create new chat: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  void _showRenameDialog(BuildContext context, AiChatState aiState, AiChat chat) {
    final controller = TextEditingController(text: chat.title);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Rename Chat',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Enter new title...',
              filled: true,
              fillColor: Theme.of(context).cardColor,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            FilledButton(
              onPressed: () async {
                final newTitle = controller.text.trim();
                if (newTitle.isNotEmpty) {
                  await aiState.renameChat(chat.id, newTitle);
                }
                if (mounted) Navigator.pop(context);
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Rename'),
            ),
          ],
        );
      },
    );
  }

  Future<bool?> _showDeleteConfirmation(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Delete Chat',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
          ),
          content: const Text('Are you sure you want to delete this conversation? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final aiState = context.watch<AiChatState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'MeetEra AI',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22, letterSpacing: -0.5),
        ),
        centerTitle: false,
        elevation: 0,
        actions: [
          if (_isCreating)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF6366F1)),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.add_rounded, size: 28, color: Color(0xFF6366F1)),
              tooltip: 'New AI chat',
              onPressed: () => _handleCreateChat(aiState),
            ),
        ],
      ),
      body: Column(
        children: [
          // 🔎 Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.trim().toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: "Search AI conversations...",
                prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey, size: 22),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, color: Colors.grey, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: Theme.of(context).cardColor.withOpacity(0.8),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.withOpacity(0.1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
                ),
              ),
            ),
          ),

          // 💬 AI Chats Stream List
          Expanded(
            child: StreamBuilder<List<AiChat>>(
              stream: aiState.myChatsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final chats = snapshot.data ?? [];
                if (chats.isEmpty) {
                  return _buildEmptyState(context);
                }

                final filteredChats = chats.where((c) {
                  return c.title.toLowerCase().contains(_searchQuery);
                }).toList();

                if (filteredChats.isEmpty) {
                  return _buildEmptyState(context, isSearch: true);
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: filteredChats.length,
                  itemBuilder: (context, i) {
                    final chat = filteredChats[i];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Theme.of(context).cardColor,
                        border: Border.all(color: Colors.grey.withOpacity(0.06)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.01),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Dismissible(
                          key: Key('ai_chat_${chat.id}'),
                          direction: DismissDirection.endToStart,
                          confirmDismiss: (direction) => _showDeleteConfirmation(context),
                          onDismissed: (direction) async {
                            await aiState.deleteChat(chat.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Chat deleted successfully')),
                              );
                            }
                          },
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            color: Colors.redAccent.withOpacity(0.9),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                                SizedBox(width: 8),
                                Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 24),
                              ],
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6366F1).withOpacity(0.08),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.auto_awesome_rounded,
                                color: Color(0xFF6366F1),
                                size: 22,
                              ),
                            ),
                            title: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    chat.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                      letterSpacing: -0.3,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _formatDateTime(chat.updatedAt),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade500,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            subtitle: const Padding(
                              padding: EdgeInsets.only(top: 4.0),
                              child: Text(
                                'Tap to talk to your Erasmus guide 🤖',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                            trailing: PopupMenuButton<String>(
                              icon: Icon(Icons.more_vert_rounded, color: Colors.grey.shade600, size: 22),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              onSelected: (val) async {
                                if (val == 'rename') {
                                  _showRenameDialog(context, aiState, chat);
                                } else if (val == 'delete') {
                                  final confirmed = await _showDeleteConfirmation(context);
                                  if (confirmed == true) {
                                    await aiState.deleteChat(chat.id);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Chat deleted successfully')),
                                      );
                                    }
                                  }
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'rename',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit_rounded, size: 18),
                                      SizedBox(width: 8),
                                      Text('Rename'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete_rounded, size: 18, color: Colors.redAccent.shade200),
                                      const SizedBox(width: 8),
                                      Text('Delete', style: TextStyle(color: Colors.redAccent.shade200)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            onTap: () {
                              aiState.openChat(chat.id);
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const AiScreen()),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, {bool isSearch = false}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withOpacity(0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSearch ? Icons.search_off_rounded : Icons.psychology_outlined,
                size: 52,
                color: const Color(0xFF6366F1),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isSearch ? "No matches found" : "Your AI Guide is ready!",
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, letterSpacing: -0.4),
            ),
            const SizedBox(height: 8),
            Text(
              isSearch
                  ? "Try searching for a different conversation title."
                  : "Start a conversation to plan your packing lists, find the best student housing, prepare budgets, or discover top locations!",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                height: 1.4,
              ),
            ),
            if (!isSearch) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => _handleCreateChat(context.read<AiChatState>()),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Start Planning Now'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

