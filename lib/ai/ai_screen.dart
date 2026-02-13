import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/ai_chat_state.dart';
import '../state/app_state.dart';
import 'ai_service.dart';
import 'widgets/checklist_card.dart';
import 'widgets/ai_quick_buttons.dart';

class AiScreen extends StatefulWidget {
  const AiScreen({super.key});

  @override
  State<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends State<AiScreen> {
  final _controller = TextEditingController();
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final aiState = context.watch<AiChatState>();
    final appState = context.watch<AppState>();
    final chat = aiState.activeChat;

    if (chat == null) {
      return const Scaffold(body: Center(child: Text('No active chat')));
    }

    return Scaffold(
      appBar: AppBar(title: Text(chat.title)),
      body: Column(
        children: [
          AiQuickButtons(onSend: (text) => _send(text, aiState, appState)),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: chat.messages.length,
              itemBuilder: (_, i) {
                final m = chat.messages[i];

                if (!m.isUser && m.text.toLowerCase().contains('checklist')) {
                  return ErasmusChecklistCard(text: m.text);
                }

                return Align(
                  alignment: m.isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: m.isUser
                          ? Colors.blueAccent
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      m.text,
                      style: TextStyle(
                        color: m.isUser ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          _buildInput(aiState, appState),
        ],
      ),
    );
  }

  Widget _buildInput(AiChatState aiState, AppState appState) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(hintText: 'Ask MeetEra AI…'),
            ),
          ),
          IconButton(
            icon: _loading
                ? const CircularProgressIndicator()
                : const Icon(Icons.send),
            onPressed: _loading
                ? null
                : () => _send(_controller.text, aiState, appState),
          ),
        ],
      ),
    );
  }

  Future<void> _send(
    String text,
    AiChatState aiState,
    AppState appState,
  ) async {
    if (text.trim().isEmpty) return;

    aiState.addUserMessage(text);
    _controller.clear();
    setState(() => _loading = true);

    final res = await AiService.askAi(
      messages: aiState.buildChatHistory(),
      city: appState.cityLabel,
    );

    aiState.addAiMessage(text: res['reply'] ?? 'Sure! Let me help you ✨');

    setState(() => _loading = false);
  }
}
