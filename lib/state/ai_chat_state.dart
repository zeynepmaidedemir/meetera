import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../ai/ai_message.dart';

class AiChat {
  final String id;
  String title;
  final List<AiMessage> messages;

  AiChat({required this.id, required this.title, required this.messages});
}

class AiChatState extends ChangeNotifier {
  final List<AiChat> _chats = [];
  String? _activeChatId;

  List<AiChat> get chats => _chats;

  AiChat? get activeChat {
    if (_activeChatId == null) return null;
    return _chats.firstWhere((c) => c.id == _activeChatId);
  }

  void createNewChat() {
    final chat = AiChat(id: const Uuid().v4(), title: 'New chat', messages: []);
    _chats.insert(0, chat);
    _activeChatId = chat.id;
    notifyListeners();
  }

  void openChat(String id) {
    _activeChatId = id;
    notifyListeners();
  }

  void deleteChat(String id) {
    _chats.removeWhere((c) => c.id == id);
    if (_activeChatId == id) {
      _activeChatId = _chats.isNotEmpty ? _chats.first.id : null;
    }
    notifyListeners();
  }

  // 👤 User
  void addUserMessage(String text) {
    activeChat?.messages.add(AiMessage(text: text, isUser: true));
    notifyListeners();
  }

  // 🤖 AI
  void addAiMessage({required String text}) {
    activeChat?.messages.add(AiMessage(text: text, isUser: false));
    notifyListeners();
  }

  // 🔁 Backend’e gönderilecek geçmiş
  List<Map<String, String>> buildChatHistory() {
    final chat = activeChat;
    if (chat == null) return [];

    return chat.messages
        .where((m) => m.isUser)
        .map((m) => {'role': 'user', 'content': m.text})
        .toList();
  }
}
