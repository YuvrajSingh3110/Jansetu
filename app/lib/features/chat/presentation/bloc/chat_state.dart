import 'package:equatable/equatable.dart';
import 'package:jansetu/features/chat/domain/models/chat_message.dart';

class ChatState extends Equatable {
  final List<ChatMessage> messages;
  final bool isListening;
  final String currentVoiceInput;
  final bool isSpeechMuted;

  const ChatState({
    this.messages = const [],
    this.isListening = false,
    this.currentVoiceInput = '',
    this.isSpeechMuted = false,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isListening,
    String? currentVoiceInput,
    bool? isSpeechMuted,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isListening: isListening ?? this.isListening,
      currentVoiceInput: currentVoiceInput ?? this.currentVoiceInput,
      isSpeechMuted: isSpeechMuted ?? this.isSpeechMuted,
    );
  }

  @override
  List<Object?> get props => [messages, isListening, currentVoiceInput, isSpeechMuted];
}
