import 'package:flutter/material.dart';
import 'package:meetera/state/chat_state.dart';
import 'package:provider/provider.dart';

import 'state/app_state.dart';
import 'onboarding/onboarding_gate.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
        ChangeNotifierProvider(create: (_) => ChatState()), // 🔥 BU ŞART
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: OnboardingGate(), // 🔥 BURASI
      ),
    );
  }
}
