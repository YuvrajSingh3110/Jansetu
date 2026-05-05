import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:jansetu/core/storage/secure_storage_service.dart';
import 'package:jansetu/core/services/model_download_service.dart';

class LlmService {
  LlmService._internal();
  static final LlmService _instance = LlmService._internal();
  factory LlmService() => _instance;

  bool _isInitialized = false;
  bool _isModelMissing = false;
  InferenceModel? _model;
  InferenceChat? _chat;
  bool _chatSupportsImages = false;

  bool get isModelMissing => _isModelMissing;

  static const String _jansetuInstruction = '''
You are Jansetu's on-device epidemiological extraction model.
You convert community health worker or villager speech transcripts into compact disease-surveillance signals.
Privacy is mandatory: never output names, phone numbers, Aadhaar numbers, exact addresses, household identifiers, or other personal identifiers.
Normalize symptoms to short English tokens.
Prefer conservative extraction over guessing.
Keep responses brief.
Do not use markdown, bullets, *, #, or tables.
Return plain text only.
If the input is unclear, say what is uncertain briefly instead of inventing details.
''';

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await FlutterGemma.initialize();

      if (!FlutterGemma.hasActiveModel()) {
        final isDownloaded = await ModelDownloadService().isModelDownloaded();
        if (!isDownloaded) {
          _isModelMissing = true;
          _isInitialized = true;
          return;
        }

        final modelPath = await ModelDownloadService().getModelPath();
        developer.log('Loading model from: $modelPath', name: 'LlmService');

        await FlutterGemma.installModel(
          modelType: ModelType.gemmaIt,
          fileType: ModelFileType.task,
        ).fromFile(modelPath).install();
      }

      _isModelMissing = false;
      _isInitialized = true;
      developer.log('FlutterGemma initialized.', name: 'LlmService');
    } catch (e) {
      developer.log('Failed to initialize: $e', name: 'LlmService');
      _isModelMissing = true;
      _isInitialized = true;
    }
  }

  Future<void> _ensureChat({required bool supportImage}) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_chat != null && _model != null && _chatSupportsImages == supportImage) {
      return;
    }

    if (_chat != null) {
      await _chat!.clearHistory();
      _chat = null;
    }

    if (_model != null) {
      await _model!.close();
      _model = null;
    }

    _model = await FlutterGemma.getActiveModel(
      maxTokens: 1024,
      supportImage: supportImage,
      maxNumImages: supportImage ? 1 : null,
    );
    _chat = await _model!.createChat(
      supportImage: supportImage,
    );
    _chatSupportsImages = supportImage;

    developer.log(
      'Created Gemma chat session. supportImage=$supportImage',
      name: 'LlmService',
    );
  }

  Stream<String> getResponseStream(Message prompt) async* {
    if (!_isInitialized) await initialize();

    try {
      final requiresImage = prompt.hasImage;
      await _ensureChat(supportImage: requiresImage);

      Message finalPrompt = prompt;
      if (prompt.hasImage && prompt.imageBytes != null) {
        final processed = await MultimodalImageHandler.processImageForAI(
          imageBytes: prompt.imageBytes!,
          modelType: ModelType.gemmaIt,
        );

        if (!processed.success || processed.processedImage == null) {
          final msg = processed.error?.message ??
              'The selected image could not be prepared for the model.';
          for (final word in msg.split(' ')) {
            await Future.delayed(const Duration(milliseconds: 40));
            yield '$word ';
          }
          return;
        }

        finalPrompt = MultimodalImageHandler.createMultimodalMessage(
          text: _buildGuidedPrompt(
            prompt.text.trim().isEmpty
                ? 'Describe what you see in this image for disease surveillance.'
                : prompt.text,
          ),
          processedImage: processed.processedImage!,
          modelType: ModelType.gemmaIt,
          isUser: true,
        );
      } else {
        finalPrompt = Message.text(
          text: _buildGuidedPrompt(prompt.text),
          isUser: prompt.isUser,
        );
      }

      if (_chat == null) {
        const msg = 'Model session could not be created.';
        for (final word in msg.split(' ')) {
          await Future.delayed(const Duration(milliseconds: 40));
          yield '$word ';
        }
        return;
      }

      await _chat!.addQuery(finalPrompt);
      await for (final response in _chat!.generateChatResponseAsync()) {
        if (response is TextResponse) {
          yield response.token;
        }
      }
      return;
    } catch (error, stackTrace) {
      developer.log(
        'Multimodal/text inference failed: $error',
        name: 'LlmService',
        stackTrace: stackTrace,
      );
      final fallback = prompt.hasImage
          ? 'Image processing failed in the current Gemma session. The model may support images, but this app could not open a stable multimodal session for that photo.'
          : 'The model session failed while generating a response.';
      for (final word in fallback.split(' ')) {
        await Future.delayed(const Duration(milliseconds: 40));
        yield '$word ';
      }
    }
  }

  Future<void> clearChat() async {
    await _chat?.clearHistory();
  }

  Future<String> getSummary(String userMessage) async {
    if (!_isInitialized) await initialize();
    if (_model == null) {
      await _ensureChat(supportImage: false);
    }
    if (_model == null) return 'Chat Session';

    try {
      final summaryChat = await _model!.createChat(supportImage: false);
      final promptMsg = Message.text(
        text: 'Summarize the following in 3 to 6 words only (no formatting or quotes): $userMessage',
        isUser: true,
      );
      await summaryChat.addQuery(promptMsg);
      
      String responseText = '';
      await for (final response in summaryChat.generateChatResponseAsync()) {
        if (response is TextResponse) {
          responseText += response.token;
        }
      }
      
      return responseText.trim().isNotEmpty ? responseText.trim() : 'Chat Session';
    } catch (e) {
      return 'Chat Session';
    }
  }

  Future<Map<String, dynamic>?> extractReport(String chatHistory) async {
    if (!_isInitialized) await initialize();
    if (_model == null) {
      await _ensureChat(supportImage: false);
    }
    if (_model == null) return null;

    try {
      final extractChat = await _model!.createChat(supportImage: false);
      const instruction = '''
You are Jansetu's on-device epidemiological extraction model.
You must extract the health symptoms discussed in this chat into a strictly formatted JSON object.
Use ONLY the following symptom codes: fever, cough, breathlessness, diarrhoea, vomiting, rash, headache, bodyache, sore_throat, runny_nose, malnutrition, jaundice, conjunctivitis, seizure, unconscious, bleeding.
Do not use any other symptom strings.

Output exactly a JSON object in this format (no markdown formatting, no comments):
{
  "villageId": "clv001rampur",
  "ageGroup": "adult", 
  "gender": "unknown",
  "symptoms": ["fever", "cough"],
  "duration": null,
  "severity": "mild",
  "referral": false
}
If age group is unknown use "adult". For gender use "M", "F", or "unknown".
For severity use "mild", "moderate", or "severe".
Use the default values shown above if the actual values are not present in the chat.
Strip all names and personal identifiers.
''';
      
      final promptMsg = Message.text(
        text: '$instruction\n\nChat history to extract:\n$chatHistory',
        isUser: true,
      );
      
      await extractChat.addQuery(promptMsg);
      String responseText = '';
      await for (final response in extractChat.generateChatResponseAsync()) {
        if (response is TextResponse) {
          responseText += response.token;
        }
      }
      
      // Basic JSON parsing to handle possible markdown wrapping
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(responseText);
      if (jsonMatch != null) {
        final Map<String, dynamic> parsed = Map<String, dynamic>.from(
          jsonDecode(jsonMatch.group(0)!) as Map<dynamic, dynamic>,
        );
        parsed['reportedAt'] = DateTime.now().toUtc().toIso8601String();
        parsed['hasPhoto'] = false; // Always false for now

        // Fetch from local storage if missing/unknown and user is villager
        final storage = SecureStorageService();
        final role = await storage.readUserRole();
        if (role == 'villager') {
          if (parsed['gender'] == 'unknown' || parsed['gender'] == null) {
            final storedGender = await storage.readGender();
            if (storedGender != null) {
              parsed['gender'] = storedGender.startsWith('M') ? 'M' : 'F';
            }
          }
          if (parsed['ageGroup'] == 'unknown' || parsed['ageGroup'] == null) {
            final storedAge = await storage.readAge();
            if (storedAge != null) {
              if (storedAge < 18) {
                parsed['ageGroup'] = 'child';
              } else if (storedAge >= 60) {
                parsed['ageGroup'] = 'elderly';
              } else {
                parsed['ageGroup'] = 'adult';
              }
            }
          }
        }

        return parsed;
      }
      return null;
    } catch (e) {
      developer.log('Extraction failed: $e', name: 'LlmService');
      return null;
    }
  }

  String _buildGuidedPrompt(String userPrompt) {
    final cleanedPrompt = userPrompt.trim();
    return '$_jansetuInstruction\n\nUser input:\n$cleanedPrompt';
  }
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
