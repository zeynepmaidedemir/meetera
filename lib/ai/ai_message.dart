import 'package:cloud_firestore/cloud_firestore.dart';

class AiMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime? createdAt;

  AiMessage({
    required this.id,
    required this.text,
    required this.isUser,
    this.createdAt,
  });

  factory AiMessage.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return AiMessage(
      id: doc.id,
      text: (data['text'] ?? '').toString(),
      isUser: (data['isUser'] ?? true) as bool,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
