import 'package:flutter/material.dart';
import 'package:meetera/screens/events_screen.dart';

import 'screens/home_screen.dart';
import 'screens/buddy_screen.dart';
import 'screens/community_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int index = 0;

  final screens = const [
    HomeScreen(),
    BuddyScreen(),
    CommunityScreen(),
    EventsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: screens[index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) {
          setState(() {
            index = i;
          });
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
        ],
      ),
    );
  }
}
