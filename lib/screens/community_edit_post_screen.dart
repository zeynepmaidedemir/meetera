import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../state/community_state.dart';

class EditPostScreen extends StatefulWidget {
  final String postId;
  final String initialText;
  final List<String> initialHashtags;

  const EditPostScreen({
    super.key,
    required this.postId,
    required this.initialText,
    required this.initialHashtags,
  });

  @override
  State<EditPostScreen> createState() => _EditPostScreenState();
}

class _EditPostScreenState extends State<EditPostScreen> {
  late final TextEditingController captionController;
  late final TextEditingController hashtagController;

  @override
  void initState() {
    super.initState();
    captionController = TextEditingController(text: widget.initialText);
    hashtagController = TextEditingController(
      text: widget.initialHashtags.map((h) => '#$h').join(' '),
    );
  }

  List<String> _parseHashtags(String raw) {
    return raw
        .replaceAll('#', ' ')
        .split(RegExp(r'[\s,]+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .map((e) => e.toLowerCase())
        .toSet()
        .toList();
  }

  @override
  void dispose() {
    captionController.dispose();
    hashtagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final cityId = appState.cityId ?? '';
    final community = context.read<CommunityState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Post"),
        actions: [
          TextButton(
            onPressed: () async {
              final text = captionController.text.trim();
              if (text.isEmpty) return;

              await community.updatePost(
                cityId: cityId,
                postId: widget.postId,
                text: text,
                hashtags: _parseHashtags(hashtagController.text),
              );

              if (mounted) Navigator.pop(context);
            },
            child: const Text("Save"),
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: captionController,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: "Caption…",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: hashtagController,
            decoration: const InputDecoration(
              hintText: "Hashtags…",
              prefixIcon: Icon(Icons.tag),
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }
}
