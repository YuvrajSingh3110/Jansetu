import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:jansetu/features/chat/domain/models/chat_message.dart';

class ChatState extends Equatable {
  final List<ChatMessage> messages;
  final bool isListening;
  final String currentVoiceInput;
  final bool isSpeechMuted;
  
  // Image attachment state
  final Uint8List? selectedImageBytes;
  final String? selectedImageName;

  // Session state
  final String? sessionId;
  final String? sessionHeader;

  // Submission state
  final bool isSubmittingReport;
  final bool isReportSubmitted;

  const ChatState({
    this.messages = const [],
    this.isListening = false,
    this.currentVoiceInput = '',
    this.isSpeechMuted = false,
    this.selectedImageBytes,
    this.selectedImageName,
    this.sessionId,
    this.sessionHeader,
    this.isSubmittingReport = false,
    this.isReportSubmitted = false,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isListening,
    String? currentVoiceInput,
    bool? isSpeechMuted,
    Uint8List? selectedImageBytes,
    String? selectedImageName,
    bool clearSelectedImage = false,
    String? sessionId,
    String? sessionHeader,
    bool? isSubmittingReport,
    bool? isReportSubmitted,
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
      sessionId: sessionId ?? this.sessionId,
      sessionHeader: sessionHeader ?? this.sessionHeader,
      isSubmittingReport: isSubmittingReport ?? this.isSubmittingReport,
      isReportSubmitted: isReportSubmitted ?? this.isReportSubmitted,
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
        sessionId,
        sessionHeader,
        isSubmittingReport,
        isReportSubmitted,
      ];
}
