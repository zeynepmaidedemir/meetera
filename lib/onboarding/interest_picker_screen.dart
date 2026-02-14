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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              const Text(
                "What are you into?",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              const Text(
                "Pick at least one interest",
                style: TextStyle(color: Colors.grey),
              ),

              const SizedBox(height: 30),

              Expanded(
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: interests.map((interest) {
                    final selected = appState.interests.contains(interest);

                    return ChoiceChip(
                      label: Text(interest),
                      selected: selected,
                      onSelected: (_) {
                        context.read<AppState>().toggleInterest(interest);
                      },
                    );
                  }).toList(),
                ),
              ),

              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: appState.interests.isEmpty
                      ? null
                      : () async {
                          await context.read<AppState>().saveInterests();
                        },
                  child: const Text("Continue"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
