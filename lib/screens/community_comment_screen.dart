import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityCommentScreen extends StatefulWidget {
  final String postId;

  const CommunityCommentScreen({super.key, required this.postId});

  @override
  State<CommunityCommentScreen> createState() => _CommunityCommentScreenState();
}

class _CommunityCommentScreenState extends State<CommunityCommentScreen> {
  final controller = TextEditingController();
  final _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text("Comments")),
      body: Column(
        children: [
          // 🔥 REALTIME COMMENTS
          Expanded(
            child: StreamBuilder(
              stream: _firestore
                  .collection('posts')
                  .doc(widget.postId)
                  .collection('comments')
                  .orderBy('createdAt')
                  .snapshots(),
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
                    final c = docs[i];

                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(c['authorName'][0].toUpperCase()),
                      ),
                      title: Text(c['authorName']),
                      subtitle: Text(c['text']),
                    );
                  },
                );
              },
            ),
          ),

          // ✍️ COMMENT INPUT
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
                    if (controller.text.trim().isEmpty || user == null) return;

                    await _firestore
                        .collection('posts')
                        .doc(widget.postId)
                        .collection('comments')
                        .add({
                          'authorId': user.uid,
                          'authorName': user.displayName ?? "User",
                          'text': controller.text.trim(),
                          'createdAt': FieldValue.serverTimestamp(),
                        });

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
