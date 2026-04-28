import 'dart:collection';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:developer' as developer;

class TtsService {
  TtsService._internal() {
    _initTts();
  }

  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;

  final FlutterTts _flutterTts = FlutterTts();
  final Queue<String> _speechQueue = Queue<String>();
  bool _isSpeaking = false;
  bool _isMuted = false;

  Future<void> _initTts() async {
    try {
      await _flutterTts.setLanguage("en-IN");
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      _flutterTts.setCompletionHandler(() {
        _isSpeaking = false;
        _speakNext();
      });

      _flutterTts.setErrorHandler((msg) {
        developer.log('TTS Error: $msg', name: 'TtsService');
        _isSpeaking = false;
        _speakNext();
      });
    } catch (e) {
      developer.log('Failed to init TTS: $e', name: 'TtsService');
    }
  }

  bool get isMuted => _isMuted;

  Future<void> setLanguageForLocale(String localeCode) async {
    final language = switch (localeCode) {
      'hi' => 'hi-IN',
      'or' => 'or-IN',
      'bn' => 'bn-IN',
      'pa' => 'pa-IN',
      'bho' => 'hi-IN',
      _ => 'en-IN',
    };
    try {
      await _flutterTts.setLanguage(language);
    } catch (e) {
      developer.log('Failed to set TTS language: $e', name: 'TtsService');
    }
  }

  void setMuted(bool muted) {
    _isMuted = muted;
    if (_isMuted) {
      stop();
    }
  }

  void speak(String text) {
    if (_isMuted || text.trim().isEmpty) return;
    
    // Add to queue and trigger playback
    _speechQueue.add(text);
    _speakNext();
  }

  Future<void> _speakNext() async {
    if (_isSpeaking || _speechQueue.isEmpty || _isMuted) return;
    
    _isSpeaking = true;
    final text = _speechQueue.removeFirst();
    try {
      await _flutterTts.speak(text);
    } catch (e) {
      developer.log('Error speaking: $e', name: 'TtsService');
      _isSpeaking = false;
      _speakNext();
    }
  }

  Future<void> stop() async {
    _speechQueue.clear();
    _isSpeaking = false;
    await _flutterTts.stop();
  }
}
