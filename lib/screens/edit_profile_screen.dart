import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _authService = AuthService();
  final _firestore = FirebaseFirestore.instance;
  final picker = ImagePicker();

  final nameController = TextEditingController();
  final bioController = TextEditingController();
  final cityController = TextEditingController();
  final countryController = TextEditingController();

  File? selectedImage;
  String? existingPhotoUrl;

  bool loading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await _firestore.collection('users').doc(user.uid).get();

    final data = doc.data();
    if (data == null) return;

    setState(() {
      nameController.text = data['displayName'] ?? '';
      bioController.text = data['bio'] ?? '';
      cityController.text = data['city'] ?? '';
      countryController.text = data['country'] ?? '';
      existingPhotoUrl = data['photoUrl'];
    });
  }

  Future<void> _pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        selectedImage = File(picked.path);
      });

      final url = await _authService.uploadProfilePhoto(selectedImage!);

      setState(() {
        existingPhotoUrl = url;
      });
    }
  }

  Future<void> _save() async {
    setState(() => loading = true);

    await _authService.updateProfile(
      displayName: nameController.text.trim(),
      bio: bioController.text.trim(),
      city: cityController.text.trim(),
      country: countryController.text.trim(),
      interests: [],
    );

    setState(() => loading = false);

    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    nameController.dispose();
    bioController.dispose();
    cityController.dispose();
    countryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Profile")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 55,
                backgroundImage: selectedImage != null
                    ? FileImage(selectedImage!)
                    : (existingPhotoUrl != null && existingPhotoUrl!.isNotEmpty
                              ? NetworkImage(existingPhotoUrl!)
                              : null)
                          as ImageProvider?,
                child:
                    selectedImage == null &&
                        (existingPhotoUrl == null || existingPhotoUrl!.isEmpty)
                    ? const Icon(Icons.camera_alt, size: 30)
                    : null,
              ),
            ),

            const SizedBox(height: 24),

            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Display Name"),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: bioController,
              decoration: const InputDecoration(labelText: "Bio"),
              maxLines: 2,
            ),
            const SizedBox(height: 12),

            TextField(
              controller: cityController,
              decoration: const InputDecoration(labelText: "City"),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: countryController,
              decoration: const InputDecoration(labelText: "Country"),
            ),

            const SizedBox(height: 30),

            loading
                ? const CircularProgressIndicator()
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _save,
                      child: const Text("Save"),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
