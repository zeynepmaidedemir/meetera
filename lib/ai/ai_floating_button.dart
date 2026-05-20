import 'package:flutter/material.dart';

import 'ai_chat_list_screen.dart';

class AiFloatingButton extends StatelessWidget {
  const AiFloatingButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: 'ai_fab',
      child: const Icon(Icons.smart_toy_outlined),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AiChatListScreen()),
        );
      },
    );
  }
}
