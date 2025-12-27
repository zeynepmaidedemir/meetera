import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';

class InterestPickerScreen extends StatelessWidget {
  const InterestPickerScreen({super.key});

  static const interests = [
    {'key': 'Books', 'label': '📚 Books'},
    {'key': 'Music', 'label': '🎵 Music'},
    {'key': 'Movies', 'label': '🎬 Movies'},
    {'key': 'Coffee', 'label': '☕ Coffee'},
    {'key': 'Walking', 'label': '🚶 Walking'},
    {'key': 'Travel', 'label': '✈️ Travel'},
  ];

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(title: const Text('Your interests')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'These help us match you with buddies 👋',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: interests.map((i) {
                  final key = i['key']!;
                  final label = i['label']!;
                  final selected = appState.interests.contains(key);

                  return FilterChip(
                    label: Text(label),
                    selected: selected,
                    onSelected: (_) {
                      appState.toggleInterest(key); // 🔥 SADECE KEY
                    },
                  );
                }).toList(),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  appState.completeInterests();
                },
                child: const Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
