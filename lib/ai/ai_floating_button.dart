import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/ai_chat_state.dart';
import 'ai_chat_list_screen.dart';

class AiFloatingButton extends StatelessWidget {
  const AiFloatingButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: 'ai_fab',
      child: const Icon(Icons.smart_toy_outlined),
      onPressed: () {
        final aiState = context.read<AiChatState>();

        // Eğer hiç chat yoksa otomatik oluştur
        if (aiState.chats.isEmpty) {
          aiState.createNewChat();
        }

        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AiChatListScreen()),
        );
      },
    );
  }
}
