import 'package:flutter/material.dart';

class AiQuickButtons extends StatelessWidget {
  final void Function(String text) onSend;

  const AiQuickButtons({super.key, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _chip('🏦 Bank', 'Find nearby banks'),
          _chip('🚍 Transport', 'Public transport info'),
          _chip('🎉 Events', 'Events in my city'),
          _chip('🧳 Checklist', 'Create an Erasmus checklist'),
        ],
      ),
    );
  }

  Widget _chip(String label, String prompt) {
    return ActionChip(label: Text(label), onPressed: () => onSend(prompt));
  }
}
