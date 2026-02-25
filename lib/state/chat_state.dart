import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatThreadModel {
  final String id;
  final List<String> participants;
  final String lastMessage;
  final DateTime? updatedAt;

  ChatThreadModel({
    required this.id,
    required this.participants,
    required this.lastMessage,
    required this.updatedAt,
  });

  factory ChatThreadModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ChatThreadModel(
      id: doc.id,
      participants: List<String>.from(data['participants'] ?? []),
      lastMessage: (data['lastMessage'] ?? '') as String,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}

class ChatState extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;

  String buildConversationId(String otherUserId) {
    final me = currentUserId!;
    final users = [me, otherUserId]..sort();
    return users.join('_');
  }

  /// ✅ Create thread doc if not exists (so ChatList can show it)
  Future<void> ensureThread({
    required String otherUserId,
    required String otherUserName,
  }) async {
    final me = currentUserId;
    if (me == null) return;

    final convoId = buildConversationId(otherUserId);
    final ref = _firestore.collection('chats').doc(convoId);
    final snap = await ref.get();

    if (!snap.exists) {
      await ref.set({
        'participants': [me, otherUserId],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'lastMessage': '',
        'title': otherUserName, // basit
      });
    }
  }

  Stream<QuerySnapshot> messagesStream(String conversationId) {
    return _firestore
        .collection('chats')
        .doc(conversationId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots();
  }

  Stream<List<ChatThreadModel>> myThreadsStream() {
    final me = currentUserId;
    if (me == null) return const Stream.empty();

    return _firestore
        .collection('chats')
        .where('participants', arrayContains: me)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => ChatThreadModel.fromDoc(d)).toList());
  }

  Future<void> sendMessage({
    required String conversationId,
    required String otherUserId,
    required String text,
  }) async {
    final me = currentUserId;
    if (me == null) return;

    final threadRef = _firestore.collection('chats').doc(conversationId);

    // Thread exists?
    final threadSnap = await threadRef.get();
    if (!threadSnap.exists) {
      await threadRef.set({
        'participants': [me, otherUserId],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'lastMessage': text,
      });
    } else {
      await threadRef.update({
        'updatedAt': FieldValue.serverTimestamp(),
        'lastMessage': text,
      });
    }

    await threadRef.collection('messages').add({
      'senderId': me,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
