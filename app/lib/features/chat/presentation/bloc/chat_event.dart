import 'dart:typed_data';

import 'package:equatable/equatable.dart';

sealed class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

class SendMessage extends ChatEvent {
  final String text;
  final Uint8List? imageBytes;
  final String? imageName;

  const SendMessage(
      this.text, {
        this.imageBytes,
        this.imageName,
      });

  @override
  List<Object?> get props => [text, imageBytes, imageName];
}

class ImageAttachmentSelected extends ChatEvent {
  final Uint8List imageBytes;
  final String imageName;

  const ImageAttachmentSelected({
    required this.imageBytes,
    required this.imageName,
  });

  @override
  List<Object?> get props => [imageBytes, imageName];
}

class ImageAttachmentCleared extends ChatEvent {
  const ImageAttachmentCleared();
}

class VoiceInputStarted extends ChatEvent {
  final String localeCode;
  const VoiceInputStarted({required this.localeCode});
}

class VoiceInputUpdated extends ChatEvent {
  final String recognizedWords;
  const VoiceInputUpdated(this.recognizedWords);

  @override
  List<Object?> get props => [recognizedWords];
}

class VoiceInputStopped extends ChatEvent {
  const VoiceInputStopped();
}

class IncomingStreamChunk extends ChatEvent {
  final String messageId;
  final String chunkText;
  final bool isComplete;

  const IncomingStreamChunk({
    required this.messageId,
    required this.chunkText,
    this.isComplete = false,
  });

  @override
  List<Object?> get props => [messageId, chunkText, isComplete];
}

class ToggleSpeechMute extends ChatEvent {
  const ToggleSpeechMute();
}
