import 'package:flutter/material.dart';
import 'package:meetera/ai/ai_chat_list_screen.dart';
import 'package:provider/provider.dart';

// Screens
import 'screens/home_screen.dart';
import 'screens/buddy_screen.dart';
import 'screens/community_screen.dart';
import 'screens/events_screen.dart';
import 'explore/explore_screen.dart';

// 🤖 AI
import 'ai/ai_screen.dart';
import 'ai/ai_context.dart';

// States
import 'state/app_state.dart';
import 'state/event_state.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int index = 0;
  Offset? aiOffset;

  final screens = const [
    HomeScreen(),
    BuddyScreen(),
    CommunityScreen(),
    EventsScreen(),
    ExploreScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    // 📌 İlk açılışta sol alt
    aiOffset ??= Offset(16, size.height - 180);

    return Scaffold(
      body: Stack(
        children: [
          screens[index],

          // 🤖 DRAGGABLE AI
          Positioned(
            left: aiOffset!.dx,
            top: aiOffset!.dy,
            child: Draggable(
              feedback: _buildAiFab(),
              childWhenDragging: const SizedBox.shrink(),
              onDragEnd: (details) {
                setState(() {
                  final dx = details.offset.dx.clamp(0.0, size.width - 72);
                  final dy = details.offset.dy.clamp(0.0, size.height - 160);
                  aiOffset = Offset(dx, dy);
                });
              },
              child: _buildAiFab(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) {
          setState(() => index = i);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            label: 'Buddy',
          ),
          NavigationDestination(
            icon: Icon(Icons.forum_outlined),
            label: 'Community',
          ),
          NavigationDestination(
            icon: Icon(Icons.event_outlined),
            label: 'Events',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            label: 'Explore', // 👈 YENİ
          ),
        ],
      ),
    );
  }

  Widget _buildAiFab() {
    return FloatingActionButton(
      heroTag: 'ai_fab',
      child: const Icon(Icons.smart_toy_outlined),
      onPressed: () {
        final appState = context.read<AppState>();
        final eventState = context.read<EventState>();

        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AiChatListScreen()),
        );
      },
    );
  }
}
