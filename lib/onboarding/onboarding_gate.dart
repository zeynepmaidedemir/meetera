import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../screens/home_screen.dart';
import 'city_picker_screen.dart';
import 'interest_picker_screen.dart';

class OnboardingGate extends StatefulWidget {
  const OnboardingGate({super.key});

  @override
  State<OnboardingGate> createState() => _OnboardingGateState();
}

class _OnboardingGateState extends State<OnboardingGate> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      context.read<AppState>().loadUserProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    if (!appState.profileLoaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!appState.hasCity) {
      return const CityPickerScreen();
    }

    if (!appState.hasInterests) {
      return const InterestPickerScreen();
    }

    return const HomeScreen();
  }
}
