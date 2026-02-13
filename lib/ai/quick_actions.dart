import 'package:flutter/material.dart';

class AiQuickButtons extends StatelessWidget {
  final void Function(String text) onSend;

  const AiQuickButtons({super.key, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Wrap(
        spacing: 8,
        children: [
          _btn("🏦 Banks", "Which banks are student-friendly in this city?"),
          _btn(
            "🚋 Transport",
            "How does public transport work for students here?",
          ),
          _btn("📋 Checklist", "Give me an Erasmus checklist"),
          _btn(
            "🎉 Events",
            "What kind of events are popular for Erasmus students?",
          ),
        ],
      ),
    );
  }

  Widget _btn(String label, String message) {
    return ActionChip(label: Text(label), onPressed: () => onSend(message));
  }
}
