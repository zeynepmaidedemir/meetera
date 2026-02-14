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
  final controller = TextEditingController();
  File? selectedImage;

  Future<void> pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        selectedImage = File(picked.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final communityState = context.read<CommunityState>();

    return Scaffold(
      appBar: AppBar(title: const Text("Create Post")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: controller,
              maxLines: 4,
              decoration: const InputDecoration(hintText: "What's happening?"),
            ),
            const SizedBox(height: 12),
            if (selectedImage != null) Image.file(selectedImage!, height: 160),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(icon: const Icon(Icons.image), onPressed: pickImage),
                const Spacer(),
                ElevatedButton(
                  child: const Text("Post"),
                  onPressed: () async {
                    if (controller.text.trim().isEmpty) return;

                    await communityState.createPost(
                      cityId: appState.cityId!,
                      text: controller.text.trim(),
                      imageFile: selectedImage,
                    );

                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
