import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../data/buddy_data.dart';
import 'buddy_card.dart';

class BuddyScreen extends StatelessWidget {
  const BuddyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final city = appState.cityLabel.split(',').first;
    final interests = appState.interests;

    // 🎯 CITY + INTEREST FILTER
    final matchedBuddies =
        mockBuddies.where((b) {
          final sameCity = b.city == city;
          final commonInterest = b.interests.any(interests.contains);
          return sameCity && commonInterest;
        }).toList()..sort((a, b) {
          final aRatio = calculateMatchRatio(interests, a.interests);
          final bRatio = calculateMatchRatio(interests, b.interests);
          return bRatio.compareTo(aRatio); // 🔥 yüksekten düşüğe
        });

    final connected = matchedBuddies
        .where((b) => appState.isConnected(b.id))
        .toList();

    final discover = matchedBuddies
        .where((b) => !appState.isConnected(b.id))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Buddy')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: matchedBuddies.isEmpty
            ? const Center(
                child: Text(
                  'No buddies found yet 🤍\nTry updating your interests',
                  textAlign: TextAlign.center,
                ),
              )
            : ListView(
                children: [
                  // 🤝 CONNECTED
                  if (connected.isNotEmpty) ...[
                    const _SectionTitle('Connected'),
                    const SizedBox(height: 8),
                    ...connected.map((b) => BuddyCard(buddy: b)),
                    const SizedBox(height: 24),
                  ],

                  // 🔍 DISCOVER
                  if (discover.isNotEmpty) ...[
                    const _SectionTitle('Discover'),
                    const SizedBox(height: 8),
                    ...discover.map((b) => BuddyCard(buddy: b)),
                  ],

                  // 🎉 ALL CONNECTED STATE
                  if (discover.isEmpty && connected.isNotEmpty) ...[
                    const SizedBox(height: 40),
                    const Center(
                      child: Column(
                        children: [
                          Text('🎉', style: TextStyle(fontSize: 48)),
                          SizedBox(height: 12),
                          Text(
                            "You're all connected!",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'You’ve connected with everyone\nwho matches your interests.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
    );
  }
}

// 🎯 MATCH CALCULATION (SIRALAMA + CARD İÇİN)
double calculateMatchRatio(
  Set<String> userInterests,
  List<String> buddyInterests,
) {
  if (userInterests.isEmpty || buddyInterests.isEmpty) return 0.0;

  final commonCount = buddyInterests
      .where((i) => userInterests.contains(i))
      .length;

  return commonCount / buddyInterests.length;
}
