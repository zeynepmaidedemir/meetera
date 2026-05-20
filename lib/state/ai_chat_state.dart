import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../ai/ai_message.dart';

class AiChat {
  final String id;
  String title;
  final List<AiMessage> messages;
  final DateTime? updatedAt;

  AiChat({
    required this.id,
    required this.title,
    required this.messages,
    this.updatedAt,
  });

  factory AiChat.fromDoc(DocumentSnapshot doc, {List<AiMessage> messages = const []}) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return AiChat(
      id: doc.id,
      title: data['title'] ?? 'New Chat',
      messages: messages,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}

class AiChatState extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _activeChatId;

  String? get activeChatId => _activeChatId;

  void openChat(String id) {
    _activeChatId = id;
    notifyListeners();
  }

  /// 🔵 Stream of all chats for current user
  Stream<List<AiChat>> myChatsStream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Stream.empty();

    return _firestore
        .collection('ai_chats')
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map((doc) => AiChat.fromDoc(doc)).toList();
      list.sort((a, b) => (b.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0))
          .compareTo(a.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0)));
      return list;
    });
  }

  /// 🔵 Stream of messages for specific active chat
  Stream<List<AiMessage>> activeChatMessagesStream(String chatId) {
    return _firestore
        .collection('ai_chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => AiMessage.fromDoc(doc)).toList());
  }

  /// 🔵 Create new chat in Firestore
  Future<String> createNewChat() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception("Not logged in");

    final docRef = _firestore.collection('ai_chats').doc();
    await docRef.set({
      'userId': uid,
      'title': 'New Chat',
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
    });

    _activeChatId = docRef.id;
    notifyListeners();
    return docRef.id;
  }

  /// 🔵 Rename chat
  Future<void> renameChat(String chatId, String newTitle) async {
    await _firestore.collection('ai_chats').doc(chatId).update({
      'title': newTitle,
      'updatedAt': Timestamp.now(),
    });
    notifyListeners();
  }

  /// 🔵 Delete chat and its messages
  Future<void> deleteChat(String chatId) async {
    final chatRef = _firestore.collection('ai_chats').doc(chatId);
    
    // Get messages to delete
    final messagesSnap = await chatRef.collection('messages').get();
    final batch = _firestore.batch();
    for (var doc in messagesSnap.docs) {
      batch.delete(doc.reference);
    }
    
    batch.delete(chatRef);
    await batch.commit();

    if (_activeChatId == chatId) {
      _activeChatId = null;
    }
    notifyListeners();
  }

  /// 🔵 Add user message to active chat
  Future<void> addUserMessage(String chatId, String text) async {
    final chatRef = _firestore.collection('ai_chats').doc(chatId);
    final messagesRef = chatRef.collection('messages');

    // Add message
    await messagesRef.add({
      'text': text,
      'isUser': true,
      'createdAt': Timestamp.now(),
    });

    // Auto-Title: If chat title is still "New Chat", generate one from first message
    final chatSnap = await chatRef.get();
    if (chatSnap.exists) {
      final currentTitle = chatSnap.data()?['title'] ?? 'New Chat';
      if (currentTitle == 'New Chat') {
        final words = text.split(' ');
        final title = words.length > 4 ? '${words.take(4).join(' ')}...' : text;
        await chatRef.update({
          'title': title,
        });
      }
    }

    // Update timestamp
    await chatRef.update({
      'updatedAt': Timestamp.now(),
    });
  }

  /// 🔵 Add AI reply to active chat
  Future<void> addAiMessage(String chatId, String text) async {
    final chatRef = _firestore.collection('ai_chats').doc(chatId);
    final messagesRef = chatRef.collection('messages');

    await messagesRef.add({
      'text': text,
      'isUser': false,
      'createdAt': Timestamp.now(),
    });

    await chatRef.update({
      'updatedAt': Timestamp.now(),
    });
  }
}
