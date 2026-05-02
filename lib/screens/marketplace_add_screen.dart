import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

import '../state/app_state.dart';
import '../state/marketplace_state.dart';

class MarketplaceAddScreen extends StatefulWidget {
  const MarketplaceAddScreen({super.key});

  @override
  State<MarketplaceAddScreen> createState() => _MarketplaceAddScreenState();
}

class _MarketplaceAddScreenState extends State<MarketplaceAddScreen> {
  final titleController = TextEditingController();
  final descController = TextEditingController();
  final priceController = TextEditingController();

  File? selectedImage;
  bool isPosting = false;

  Future<void> pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        selectedImage = File(picked.path);
      });
    }
  }

  Future<void> submit() async {
    final user = FirebaseAuth.instance.currentUser;
    final appState = context.read<AppState>();
    
    if (user == null || appState.cityLabel == null) return;
    
    final title = titleController.text.trim();
    if (title.isEmpty) return;

    setState(() => isPosting = true);

    try {
      final itemId = const Uuid().v4();
      List<String> imageUrls = [];

      if (selectedImage != null) {
        final ref = FirebaseStorage.instance.ref().child('marketplace_images/\$itemId.jpg');
        await ref.putFile(selectedImage!);
        final url = await ref.getDownloadURL();
        imageUrls.add(url);
      }

      await FirebaseFirestore.instance.collection('marketplace_items').doc(itemId).set({
        'sellerId': user.uid,
        'title': title,
        'description': descController.text.trim(),
        'price': double.tryParse(priceController.text) ?? 0.0,
        'imageUrls': imageUrls,
        'city': appState.cityLabel,
        'country': appState.country ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'active',
      });

      if (mounted) {
        context.read<MarketplaceState>().fetchItems(appState.cityLabel);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }

    if (mounted) {
      setState(() => isPosting = false);
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    descController.dispose();
    priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Item')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GestureDetector(
            onTap: pickImage,
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(16),
              ),
              child: selectedImage == null
                  ? const Center(child: Icon(Icons.add_a_photo, size: 50, color: Colors.grey))
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(selectedImage!, fit: BoxFit.cover),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: titleController,
            decoration: const InputDecoration(labelText: 'Title (e.g. Ikea Desk)'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: descController,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Description'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: priceController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Price (0 for free/exchange)'),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: isPosting ? null : submit,
            child: isPosting ? const CircularProgressIndicator(color: Colors.white) : const Text('Post Item'),
          )
        ],
      ),
    );
  }
}
