class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final bool isComplete; // Used for streaming responses

  const ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    this.isComplete = true,
  });

  ChatMessage copyWith({
    String? id,
    String? text,
    bool? isUser,
    bool? isComplete,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      isComplete: isComplete ?? this.isComplete,
    );
  }
}
