import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/ai_chat_state.dart';
import '../state/app_state.dart';
import 'ai_service.dart';
import 'widgets/ai_quick_buttons.dart';
import 'widgets/checklist_card.dart';

class AiScreen extends StatefulWidget {
  const AiScreen({super.key});

  @override
  State<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends State<AiScreen> {
  final TextEditingController _controller = TextEditingController();
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
          // ⚡ QUICK ACTIONS
          AiQuickButtons(
            onSend: (text) {
              _sendQuick(text, aiState, appState);
            },
          ),

          // 💬 CHAT
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: chat.messages.length,
              itemBuilder: (_, i) {
                final m = chat.messages[i];

                // 🧳 CHECKLIST UI
                if (!m.isUser &&
                    m.text.toLowerCase().contains('before arrival')) {
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

          // ⌨️ INPUT
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
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
            onPressed: _loading ? null : () => _send(aiState, appState),
          ),
        ],
      ),
    );
  }

  // ✉️ NORMAL SEND
  Future<void> _send(AiChatState aiState, AppState appState) async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    aiState.addMessage(text: text, isUser: true);
    _controller.clear();
    setState(() => _loading = true);

    await _askAi(aiState, appState);

    setState(() => _loading = false);
  }

  // ⚡ QUICK ACTION SEND
  Future<void> _sendQuick(
    String text,
    AiChatState aiState,
    AppState appState,
  ) async {
    aiState.addMessage(text: text, isUser: true);
    setState(() => _loading = true);

    await _askAi(aiState, appState);

    setState(() => _loading = false);
  }

  // 🤖 TEK AI İSTEK NOKTASI (ÇOK ÖNEMLİ)
  Future<void> _askAi(AiChatState aiState, AppState appState) async {
    try {
      final res = await AiService.askAi(
        messages: aiState.buildChatHistory(),
        city: appState.cityLabel,
      );

      aiState.addMessage(text: res['reply'] ?? '🤖', isUser: false);
    } catch (e) {
      aiState.addMessage(text: '⚠️ AI connection error', isUser: false);
    }
  }
}
