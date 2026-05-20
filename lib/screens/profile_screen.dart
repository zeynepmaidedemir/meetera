import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../services/auth_service.dart';
import '../services/error_handler.dart';
import 'edit_profile_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  String _fallbackName(User user, Map<String, dynamic> data) {
    final dn = (data['displayName'] ?? '').toString().trim();
    if (dn.isNotEmpty) return dn;

    final fromAuth = (user.displayName ?? '').trim();
    if (fromAuth.isNotEmpty) return fromAuth;

    final email = (user.email ?? '').trim();
    if (email.contains('@')) return email.split('@').first;
    return 'MeetEra User';
  }

  String _fallbackBio(Map<String, dynamic> data) {
    final bio = (data['bio'] ?? '').toString().trim();
    if (bio.isNotEmpty) return bio;
    return "No bio added yet. Tell others about yourself ✨";
  }

  Future<void> _deleteAccount(BuildContext context, User user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Delete Account", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
            "Are you sure you want to permanently delete your account? This action cannot be undone and all your data will be deleted."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Delete", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (!context.mounted) return;
    
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1))),
    );

    try {
      // 1. Delete user data completely from Firestore (Clean wipe)
      await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();
      
      // 2. Attempt to anonymize authored UGC across the platform.
      try {
        final batch = FirebaseFirestore.instance.batch();
        
        // Anonymize Posts
        final posts = await FirebaseFirestore.instance
            .collectionGroup('items')
            .where('authorId', isEqualTo: user.uid)
            .get();
        for (var doc in posts.docs) {
          batch.update(doc.reference, {
            'authorName': 'Deleted User',
            'authorPhotoUrl': '',
          });
        }
        
        // Anonymize Comments
        final comments = await FirebaseFirestore.instance
            .collectionGroup('comments')
            .where('authorId', isEqualTo: user.uid)
            .get();
        for (var doc in comments.docs) {
          batch.update(doc.reference, {
            'authorName': 'Deleted User',
            'authorPhotoUrl': '', 
          });
        }
        
        await batch.commit();
      } catch (e) {
        debugPrint("Could not anonymize all UGC: $e");
      }
      
      // 3. Delete the Auth user
      await user.delete();

      if (!context.mounted) return;
      Navigator.pop(context); // pop loading
      context.read<AppState>().reset(); // resets state and routes to auth
      
      UiHelpers.showPremiumSnackBar(
        context,
        message: "Your account was deleted successfully. Goodbye! 👋",
        isError: false,
      );
    } on FirebaseAuthException catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context); // pop loading
      
      if (e.code == 'requires-recent-login') {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.security, color: Colors.orange),
                SizedBox(width: 8),
                Text("Security Alert", style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            content: const Text(
                "For security reasons, you must have logged in recently to perform critical actions like deleting your account. Please log out, log in again, and try again."),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("OK", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      } else {
        final friendlyMsg = ErrorMapper.getFriendlyMessage(e);
        UiHelpers.showPremiumSnackBar(context, message: friendlyMsg, isError: true);
      }
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context);
      final friendlyMsg = ErrorMapper.getFriendlyMessage(e);
      UiHelpers.showPremiumSnackBar(context, message: friendlyMsg, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text("Not logged in")));
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final data = (snapshot.data!.data() as Map<String, dynamic>?) ?? {};

        final name = _fallbackName(user, data);
        final bio = _fallbackBio(data);
        final photoUrl = (data['photoUrl'] ?? '').toString();

        final cityName = (data['cityName'] ?? data['city'] ?? '').toString();
        final country = (data['country'] ?? '').toString();

        final interests = (data['interests'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList();

        return Scaffold(
          appBar: AppBar(
            title: const Text("My Profile"),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () async {
                  // Pop all routes and go to AuthWrapper (Login screen)
                  Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
                  
                  // Use AuthService to properly sign out from Firebase and Google/Apple
                  await AuthService().signOut();
                  
                  if (context.mounted) {
                    context.read<AppState>().reset();
                  }
                },
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 44,
                    backgroundImage:
                        photoUrl.isNotEmpty ? CachedNetworkImageProvider(photoUrl) : null,
                    child: photoUrl.isEmpty
                        ? const Icon(Icons.person, size: 42)
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          user.email ?? '',
                          style:
                              TextStyle(color: Colors.black.withOpacity(0.6)),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 18),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                (cityName.isEmpty && country.isEmpty)
                                    ? "No city selected"
                                    : "$cityName, $country",
                                style: TextStyle(
                                  color: Colors.black.withOpacity(0.7),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.black.withOpacity(0.06)),
                ),
                child: Text(
                  bio,
                  style: const TextStyle(height: 1.4),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Interests",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.black.withOpacity(0.85),
                ),
              ),
              const SizedBox(height: 10),
              interests.isEmpty
                  ? Text(
                      "No interests selected yet.",
                      style: TextStyle(color: Colors.black.withOpacity(0.6)),
                    )
                  : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          interests.map((e) => Chip(label: Text(e))).toList(),
                    ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text("Edit Profile"),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const EditProfileScreen()),
                    );
                  },
                ),
              ),
              const SizedBox(height: 40),
              TextButton.icon(
                onPressed: () => _deleteAccount(context, user),
                icon: const Icon(Icons.delete_forever, color: Colors.red),
                label: const Text(
                  "Delete Account",
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
