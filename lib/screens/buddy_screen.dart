import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/buddy_state.dart';
import '../state/app_state.dart';
import '../models/user_model.dart';
import 'buddy_card.dart';

class BuddyScreen extends StatefulWidget {
  const BuddyScreen({super.key});

  @override
  State<BuddyScreen> createState() => _BuddyScreenState();
}

class _BuddyScreenState extends State<BuddyScreen> {
  String? _currentCityId;
  List<String> _connectedIds = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final cityId = context.read<AppState>().cityId;
    if (cityId != null && cityId.isNotEmpty && cityId != _currentCityId) {
      _currentCityId = cityId;
      context.read<BuddyState>().loadUsersByCity(cityId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<BuddyState>();
    final appState = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        title: Text("Buddies in ${appState.city ?? ''}"),
        centerTitle: true,
      ),
      body: state.users.isEmpty
          ? const Center(
              child: Text(
                "No buddies found here yet 😢\nCheck back later!",
                textAlign: TextAlign.center,
              ),
            )
          : StreamBuilder<List<String>>(
              stream: state.myConnectedIdsStream(),
              builder: (context, snapshot) {
                final connectedIds = snapshot.data ?? [];
                
                final sortedUsers = List<UserModel>.from(state.users);
                sortedUsers.sort((a, b) {
                  final pA = state.matchPercent(
                    myInterests: appState.interests.toList(),
                    otherInterests: a.interests,
                  );
                  final pB = state.matchPercent(
                    myInterests: appState.interests.toList(),
                    otherInterests: b.interests,
                  );
                  return pB.compareTo(pA); // descending
                });

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: sortedUsers.length,
                  itemBuilder: (_, i) {
                    final u = sortedUsers[i];
                    final isConnected = connectedIds.contains(u.uid);

                    return BuddyCard(buddy: u, isConnected: isConnected);
                  },
                );
              },
            ),
    );
  }
}
