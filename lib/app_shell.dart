import 'package:flutter/material.dart';

// AI
import 'ai/ai_chat_list_screen.dart';

// Screens
import 'screens/dashboard_screen.dart';
import 'screens/buddy_screen.dart';
import 'screens/community_screen.dart';
import 'screens/events_screen.dart';
import 'explore/explore_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/marketplace_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int index = 0;
  Offset? aiOffset;

  void _navigate(int newIndex) {
    setState(() {
      index = newIndex;
    });
  }

  late final List<Widget> screens = [
    DashboardScreen(onNavigate: _navigate),
    const BuddyScreen(),
    const CommunityScreen(),
    const ExploreScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    aiOffset ??= Offset(16, size.height - 240); // Adjusted for new nav bar

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
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
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          height: 64,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withOpacity(0.15),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(0, Icons.home_rounded, Icons.home_outlined),
              _buildNavItem(1, Icons.people_rounded, Icons.people_outline),
              _buildNavItem(2, Icons.forum_rounded, Icons.forum_outlined),
              _buildNavItem(3, Icons.explore_rounded, Icons.explore_outlined),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int itemIndex, IconData activeIcon, IconData inactiveIcon) {
    final isSelected = index == itemIndex;
    return GestureDetector(
      onTap: () => setState(() => index = itemIndex),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 20 : 12,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6366F1).withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(
          isSelected ? activeIcon : inactiveIcon,
          color: isSelected ? const Color(0xFF6366F1) : Colors.grey.shade400,
          size: isSelected ? 28 : 24,
        ),
      ),
    );
  }

  Widget _buildAiFab() {
    return FloatingActionButton(
      heroTag: 'ai_fab',
      child: const Icon(Icons.smart_toy_outlined),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AiChatListScreen()),
        );
      },
    );
  }
}
