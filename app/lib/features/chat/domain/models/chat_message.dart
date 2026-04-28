import 'dart:typed_data';

class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final bool isComplete; // Used for streaming responses
  final Uint8List? imageBytes;
  final String? imageName;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    this.isComplete = true,
    this.imageBytes,
    this.imageName,
  });

  ChatMessage copyWith({
    String? id,
    String? text,
    bool? isUser,
    bool? isComplete,
    Uint8List? imageBytes,
    String? imageName,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      isComplete: isComplete ?? this.isComplete,
      imageBytes: imageBytes ?? this.imageBytes,
      imageName: imageName ?? this.imageName
    );
  }
}
