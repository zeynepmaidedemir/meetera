import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../state/community_state.dart';
import 'community_comment_screen.dart';

const mockImages = [
  'https://images.unsplash.com/photo-1504674900247-0877df9cc836',
  'https://images.unsplash.com/photo-1528605248644-14dd04022da1',
  'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee',
  'https://images.unsplash.com/photo-1501785888041-af3ef285b470',
];

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final city = context.watch<AppState>().cityLabel.split(',').first;
    final community = context.watch<CommunityState>();
    final posts = community.postsForCity(city);

    return Scaffold(
      appBar: AppBar(title: Text('$city Community')),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (_) => const _CreatePostSheet(),
          );
        },
      ),
      body: posts.isEmpty
          ? const Center(
              child: Text(
                'No posts yet 👀\nBe the first to ask something!',
                textAlign: TextAlign.center,
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: posts.length,
              itemBuilder: (_, i) {
                final p = posts[i];
                final liked = p.likedBy.contains('me');

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // HEADER
                        Row(
                          children: [
                            CircleAvatar(child: Text(p.authorName[0])),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                p.authorName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (p.authorId == 'me')
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () {
                                  community.deletePost(p.id, 'me');
                                },
                              ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // IMAGE
                        if (p.imageUrl != null) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              p.imageUrl!,
                              height: 180,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],

                        // TEXT
                        Text(p.text),

                        const SizedBox(height: 12),

                        // ACTIONS
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                liked ? Icons.favorite : Icons.favorite_border,
                                color: liked ? Colors.red : null,
                              ),
                              onPressed: () {
                                community.toggleLike(p.id, 'me');
                              },
                            ),
                            Text('${p.likedBy.length}'),
                            const SizedBox(width: 16),
                            InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        CommunityCommentScreen(post: p),
                                  ),
                                );
                              },
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.chat_bubble_outline,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 4),
                                  Text('${p.commentCount}'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// =====================
// CREATE POST SHEET
// =====================
class _CreatePostSheet extends StatefulWidget {
  const _CreatePostSheet();

  @override
  State<_CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State<_CreatePostSheet> {
  final controller = TextEditingController();
  String? selectedImage;

  @override
  Widget build(BuildContext context) {
    final city = context.read<AppState>().cityLabel.split(',').first;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Create Post',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Ask something to your city community…',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),

          // MOCK IMAGE PICKER
          SizedBox(
            height: 90,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: mockImages.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final url = mockImages[i];
                final selected = selectedImage == url;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedImage = selected ? null : url;
                    });
                  },
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          url,
                          width: 120,
                          height: 90,
                          fit: BoxFit.cover,
                        ),
                      ),
                      if (selected)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.check_circle,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                if (controller.text.trim().isEmpty) return;

                context.read<CommunityState>().createPost(
                  city: city,
                  authorId: 'me',
                  authorName: 'You',
                  text: controller.text.trim(),
                  imageUrl: selectedImage,
                );

                Navigator.pop(context);
              },
              child: const Text('Post'),
            ),
          ),
        ],
      ),
    );
  }
}
