import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:permission_handler/permission_handler.dart';

class LlmService {
  LlmService._internal();
  static final LlmService _instance = LlmService._internal();
  factory LlmService() => _instance;

  bool _isInitialized = false;
  InferenceModel? _model;
  InferenceChat? _chat;

  static const _modelPath =
      '/storage/emulated/0/Download/gemma-4-E2B-it.litertlm';

  Future<bool> _requestStoragePermission() async {
    // Android 13+ uses granular media permissions
    // Android 10-12 uses READ_EXTERNAL_STORAGE
    PermissionStatus status;

    if (await Permission.manageExternalStorage.isGranted) {
      return true;
    }

    // Try READ_EXTERNAL_STORAGE first (covers Android 10-12)
    status = await Permission.storage.request();
    if (status.isGranted) return true;

    // On Android 13+, storage permission is always denied — that's expected.
    // The Downloads folder is readable via MediaStore or direct path after
    // granting manageExternalStorage. Request it as fallback.
    status = await Permission.manageExternalStorage.request();
    return status.isGranted;
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await FlutterGemma.initialize();

      if (!FlutterGemma.hasActiveModel()) {
        // Request storage permission before accessing the file
        final hasPermission = await _requestStoragePermission();
        if (!hasPermission) {
          developer.log(
            'Storage permission denied — cannot load model from Downloads.',
            name: 'LlmService',
          );
          _isInitialized = true;
          return;
        }

        developer.log('Loading model from: $_modelPath', name: 'LlmService');

        await FlutterGemma.installModel(
          modelType: ModelType.gemmaIt,
          fileType: ModelFileType.task,
        ).fromFile(_modelPath).install();
      }

      _model = await FlutterGemma.getActiveModel(maxTokens: 1024);
      _chat = await _model!.createChat();

      _isInitialized = true;
      developer.log('FlutterGemma initialized.', name: 'LlmService');
    } catch (e) {
      developer.log('Failed to initialize: $e', name: 'LlmService');
      _isInitialized = true;
    }
  }

  Stream<String> getResponseStream(String prompt) async* {
    if (!_isInitialized) await initialize();

    if (_chat != null) {
      await _chat!.addQuery(Message.text(text: prompt, isUser: true));
      await for (final response in _chat!.generateChatResponseAsync()) {
        if (response is TextResponse) {
          yield response.token;
        }
      }
      return;
    }

    const msg =
        'Model not loaded. Please grant storage permission and restart the app.';
    for (final word in msg.split(' ')) {
      await Future.delayed(const Duration(milliseconds: 80));
      yield '$word ';
    }
  }

  Future<void> clearChat() async => _chat?.clearHistory();
}


// import 'dart:async';
// import 'dart:developer' as developer;
// import 'package:flutter_gemma/flutter_gemma.dart';
//
// class LlmService {
//   LlmService._internal();
//   static final LlmService _instance = LlmService._internal();
//   factory LlmService() => _instance;
//
//   bool _isInitialized = false;
//   // ignore: unused_field
//   InferenceModel? _model;
//   InferenceChat? _chat;
//
//   /// Initializes the Gemma LLM instance.
//   /// If the model file is not found, it gracefully falls back to mock mode
//   /// so the POC UI can still function.
//   Future<void> initialize() async {
//     if (_isInitialized) return;
//
//     try {
//       // ---------------------------------------------------------
//       // TO INTEGRATE YOUR DOWNLOADED MODEL, UNCOMMENT THIS BLOCK:
//       // ---------------------------------------------------------
//       //
//       // 1. Initialize the plugin
//       await FlutterGemma.initialize();
//
//       // 2. Install the model from your assets if not already active
//       if (!FlutterGemma.hasActiveModel()) {
//         await FlutterGemma.installModel(
//           modelType: ModelType.gemmaIt,
//         ).fromAsset('assets/models/gemma-4-E2B-it.litertlm').install();
//       }
//
//       // 3. Get the active model instance for chatting
//       _model = await FlutterGemma.getActiveModel(maxTokens: 1024);
//       // Create the chat session once and reuse it
//       _chat = await _model!.createChat(
//         fileType: ModelFileType.task, // covers .litertlm
//       );
//       _isInitialized = true;
//       return;
//       // ---------------------------------------------------------
//
//       developer.log(
//         'Falling back to Mock LLM Mode for POC.',
//         name: 'LlmService',
//       );
//       _isInitialized = true;
//     } catch (e) {
//       developer.log(
//         'Failed to initialize FlutterGemma: $e',
//         name: 'LlmService',
//       );
//       _isInitialized = true;
//     }
//   }
//
//   /// Sends a prompt to the LLM and streams the response back.
//   Stream<String> getResponseStream(String prompt) async* {
//     if (!_isInitialized) {
//       await initialize();
//     }
//
//     // ---------------------------------------------------------
//     // TO USE THE REAL MODEL STREAM, UNCOMMENT THIS BLOCK:
//     // ---------------------------------------------------------
//     if (_model != null) {
//       final chat = await _model!.createChat();
//       yield* chat.sendMessageStream(prompt);
//       return;
//     }
//     // ---------------------------------------------------------
//
//     // Yield a simulated mock response word by word
//     final mockResponse =
//         'Mock LLM Response: I received your prompt - "$prompt". Once the actual Gemma model file is added, this will be a real response.';
//     final mockWords = mockResponse.split(' ');
//
//     for (final word in mockWords) {
//       await Future.delayed(const Duration(milliseconds: 100));
//       yield '$word ';
//     }
//   }
// }
