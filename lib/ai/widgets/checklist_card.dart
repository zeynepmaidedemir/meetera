import 'package:flutter/material.dart';

class ErasmusChecklistCard extends StatelessWidget {
  final String text;

  const ErasmusChecklistCard({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(text, style: const TextStyle(fontSize: 14, height: 1.5)),
      ),
    );
  }
}
