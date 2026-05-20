import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../state/chat_state.dart';
import 'chat_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      // Today, return hours and minutes
      return "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
    } else if (difference.inDays == 1) {
      return "Yesterday";
    } else if (difference.inDays < 7) {
      // Days of the week
      final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return weekdays[dateTime.weekday - 1];
    } else {
      return "${dateTime.day} ${_getMonthName(dateTime.month)}";
    }
  }

  String _getMonthName(int month) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final me = FirebaseAuth.instance.currentUser;

    if (me == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            "Please log in to view chats.",
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      );
    }

    final chatState = context.watch<ChatState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Messages",
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22, letterSpacing: -0.5),
        ),
        centerTitle: false,
        elevation: 0,
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
                hintText: "Search conversations...",
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

          // 💬 Threads List
          Expanded(
            child: StreamBuilder<List<ChatThreadModel>>(
              stream: chatState.myThreadsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final threads = snapshot.data ?? [];
                if (threads.isEmpty) {
                  return _buildEmptyState(context);
                }

                return StreamBuilder<QuerySnapshot>(
                  // Dinamik arama yapmak için tüm kullanıcı adlarını çözmemiz gerekiyor.
                  // Arama yaparken, eğer arama sorgusu varsa her thread için user bilgilerini çekip filtereliyoruz.
                  stream: FirebaseFirestore.instance.collection('users').snapshots(),
                  builder: (context, usersSnap) {
                    if (!usersSnap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final usersMap = {
                      for (var doc in usersSnap.data!.docs)
                        doc.id: doc.data() as Map<String, dynamic>
                    };

                    final filteredThreads = threads.where((t) {
                      final otherId = t.participants.firstWhere((id) => id != me.uid, orElse: () => '');
                      if (otherId.isEmpty) return false;

                      final userData = usersMap[otherId] ?? {};
                      final name = (userData['displayName'] ?? userData['email'] ?? '').toString().toLowerCase();
                      final lastMsg = t.lastMessage.toLowerCase();

                      return name.contains(_searchQuery) || lastMsg.contains(_searchQuery);
                    }).toList();

                    if (filteredThreads.isEmpty) {
                      return _buildEmptyState(context, isSearch: _searchQuery.isNotEmpty);
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: filteredThreads.length,
                      itemBuilder: (context, i) {
                        final t = filteredThreads[i];
                        final otherId = t.participants.firstWhere((id) => id != me.uid);
                        final userData = usersMap[otherId] ?? {};
                        final name = (userData['displayName'] ?? userData['email'] ?? 'User $otherId').toString();
                        final photoUrl = (userData['photoUrl'] ?? '').toString();
                        final isOnline = (userData['isOnline'] ?? false) as bool;

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
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              leading: Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 26,
                                    backgroundImage: photoUrl.isNotEmpty
                                        ? CachedNetworkImageProvider(photoUrl)
                                        : null,
                                    child: photoUrl.isEmpty
                                        ? Text(
                                            name.isNotEmpty ? name[0].toUpperCase() : 'U',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                          )
                                        : null,
                                  ),
                                  if (isOnline)
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        width: 14,
                                        height: 14,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF10B981), // Emerald Green
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Theme.of(context).scaffoldBackgroundColor,
                                            width: 2.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              title: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    _formatDateTime(t.updatedAt),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade500,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  t.lastMessage.isEmpty ? 'Say hi 👋' : t.lastMessage,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: t.lastMessage.isEmpty
                                        ? Colors.grey.shade400
                                        : Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.65),
                                  ),
                                ),
                              ),
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
                            ),
                          ),
                        );
                      },
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
                isSearch ? Icons.search_off_rounded : Icons.chat_bubble_outline_rounded,
                size: 52,
                color: const Color(0xFF6366F1),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isSearch ? "No matches found" : "No chats yet",
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, letterSpacing: -0.4),
            ),
            const SizedBox(height: 8),
            Text(
              isSearch
                  ? "Try looking for another username or search term."
                  : "Connect with awesome buddies in the community to start conversations and plan your journeys!",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
