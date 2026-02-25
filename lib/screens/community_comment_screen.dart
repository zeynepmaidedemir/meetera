import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/community_state.dart';

class CommunityCommentScreen extends StatefulWidget {
  final String cityId;
  final String postId;

  const CommunityCommentScreen({
    super.key,
    required this.cityId,
    required this.postId,
  });

  @override
  State<CommunityCommentScreen> createState() => _CommunityCommentScreenState();
}

class _CommunityCommentScreenState extends State<CommunityCommentScreen> {
  final controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final community = context.read<CommunityState>();

    return Scaffold(
      appBar: AppBar(title: const Text("Comments")),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: community.commentsStream(
                cityId: widget.cityId,
                postId: widget.postId,
              ),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return const Center(child: Text("No comments yet 💬"));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final c = docs[i].data();
                    final author = (c['authorName'] ?? 'User').toString();
                    final text = (c['text'] ?? '').toString();

                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(
                            author.isNotEmpty ? author[0].toUpperCase() : 'U'),
                      ),
                      title: Text(author),
                      subtitle: Text(text),
                    );
                  },
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
                      hintText: "Write a comment…",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () async {
                    final text = controller.text.trim();
                    if (text.isEmpty) return;

                    await community.addComment(
                      cityId: widget.cityId,
                      postId: widget.postId,
                      text: text,
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
