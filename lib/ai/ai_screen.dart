import 'package:flutter/material.dart';

import 'ai_context.dart';
import 'ai_service.dart';

class AiScreen extends StatefulWidget {
  final AiContext contextData;

  const AiScreen({super.key, required this.contextData});

  @override
  State<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends State<AiScreen> {
  final _controller = TextEditingController();
  final List<_Message> _messages = [];
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ask MeetEra AI')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (_, i) {
                final m = _messages[i];
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
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildInput() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(hintText: 'Ask something…'),
            ),
          ),
          IconButton(
            icon: _loading
                ? const CircularProgressIndicator()
                : const Icon(Icons.send),
            onPressed: _loading ? null : _send,
          ),
        ],
      ),
    );
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(_Message(text, true));
      _controller.clear();
      _loading = true;
    });

    final res = await AiService.askAi(
      message: text,
      context: widget.contextData,
      // 🔜 ileride GPS ekleriz
    );

    setState(() {
      _messages.add(_Message(res['reply'] ?? '🤖'));
      _loading = false;
    });
  }
}

class _Message {
  final String text;
  final bool isUser;

  _Message(this.text, [this.isUser = false]);
}
