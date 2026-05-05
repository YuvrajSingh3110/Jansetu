import 'dart:convert';
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'isUser': isUser,
      'isComplete': isComplete,
      'imageBytes': imageBytes != null ? base64Encode(imageBytes!) : null,
      'imageName': imageName,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      text: json['text'] as String,
      isUser: json['isUser'] as bool,
      isComplete: json['isComplete'] as bool,
      imageBytes: json['imageBytes'] != null ? base64Decode(json['imageBytes'] as String) : null,
      imageName: json['imageName'] as String?,
    );
  }
}
