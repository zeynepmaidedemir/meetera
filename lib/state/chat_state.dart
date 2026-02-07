  import 'package:flutter/material.dart';
  import '../data/chat_models.dart';

  class ChatState extends ChangeNotifier {
    // threadId -> messages
    final Map<String, List<ChatMessage>> _messages = {};

    /// 🔁 THREAD OLUŞTUR / VARSA AL
    String getOrCreateThread({required String userId, required String buddyId}) {
      // deterministik thread id
      final ids = [userId, buddyId]..sort();
      final threadId = ids.join('_');

      _messages.putIfAbsent(threadId, () => []);
      return threadId;
    }

    List<ChatMessage> messagesFor(String threadId) {
      return _messages[threadId] ?? [];
    }

    void sendMessage({required String threadId, required ChatMessage message}) {
      _messages.putIfAbsent(threadId, () => []);
      _messages[threadId]!.add(message);
      notifyListeners();
    }
  }
