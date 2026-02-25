import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../app_shell.dart';
import '../onboarding/city_picker_screen.dart';
import '../onboarding/interest_picker_screen.dart';
import '../services/auth_service.dart';
import '../state/app_state.dart';

class OnboardingGate extends StatefulWidget {
  const OnboardingGate({super.key});

  @override
  State<OnboardingGate> createState() => _OnboardingGateState();
}

class _OnboardingGateState extends State<OnboardingGate> {
  bool _ensured = false;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final ref = FirebaseFirestore.instance.collection('users').doc(uid);

    return StreamBuilder<DocumentSnapshot>(
      stream: ref.snapshots(),
      builder: (context, snapshot) {
        // loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // doc yoksa -> create + loading göster
        if (!snapshot.hasData || !snapshot.data!.exists) {
          if (!_ensured) {
            _ensured = true;
            AuthService().ensureUserDoc();
          }

          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;

        // 🔥 local state'e hydrate
        context.read<AppState>().hydrateFromFirestore(data);

        final cityId = (data['cityId'] ?? '') as String;
        final interests = List<String>.from(data['interests'] ?? []);
        final onboardingCompleted = data['onboardingCompleted'] ?? false;

        if (cityId.isEmpty) {
          return const CityPickerScreen();
        }

        if (interests.isEmpty) {
          return const InterestPickerScreen();
        }

        if (onboardingCompleted == true) {
          return const AppShell();
        }

        // fallback
        return const AppShell();
      },
    );
  }
}
