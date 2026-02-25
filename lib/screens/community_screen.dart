import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../state/app_state.dart';
import '../state/community_state.dart';
import 'community_create_post_screen.dart';
import 'community_comment_screen.dart';
import 'community_edit_post_screen.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  bool _listening = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_listening) return;

    final cityId = context.read<AppState>().cityId;
    if (cityId != null && cityId.isNotEmpty) {
      context.read<CommunityState>().listenPosts(cityId);
      _listening = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final state = context.watch<CommunityState>();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final cityId = appState.cityId;

    if (cityId == null || cityId.isEmpty) {
      return const Scaffold(body: Center(child: Text("City not selected")));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Community • ${appState.city ?? ''}"),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'community_create',
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreatePostScreen()),
          );
        },
      ),
      body: state.posts.isEmpty
          ? const Center(child: Text("No posts yet 👀\nBe the first one!"))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: state.posts.length,
              itemBuilder: (_, i) {
                final doc = state.posts[i];
                final data = doc.data();

                final likedBy = List<String>.from(data['likedBy'] ?? []);
                final isLiked = uid != null && likedBy.contains(uid);
                final isMine = uid != null && data['authorId'] == uid;

                final hashtags = List<String>.from(data['hashtags'] ?? []);

                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  margin: const EdgeInsets.only(bottom: 14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CommunityCommentScreen(
                            cityId: cityId,
                            postId: doc.id,
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Row(
                            children: [
                              CircleAvatar(
                                child: Text(
                                  (data['authorName'] ?? 'U')
                                      .toString()
                                      .substring(0, 1)
                                      .toUpperCase(),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  (data['authorName'] ?? 'User').toString(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              if (isMine)
                                PopupMenuButton<String>(
                                  onSelected: (v) async {
                                    if (v == 'edit') {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => EditPostScreen(
                                            postId: doc.id,
                                            initialText:
                                                (data['text'] ?? '').toString(),
                                            initialHashtags: hashtags,
                                          ),
                                        ),
                                      );
                                    }
                                    if (v == 'delete') {
                                      await state.deletePost(
                                        cityId: cityId,
                                        postId: doc.id,
                                      );
                                    }
                                  },
                                  itemBuilder: (_) => const [
                                    PopupMenuItem(
                                      value: 'edit',
                                      child: Text('Edit'),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Text('Delete'),
                                    ),
                                  ],
                                ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          Text(
                            (data['text'] ?? '').toString(),
                            style: const TextStyle(fontSize: 15, height: 1.35),
                          ),

                          if (hashtags.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: hashtags.take(12).map((h) {
                                return Text(
                                  '#$h',
                                  style: TextStyle(
                                    color: Colors.blue.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                );
                              }).toList(),
                            ),
                          ],

                          if ((data['imageUrl'] ?? '')
                              .toString()
                              .isNotEmpty) ...[
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.network(
                                data['imageUrl'],
                                height: 180,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ],

                          const SizedBox(height: 10),

                          Row(
                            children: [
                              IconButton(
                                icon: Icon(
                                  isLiked
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color:
                                      isLiked ? Colors.red : Colors.grey[700],
                                ),
                                onPressed: () => state.toggleLike(
                                  cityId: cityId,
                                  postId: doc.id,
                                ),
                              ),
                              Text("${likedBy.length}"),
                              const SizedBox(width: 12),
                              const Icon(Icons.chat_bubble_outline, size: 18),
                              const Spacer(),
                              Icon(
                                Icons.location_city,
                                size: 18,
                                color: Colors.black.withOpacity(0.5),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                appState.city ?? '',
                                style: TextStyle(
                                  color: Colors.black.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
