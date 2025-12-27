import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/community_state.dart';
import '../data/community_models.dart';

class CommunityCommentScreen extends StatefulWidget {
  final CommunityPost post;

  const CommunityCommentScreen({super.key, required this.post});

  @override
  State<CommunityCommentScreen> createState() => _CommunityCommentScreenState();
}

class _CommunityCommentScreenState extends State<CommunityCommentScreen> {
  final controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final community = context.watch<CommunityState>();
    final comments = community.commentsForPost(widget.post.id);

    return Scaffold(
      appBar: AppBar(title: const Text('Comments')),
      body: Column(
        children: [
          Expanded(
            child: comments.isEmpty
                ? const Center(child: Text('No comments yet 💬'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: comments.length,
                    itemBuilder: (_, i) {
                      final c = comments[i];
                      return ListTile(
                        leading: CircleAvatar(child: Text(c.authorName[0])),
                        title: Text(c.authorName),
                        subtitle: Text(c.text),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      hintText: 'Write a comment…',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {
                    if (controller.text.trim().isEmpty) return;

                    community.addComment(
                      postId: widget.post.id,
                      authorId: 'me',
                      authorName: 'You',
                      text: controller.text.trim(),
                    );

                    controller.clear();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
