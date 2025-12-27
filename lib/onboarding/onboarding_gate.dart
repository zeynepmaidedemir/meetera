import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import 'city_picker_screen.dart';
import 'interest_picker_screen.dart';
import '../app_shell.dart';

class OnboardingGate extends StatelessWidget {
  const OnboardingGate({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    // 1️⃣ City seçilmemişse
    if (!appState.hasCity) {
      return const CityPickerScreen();
    }

    // 2️⃣ Interest tamamlanmamışsa
    if (!appState.interestsCompleted) {
      return const InterestPickerScreen();
    }

    // 3️⃣ Her şey tamam → App
    return const AppShell();
  }
}
