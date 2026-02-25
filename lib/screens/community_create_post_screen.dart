import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../state/community_state.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final captionController = TextEditingController();
  final hashtagController = TextEditingController();

  File? selectedImage;
  bool posting = false;

  Future<void> pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() {
      selectedImage = File(picked.path);
    });
  }

  List<String> _parseHashtags(String raw) {
    // "erasmus, travel #poland" -> ["erasmus","travel","poland"]
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
    final community = context.read<CommunityState>();

    final cityId = appState.cityId;
    if (cityId == null || cityId.isEmpty) {
      return const Scaffold(body: Center(child: Text("City not selected")));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Post"),
        actions: [
          TextButton(
            onPressed: posting
                ? null
                : () async {
                    final caption = captionController.text.trim();
                    if (caption.isEmpty) return;

                    setState(() => posting = true);

                    await community.createPost(
                      cityId: cityId,
                      text: caption,
                      hashtags: _parseHashtags(hashtagController.text),
                      imageFile: selectedImage,
                    );

                    if (mounted) Navigator.pop(context);
                  },
            child: posting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    "Share",
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Image
          GestureDetector(
            onTap: pickImage,
            child: Container(
              height: 220,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.04),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.black.withOpacity(0.08)),
              ),
              child: selectedImage == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.add_photo_alternate_outlined, size: 42),
                        SizedBox(height: 10),
                        Text(
                          "Add a photo",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.file(
                        selectedImage!,
                        width: double.infinity,
                        height: 220,
                        fit: BoxFit.cover,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 16),

          // Caption
          TextField(
            controller: captionController,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: "Write a caption…",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Hashtags
          TextField(
            controller: hashtagController,
            decoration: InputDecoration(
              hintText: "Hashtags (e.g. #erasmus #krakow #coffee)",
              prefixIcon: const Icon(Icons.tag),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // City chip
          Row(
            children: [
              const Icon(Icons.location_city, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Posting to ${appState.cityLabel}",
                  style: TextStyle(color: Colors.black.withOpacity(0.7)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
