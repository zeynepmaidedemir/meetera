import 'package:flutter/material.dart';

class AiQuickActions extends StatelessWidget {
  final void Function(String text) onTap;

  const AiQuickActions({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Wrap(
        spacing: 8,
        children: [
          _chip('🏦 Bank', 'Where can I find nearby banks?'),
          _chip('🚍 Transport', 'How is public transport here?'),
          _chip('🎉 Events', 'What events are happening this week?'),
          _chip('🧳 Erasmus checklist', 'Create an Erasmus checklist'),
        ],
      ),
    );
  }

  Widget _chip(String label, String prompt) {
    return ActionChip(label: Text(label), onPressed: () => onTap(prompt));
  }
}
