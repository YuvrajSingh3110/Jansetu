import 'package:jansetu/features/chat/domain/models/chat_message.dart';

class ChatSession {
  final String id;
  final String header;
  final List<ChatMessage> messages;
  final DateTime timestamp;

  const ChatSession({
    required this.id,
    required this.header,
    required this.messages,
    required this.timestamp,
  });

  ChatSession copyWith({
    String? id,
    String? header,
    List<ChatMessage>? messages,
    DateTime? timestamp,
  }) {
    return ChatSession(
      id: id ?? this.id,
      header: header ?? this.header,
      messages: messages ?? this.messages,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'header': header,
      'messages': messages.map((m) => m.toJson()).toList(),
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      id: json['id'] as String,
      header: json['header'] as String,
      messages: (json['messages'] as List<dynamic>)
          .map((m) => ChatMessage.fromJson(m as Map<String, dynamic>))
          .toList(),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}
