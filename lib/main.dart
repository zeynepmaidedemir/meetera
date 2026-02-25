import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'services/notification_service.dart';

import 'state/app_state.dart';
import 'state/chat_state.dart';
import 'state/community_state.dart';
import 'state/event_state.dart';
import 'state/buddy_state.dart';
import 'state/ai_chat_state.dart';
import 'explore/state/explore_state.dart';

import 'auth/auth_wrapper.dart';

import 'explore/explore_route_screen.dart';
import 'explore/explore_wrap_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
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
        ChangeNotifierProvider(create: (_) => BuddyState()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const AuthWrapper(),

      // 🔥 BURASI ÇOK ÖNEMLİ
      routes: {
        "/exploreRoute": (_) => const ExploreRouteScreen(),
        "/exploreWrap": (_) => const ExploreWrapScreen(),
      },
    );
  }
}
