import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:jansetu/core/services/llm_service.dart';
import 'package:jansetu/core/services/speech_service.dart';
import 'package:jansetu/core/services/tts_service.dart';
import 'package:jansetu/features/chat/domain/models/chat_message.dart';
import 'package:jansetu/features/chat/presentation/bloc/chat_event.dart';
import 'package:jansetu/features/chat/presentation/bloc/chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final LlmService _llmService = LlmService();
  final SpeechService _speechService = SpeechService();
  final TtsService _ttsService = TtsService();
  final Uuid _uuid = const Uuid();

  String _currentSpeechBuffer = '';

  ChatBloc() : super(const ChatState()) {
    on<SendMessage>(_onSendMessage);
    on<VoiceInputStarted>(_onVoiceInputStarted);
    on<VoiceInputUpdated>(_onVoiceInputUpdated);
    on<VoiceInputStopped>(_onVoiceInputStopped);
    on<IncomingStreamChunk>(_onIncomingStreamChunk);
    on<ToggleSpeechMute>(_onToggleSpeechMute);

    // Initialise LLM and Speech services
    _llmService.initialize();
    _speechService.initialize();
  }

  @override
  Future<void> close() async {
    await _ttsService.stop();
    return super.close();
  }

  void _onToggleSpeechMute(
    ToggleSpeechMute event,
    Emitter<ChatState> emit,
  ) {
    final newMuteState = !state.isSpeechMuted;
    _ttsService.setMuted(newMuteState);
    emit(state.copyWith(isSpeechMuted: newMuteState));
  }

  Future<void> _onSendMessage(
    SendMessage event,
    Emitter<ChatState> emit,
  ) async {
    if (event.text.trim().isEmpty) return;

    final userMsg = ChatMessage(
      id: _uuid.v4(),
      text: event.text,
      isUser: true,
    );

    final aiMsgId = _uuid.v4();
    final initialAiMsg = ChatMessage(
      id: aiMsgId,
      text: '',
      isUser: false,
      isComplete: false,
    );

    emit(state.copyWith(
      messages: List.from(state.messages)..add(userMsg)..add(initialAiMsg),
    ));

    final stream = _llmService.getResponseStream(event.text);
    
    await for (final chunk in stream) {
      if (!isClosed) {
        add(IncomingStreamChunk(messageId: aiMsgId, chunkText: chunk));
      }
    }

    if (!isClosed) {
      add(IncomingStreamChunk(messageId: aiMsgId, chunkText: '', isComplete: true));
    }
  }

  void _onIncomingStreamChunk(
    IncomingStreamChunk event,
    Emitter<ChatState> emit,
  ) {
    final updatedMessages = state.messages.map((msg) {
      if (msg.id == event.messageId) {
        return msg.copyWith(
          text: msg.text + event.chunkText,
          isComplete: event.isComplete,
        );
      }
      return msg;
    }).toList();

    if (!state.isSpeechMuted && event.chunkText.isNotEmpty) {
      _currentSpeechBuffer += event.chunkText;
      // If we encounter a sentence ending punctuation, speak it
      if (RegExp(r'[.!?।\n]\s*$').hasMatch(_currentSpeechBuffer)) {
        _ttsService.speak(_currentSpeechBuffer);
        _currentSpeechBuffer = '';
      }
    }

    if (event.isComplete) {
      if (!state.isSpeechMuted && _currentSpeechBuffer.trim().isNotEmpty) {
        _ttsService.speak(_currentSpeechBuffer);
      }
      _currentSpeechBuffer = '';
    }

    emit(state.copyWith(messages: updatedMessages));
  }

  Future<void> _onVoiceInputStarted(
    VoiceInputStarted event,
    Emitter<ChatState> emit,
  ) async {
    emit(state.copyWith(isListening: true, currentVoiceInput: ''));
    
    await _speechService.startListening(
      localeId: event.localeCode,
      onResult: (text) {
        if (!isClosed) {
          add(VoiceInputUpdated(text));
        }
      },
    );
  }

  void _onVoiceInputUpdated(
    VoiceInputUpdated event,
    Emitter<ChatState> emit,
  ) {
    emit(state.copyWith(currentVoiceInput: event.recognizedWords));
  }

  Future<void> _onVoiceInputStopped(
    VoiceInputStopped event,
    Emitter<ChatState> emit,
  ) async {
    await _speechService.stopListening();
    
    final finalVoiceInput = state.currentVoiceInput;
    emit(state.copyWith(isListening: false, currentVoiceInput: ''));

    if (finalVoiceInput.isNotEmpty) {
      add(SendMessage(finalVoiceInput));
    }
  }
}
