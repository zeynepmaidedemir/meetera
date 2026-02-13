import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:meetera/explore/state/explore_state.dart';
import 'package:meetera/state/ai_chat_state.dart';
import 'package:provider/provider.dart';

import 'services/notification_service.dart';

import 'state/app_state.dart';
import 'state/chat_state.dart';
import 'state/community_state.dart';
import 'state/event_state.dart';

import 'auth/auth_wrapper.dart'; // 🔥 bunu ekle

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔥 Firebase initialize
  await Firebase.initializeApp();

  // 🔔 Notification init
  await NotificationService.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
        ChangeNotifierProvider(create: (_) => ChatState()),
        ChangeNotifierProvider(create: (_) => CommunityState()),
        ChangeNotifierProvider(create: (_) => EventState()),
        ChangeNotifierProvider(create: (_) => AiChatState()),
        ChangeNotifierProvider(create: (_) => ExploreState()),
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
      home: AuthWrapper(), // 🔥 burayı değiştirdik
    );
  }
}
