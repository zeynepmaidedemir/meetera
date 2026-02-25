import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/buddy_state.dart';
import '../state/app_state.dart';
import '../models/buddy_user.dart';
import 'buddy_card.dart';

class BuddyScreen extends StatefulWidget {
  const BuddyScreen({super.key});

  @override
  State<BuddyScreen> createState() => _BuddyScreenState();
}

class _BuddyScreenState extends State<BuddyScreen> {
  bool _loaded = false;
  List<String> _connectedIds = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;

    final cityId = context.read<AppState>().cityId;
    if (cityId != null && cityId.isNotEmpty) {
      context.read<BuddyState>().loadUsersByCity(cityId);
      _loadConnections();
    }
    _loaded = true;
  }

  Future<void> _loadConnections() async {
    final buddyState = context.read<BuddyState>();
    final ids = await buddyState.getMyConnectedIds();
    if (!mounted) return;
    setState(() {
      _connectedIds = ids;
    });
  }

  @override
  Widget build(BuildContext context) {
    final buddyState = context.watch<BuddyState>();
    final appState = context.watch<AppState>();
    final users = buddyState.users;

    final sorted = [...users];

    sorted.sort((a, b) {
      final aConnected = _connectedIds.contains(a.uid);
      final bConnected = _connectedIds.contains(b.uid);

      if (aConnected && !bConnected) return -1;
      if (!aConnected && bConnected) return 1;

      final aMatch = buddyState.matchPercent(
        myInterests: appState.interests.toList(),
        otherInterests: a.interests,
      );

      final bMatch = buddyState.matchPercent(
        myInterests: appState.interests.toList(),
        otherInterests: b.interests,
      );

      return bMatch.compareTo(aMatch);
    });

    return Scaffold(
      appBar: AppBar(title: const Text("Buddies")),
      body: sorted.isEmpty
          ? const Center(child: Text("No users in this city yet 👀"))
          : RefreshIndicator(
              onRefresh: () async {
                final cityId = appState.cityId;
                if (cityId != null) {
                  await buddyState.loadUsersByCity(cityId);
                  await _loadConnections();
                }
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: sorted.length,
                itemBuilder: (_, i) {
                  final BuddyUser user = sorted[i];
                  final isConnected = _connectedIds.contains(user.uid);

                  return BuddyCard(
                    buddy: user,
                    isConnected: isConnected,
                  );
                },
              ),
            ),
    );
  }
}
