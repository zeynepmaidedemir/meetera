enum AiMessageSender { user, ai }

class AiMessage {
  final String text;
  final AiMessageSender sender;

  AiMessage({required this.text, required this.sender});
}
