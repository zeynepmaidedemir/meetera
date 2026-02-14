import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatState extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String buildConversationId(String otherUserId) {
    final currentUser = FirebaseAuth.instance.currentUser!.uid;
    final users = [currentUser, otherUserId]..sort();
    return users.join('_');
  }

  Stream<QuerySnapshot> messagesStream(String conversationId) {
    return _firestore
        .collection('chats')
        .doc(conversationId)
        .collection('messages')
        .orderBy('createdAt')
        .snapshots();
  }

  Future<void> sendMessage({
    required String conversationId,
    required String text,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser!;

    await _firestore
        .collection('chats')
        .doc(conversationId)
        .collection('messages')
        .add({
      'senderId': currentUser.uid,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
