import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

/// =======================
/// MODELS
/// =======================

class AiMessage {
  final String text;
  final bool isUser;

  AiMessage({required this.text, required this.isUser});
}

class AiChat {
  final String id;
  String title;
  final List<AiMessage> messages;

  AiChat({required this.id, required this.title, required this.messages});
}

/// =======================
/// STATE
/// =======================

class AiChatState extends ChangeNotifier {
  final List<AiChat> _chats = [];
  String? _activeChatId;

  /// 📋 Tüm chatler
  List<AiChat> get chats => List.unmodifiable(_chats);

  /// 👉 Aktif chat
  AiChat? get activeChat {
    if (_activeChatId == null) return null;
    return _chats.firstWhere(
      (c) => c.id == _activeChatId,
      orElse: () => _chats.first,
    );
  }

  /// ➕ NEW CHAT
  void createNewChat() {
    final chat = AiChat(id: const Uuid().v4(), title: 'New chat', messages: []);

    _chats.insert(0, chat);
    _activeChatId = chat.id;
    notifyListeners();
  }

  /// 🔁 CHAT AÇ
  void openChat(String chatId) {
    _activeChatId = chatId;
    notifyListeners();
  }

  /// 🗑️ CHAT SİL
  void deleteChat(String chatId) {
    _chats.removeWhere((c) => c.id == chatId);

    if (_activeChatId == chatId) {
      _activeChatId = _chats.isNotEmpty ? _chats.first.id : null;
    }

    notifyListeners();
  }

  /// 💬 MESAJ EKLE
  void addMessage({required String text, required bool isUser}) {
    final chat = activeChat;
    if (chat == null) return;

    chat.messages.add(AiMessage(text: text, isUser: isUser));

    // 📝 İlk user mesajından title üret
    if (chat.messages.length == 1 && isUser) {
      chat.title = text.length > 25 ? '${text.substring(0, 25)}…' : text;
    }

    notifyListeners();
  }

  /// 🔌 BACKEND’E GİDECEK CHAT MEMORY
  List<Map<String, String>> buildChatHistory() {
    final chat = activeChat;
    if (chat == null) return [];

    return chat.messages.map((m) {
      return {'role': m.isUser ? 'user' : 'assistant', 'content': m.text};
    }).toList();
  }

  /// 🧹 RESET (ileride logout için)
  void clearAll() {
    _chats.clear();
    _activeChatId = null;
    notifyListeners();
  }
}
