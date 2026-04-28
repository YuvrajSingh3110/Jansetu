import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:jansetu/features/chat/domain/models/chat_message.dart';

class ChatState extends Equatable {
  final List<ChatMessage> messages;
  final bool isListening;
  final String currentVoiceInput;
  final bool isSpeechMuted;
  final Uint8List? selectedImageBytes;
  final String? selectedImageName;

  const ChatState({
    this.messages = const [],
    this.isListening = false,
    this.currentVoiceInput = '',
    this.isSpeechMuted = false,
    this.selectedImageBytes,
    this.selectedImageName,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isListening,
    String? currentVoiceInput,
    bool? isSpeechMuted,
    Uint8List? selectedImageBytes,
    String? selectedImageName,
    bool clearSelectedImage = false,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isListening: isListening ?? this.isListening,
      currentVoiceInput: currentVoiceInput ?? this.currentVoiceInput,
      isSpeechMuted: isSpeechMuted ?? this.isSpeechMuted,
      selectedImageBytes: clearSelectedImage
          ? null
          : (selectedImageBytes ?? this.selectedImageBytes),
      selectedImageName: clearSelectedImage
          ? null
          : (selectedImageName ?? this.selectedImageName),
    );
  }

  @override
  List<Object?> get props => [
    messages,
    isListening,
    currentVoiceInput,
    isSpeechMuted,
    selectedImageBytes,
    selectedImageName,
  ];}
