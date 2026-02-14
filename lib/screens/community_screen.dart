import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../state/community_state.dart';
import 'community_comment_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final cityId = context.read<AppState>().cityId;
    if (cityId != null) {
      context.read<CommunityState>().loadPosts(cityId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CommunityState>();
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (state.posts.isEmpty) {
      return const Scaffold(body: Center(child: Text("No posts yet 👀")));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Community")),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: state.posts.length,
        itemBuilder: (_, i) {
          final post = state.posts[i];
          final likedBy = List<String>.from(post['likedBy'] ?? []);
          final isLiked = likedBy.contains(uid);

          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            margin: const EdgeInsets.only(bottom: 14),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CommunityCommentScreen(postId: post.id),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // HEADER
                    Row(
                      children: [
                        CircleAvatar(
                          child: Text(post['authorName'][0].toUpperCase()),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            post['authorName'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // TEXT
                    Text(post['text'], style: const TextStyle(fontSize: 15)),

                    const SizedBox(height: 14),

                    // ACTIONS
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            isLiked ? Icons.favorite : Icons.favorite_border,
                            color: isLiked ? Colors.red : Colors.grey,
                          ),
                          onPressed: () => state.toggleLike(post.id),
                        ),
                        Text("${likedBy.length}"),
                        const Spacer(),
                        const Icon(Icons.chat_bubble_outline, size: 18),
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
