import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../onboarding/city_picker_screen.dart';
import '../onboarding/interest_picker_screen.dart';
import '../app_shell.dart';

class OnboardingGate extends StatefulWidget {
  const OnboardingGate({super.key});

  @override
  State<OnboardingGate> createState() => _OnboardingGateState();
}

class _OnboardingGateState extends State<OnboardingGate> {
  @override
  void initState() {
    super.initState();

    // 🔥 Profile load AFTER build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().loadUserProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    // 🔥 Profile loading
    if (!appState.profileLoaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // 🔥 City not selected
    if (!appState.hasCity) {
      return const CityPickerScreen();
    }

    // 🔥 Interests not selected
    if (!appState.hasInterests) {
      return const InterestPickerScreen();
    }

    // 🔥 All good → main app
    return const AppShell();
  }
}
