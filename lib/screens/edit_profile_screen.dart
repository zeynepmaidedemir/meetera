import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/auth_service.dart';
import '../services/error_handler.dart';
import 'event_city_picker_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
  final bioController = TextEditingController(); // şimdilik UI’da duruyor
  final cityController = TextEditingController();
  final countryController = TextEditingController();

  File? selectedImage;
  String? existingPhotoUrl;

  bool loading = false;

  // ✅ Onboarding alanları
  String _cityId = '';
  String _countryCode = '';
  List<String> _interests = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  String _buildCountryCode(String country) {
    final t = country.trim();
    if (t.isEmpty) return '';
    // super basit fallback: ilk 2 harf
    return t.length >= 2 ? t.substring(0, 2).toUpperCase() : t.toUpperCase();
  }

  String _buildCityId(String city, String countryCode) {
    final c = city.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_');
    final cc = countryCode.trim().toLowerCase();
    if (c.isEmpty || cc.isEmpty) return '';
    return '${c}_$cc';
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    final data = doc.data();
    if (data == null) return;

    setState(() {
      nameController.text = (data['displayName'] ?? '') as String;
      bioController.text = (data['bio'] ?? '') as String;

      // 🔥 DİKKAT: projede alan adı cityName / country
      cityController.text = (data['cityName'] ?? data['city'] ?? '') as String;
      countryController.text = (data['country'] ?? '') as String;

      existingPhotoUrl = data['photoUrl'] as String?;

      _cityId = (data['cityId'] ?? '') as String;
      _countryCode = (data['countryCode'] ?? '') as String;

      _interests = List<String>.from(data['interests'] ?? []);
    });
  }

  Future<void> _pickImage() async {
    try {
      final picked = await picker.pickImage(source: ImageSource.gallery);

      if (picked != null) {
        setState(() {
          selectedImage = File(picked.path);
          loading = true;
        });

        if (mounted) {
          UiHelpers.showPremiumSnackBar(
            context,
            message: "Uploading your profile photo, please wait...",
            isError: false,
            duration: const Duration(seconds: 2),
          );
        }

        final url = await _authService.uploadProfilePhoto(selectedImage!);

        if (!mounted) return;
        setState(() {
          existingPhotoUrl = url;
        });

        UiHelpers.showPremiumSnackBar(
          context,
          message: "Profile photo updated successfully! ✨",
          isError: false,
        );
      }
    } catch (e) {
      if (mounted) {
        final friendlyMsg = ErrorMapper.getFriendlyMessage(e);
        UiHelpers.showPremiumSnackBar(context, message: friendlyMsg, isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  Future<void> _save() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final displayName = nameController.text.trim();
    final cityName = cityController.text.trim();
    final country = countryController.text.trim();

    if (displayName.isEmpty) {
      UiHelpers.showPremiumSnackBar(context, message: "Please enter your display name.");
      return;
    }

    if (cityName.isEmpty) {
      UiHelpers.showPremiumSnackBar(context, message: "Please select your city.");
      return;
    }

    // countryCode / cityId yoksa üret (fallback)
    final countryCode = (_countryCode.trim().isNotEmpty)
        ? _countryCode.trim()
        : _buildCountryCode(country);

    final cityId = (_cityId.trim().isNotEmpty)
        ? _cityId.trim()
        : _buildCityId(cityName, countryCode);

    setState(() => loading = true);

    try {
      // ✅ interests'i ASLA boş listeyle overwrite etmiyoruz
      await _authService.updateProfile(
        displayName: displayName,
        bio: bioController.text.trim(),
        cityName: cityName,
        country: country,
        countryCode: countryCode,
        cityId: cityId,
        interests: _interests,
      );

      if (mounted) {
        UiHelpers.showPremiumSnackBar(
          context,
          message: "Profile updated successfully! ✨",
          isError: false,
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        final friendlyMsg = ErrorMapper.getFriendlyMessage(e);
        UiHelpers.showPremiumSnackBar(context, message: friendlyMsg, isError: true);
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
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
                        ? CachedNetworkImageProvider(existingPhotoUrl!)
                        : null) as ImageProvider?,
                child: selectedImage == null &&
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
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EventCityPickerScreen()),
                );
                if (result != null && result is Map<String, String>) {
                  setState(() {
                    cityController.text = result['cityName'] ?? '';
                    countryController.text = result['countryName'] ?? '';
                  });
                }
              },
              child: AbsorbPointer(
                child: TextField(
                  controller: cityController,
                  decoration: const InputDecoration(
                    labelText: "City",
                    suffixIcon: Icon(Icons.arrow_forward_ios, size: 16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            AbsorbPointer(
              child: TextField(
                controller: countryController,
                decoration: const InputDecoration(
                  labelText: "Country",
                  helperText: "Country updates automatically when you select a city.",
                ),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: loading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        "Save",
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
