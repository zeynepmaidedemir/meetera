import 'package:flutter/material.dart';
import 'package:meetera/state/ai_chat_state.dart';
import 'package:provider/provider.dart';

import 'services/notification_service.dart';

import 'state/app_state.dart';
import 'state/chat_state.dart';
import 'state/community_state.dart';
import 'state/event_state.dart';

import 'onboarding/onboarding_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔔 Notification init (SAFE)
  await NotificationService.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
        ChangeNotifierProvider(create: (_) => ChatState()),
        ChangeNotifierProvider(create: (_) => CommunityState()),
        ChangeNotifierProvider(create: (_) => EventState()),
        ChangeNotifierProvider(create: (_) => AiChatState()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: OnboardingGate(),
    );
  }
}
