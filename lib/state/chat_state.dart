import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxdart/rxdart.dart';

class ChatThreadModel {
  final String id;
  final List<String> participants;
  final String lastMessage;
  final DateTime? updatedAt;
  final String? blockedBy;
  final bool isActive;
  final Map<String, dynamic> clearedAt;

  ChatThreadModel({
    required this.id,
    required this.participants,
    required this.lastMessage,
    required this.updatedAt,
    this.blockedBy,
    this.isActive = true,
    this.clearedAt = const {},
  });

  factory ChatThreadModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ChatThreadModel(
      id: doc.id,
      participants: List<String>.from(data['participants'] ?? []),
      lastMessage: (data['lastMessage'] ?? '') as String,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      blockedBy: data['blockedBy'] as String?,
      isActive: (data['isActive'] ?? true) as bool,
      clearedAt: Map<String, dynamic>.from(data['clearedAt'] ?? {}),
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
        'isActive': true,
        'title': otherUserName,
      });
    }
  }

  Stream<QuerySnapshot> messagesStream(String conversationId) {
    final me = currentUserId;
    if (me == null) return const Stream.empty();

    final threadRef = _firestore.collection('chats').doc(conversationId);

    return threadRef.snapshots().switchMap((threadSnap) {
      if (!threadSnap.exists) {
        return threadRef.collection('messages').orderBy('createdAt', descending: false).snapshots();
      }
      final data = threadSnap.data() ?? {};
      final clearedAtMap = data['clearedAt'] as Map<String, dynamic>? ?? {};
      final myClearedAt = clearedAtMap[me] as Timestamp?;

      if (myClearedAt == null) {
        return threadRef.collection('messages').orderBy('createdAt', descending: false).snapshots();
      }

      return threadRef
          .collection('messages')
          .where('createdAt', isGreaterThan: myClearedAt)
          .orderBy('createdAt', descending: false)
          .snapshots();
    });
  }

  Stream<List<ChatThreadModel>> myThreadsStream() {
    final me = currentUserId;
    if (me == null) return const Stream.empty();

    return _firestore
        .collection('chats')
        .where('participants', arrayContains: me)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map((d) => ChatThreadModel.fromDoc(d)).toList();
      
      final filteredList = list.where((thread) {
        final clearedAtMap = thread.clearedAt;
        final myClearedAtTimestamp = clearedAtMap[me] as Timestamp?;
        if (myClearedAtTimestamp == null) return true;

        final myClearedAt = myClearedAtTimestamp.toDate();
        final updatedAt = thread.updatedAt;
        if (updatedAt == null) return true;

        return updatedAt.isAfter(myClearedAt);
      }).toList();

      filteredList.sort((a, b) {
        final dateA = a.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final dateB = b.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return dateB.compareTo(dateA); // descending
      });
      return filteredList;
    });
  }

  Future<void> sendMessage({
    required String conversationId,
    required String otherUserId,
    required String text,
  }) async {
    final me = currentUserId;
    if (me == null) return;

    final threadRef = _firestore.collection('chats').doc(conversationId);

    // Thread exists? Check block status.
    final threadSnap = await threadRef.get();
    if (threadSnap.exists) {
      final data = threadSnap.data() as Map<String, dynamic>? ?? {};
      final blockedBy = data['blockedBy'];
      final isActive = data['isActive'] ?? true;
      if (blockedBy != null || !isActive) {
        throw Exception("Cannot send message. You have been blocked or connection is inactive.");
      }

      await threadRef.update({
        'updatedAt': FieldValue.serverTimestamp(),
        'lastMessage': text,
      });
    } else {
      await threadRef.set({
        'participants': [me, otherUserId],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'lastMessage': text,
        'isActive': true,
      });
    }

    await threadRef.collection('messages').add({
      'senderId': me,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// 🔵 Delete entire chat conversation (soft-clear for current user)
  Future<void> deleteChat(String conversationId) async {
    final me = currentUserId;
    if (me == null) return;

    final threadRef = _firestore.collection('chats').doc(conversationId);
    await threadRef.update({
      'clearedAt.$me': FieldValue.serverTimestamp(),
    });
  }
}
