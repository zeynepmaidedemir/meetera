class ChatThread {
  final String id;
  final List<String> participants;
  final String lastMessage;
  final DateTime updatedAt;

  ChatThread({
    required this.id,
    required this.participants,
    required this.lastMessage,
    required this.updatedAt,
  });
}

class ChatMessage {
  final String id;
  final String senderId;
  final String text;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.createdAt,
  });
}
