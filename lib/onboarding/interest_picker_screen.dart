import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';

class InterestPickerScreen extends StatelessWidget {
  const InterestPickerScreen({super.key});

  static const interests = [
    "Travel",
    "Food",
    "Coding",
    "Music",
    "Photography",
    "Gym",
    "Gaming",
    "Hiking",
    "Art",
    "Movies",
  ];

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Select your interests"),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: interests.map((interest) {
                final selected = appState.interests.contains(interest);

                return FilterChip(
                  label: Text(interest),
                  selected: selected,
                  onSelected: (_) {
                    context.read<AppState>().toggleInterest(interest);
                  },
                );
              }).toList(),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: appState.interests.isEmpty
                    ? null
                    : () {
                        context.read<AppState>().completeInterests();
                      },
                child: const Text("Continue"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
