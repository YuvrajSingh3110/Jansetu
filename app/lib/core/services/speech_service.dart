import 'dart:developer' as developer;
import 'package:speech_to_text/speech_to_text.dart';

class SpeechService {
  SpeechService._internal();
  static final SpeechService _instance = SpeechService._internal();
  factory SpeechService() => _instance;

  final SpeechToText _speechToText = SpeechToText();
  bool _isInitialized = false;

  /// Initializes the speech recognizer
  Future<bool> initialize() async {
    if (_isInitialized) return true;
    _isInitialized = await _speechToText.initialize(
      onError: (val) => developer.log('SpeechError: ${val.errorMsg}', name: 'SpeechService'),
      onStatus: (val) => developer.log('SpeechStatus: $val', name: 'SpeechService'),
    );
    return _isInitialized;
  }

  /// Starts listening to speech and returns recognized words via callback.
  /// Optionally accepts a locale ID (e.g., 'hi_IN', 'en_US').
  Future<void> startListening({
    required Function(String) onResult,
    String? localeId,
  }) async {
    if (!_isInitialized) await initialize();
    
    await _speechToText.listen(
      onResult: (result) => onResult(result.recognizedWords),
      localeId: localeId,
    );
  }

  /// Stops listening
  Future<void> stopListening() async {
    await _speechToText.stop();
  }

  bool get isListening => _speechToText.isListening;
}
