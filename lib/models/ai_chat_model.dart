import 'package:cloud_firestore/cloud_firestore.dart';

class AIChatModel {
  final String id;
  final String userId;
  String title;
  final DateTime createdAt;
  final DateTime updatedAt;

  AIChatModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AIChatModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AIChatModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? 'New Chat',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

class AIMessageModel {
  final String id;
  final String role; // 'user' or 'assistant'
  final String content;
  final DateTime timestamp;

  AIMessageModel({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
  });

  factory AIMessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AIMessageModel(
      id: doc.id,
      role: data['role'] ?? 'user',
      content: data['content'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'role': role,
      'content': content,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
