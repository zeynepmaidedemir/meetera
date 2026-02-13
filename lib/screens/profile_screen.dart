import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

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

        final data = snapshot.data!.data() as Map<String, dynamic>;

        return Scaffold(
          appBar: AppBar(
            title: const Text("My Profile"),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                },
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage:
                      data['photoUrl'] != null && data['photoUrl'] != ''
                      ? NetworkImage(data['photoUrl'])
                      : null,
                  child: data['photoUrl'] == null || data['photoUrl'] == ''
                      ? const Icon(Icons.person, size: 40)
                      : null,
                ),
                const SizedBox(height: 20),

                Text(
                  data['displayName'] ?? '',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                Text(data['bio'] ?? '', textAlign: TextAlign.center),

                const SizedBox(height: 20),

                Text("📍 ${data['city'] ?? ''}, ${data['country'] ?? ''}"),

                const SizedBox(height: 20),

                Wrap(
                  spacing: 8,
                  children: (data['interests'] as List<dynamic>? ?? [])
                      .map((e) => Chip(label: Text(e)))
                      .toList(),
                ),

                const SizedBox(height: 30),

                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const EditProfileScreen(),
                      ),
                    );
                  },
                  child: const Text("Edit Profile"),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
