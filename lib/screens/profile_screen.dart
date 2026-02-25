import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import 'edit_profile_screen.dart';

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
    return "No bio yet. Tell people who you are ✨";
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
                  await FirebaseAuth.instance.signOut();
                  context.read<AppState>().reset();
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
                        photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
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
                                    ? "City not set yet"
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
            ],
          ),
        );
      },
    );
  }
}
