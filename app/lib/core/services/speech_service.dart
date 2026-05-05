import 'dart:developer' as developer;
import 'package:speech_to_text/speech_to_text.dart';

class SpeechService {
  SpeechService._internal();
  static final SpeechService _instance = SpeechService._internal();
  factory SpeechService() => _instance;

  final SpeechToText _speechToText = SpeechToText();
  bool _isInitialized = false;
  void Function(String status)? _statusListener;
  void Function(String error)? _errorListener;

  /// Initializes the speech recognizer
  Future<bool> initialize() async {
    if (_isInitialized) return true;
    _isInitialized = await _speechToText.initialize(
      onError: (val) {
        developer.log('SpeechError: ${val.errorMsg}', name: 'SpeechService');
        _errorListener?.call(val.errorMsg);
      },
      onStatus: (val) {
        developer.log('SpeechStatus: $val', name: 'SpeechService');
        _statusListener?.call(val);
      },
    );
    return _isInitialized;
  }

  /// Starts listening to speech and returns recognized words via callback.
  /// Optionally accepts a locale ID (e.g., 'hi_IN', 'en_US').
  Future<void> startListening({
    required void Function(String text, bool isFinal) onResult,
    String? localeId,
    void Function(double level)? onSoundLevelChange,
    void Function(String status)? onStatusChanged,
    void Function(String error)? onError,
  }) async {
    if (!_isInitialized) await initialize();

    _statusListener = onStatusChanged;
    _errorListener = onError;

    if (_speechToText.isListening) {
      await _speechToText.stop();
    }

    await _speechToText.listen(
      onResult: (result) =>
          onResult(result.recognizedWords, result.finalResult),
      localeId: localeId,
      onSoundLevelChange: onSoundLevelChange,
      listenOptions: SpeechListenOptions(partialResults: true),
    );
  }

  /// Stops listening
  Future<void> stopListening() async {
    await _speechToText.stop();
  }

  bool get isListening => _speechToText.isListening;
}
