import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:permission_handler/permission_handler.dart';

class LlmService {
  LlmService._internal();
  static final LlmService _instance = LlmService._internal();
  factory LlmService() => _instance;

  static const String preferredModelPath =
      '/storage/emulated/0/Download/gemma-4-E2B-it.litertlm';
  static const List<String> _candidateModelPaths = [
    preferredModelPath,
    '/sdcard/Download/gemma-4-E2B-it.litertlm',
    '/storage/emulated/0/Android/data/com.example.jansetu/files/models/gemma-4-E2B-it.litertlm',
    '/sdcard/Android/data/com.example.jansetu/files/models/gemma-4-E2B-it.litertlm',
  ];

  bool _runtimeInitialized = false;
  bool _modelReady = false;
  InferenceModel? _model;
  InferenceChat? _chat;
  bool _chatSupportsImages = false;
  String? _activeModelPath;
  String? _lastInitializationIssue;

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

  String? get lastInitializationIssue => _lastInitializationIssue;
  String? get activeModelPath => _activeModelPath;

  Future<bool> _requestStoragePermission() async {
    if (await Permission.manageExternalStorage.isGranted) {
      return true;
    }

    final storageStatus = await Permission.storage.request();
    if (storageStatus.isGranted) {
      return true;
    }

    final manageStatus = await Permission.manageExternalStorage.request();
    return manageStatus.isGranted;
  }

  Future<String?> resolveModelPath() async {
    for (final candidate in _candidateModelPaths) {
      final file = File(candidate);
      if (await file.exists()) {
        return candidate;
      }
    }
    return null;
  }

  Future<String?> _getRegisteredActiveModelPath() async {
    final activeSpec =
        FlutterGemmaPlugin.instance.modelManager.activeInferenceModel;
    if (activeSpec == null) {
      return null;
    }
    final filePaths = await FlutterGemmaPlugin.instance.modelManager
        .getModelFilePaths(activeSpec);
    if (filePaths == null || filePaths.isEmpty) {
      return null;
    }
    return filePaths.values.first;
  }

  Future<void> _disposeSession() async {
    if (_chat != null) {
      await _chat!.clearHistory();
      _chat = null;
    }

    if (_model != null) {
      await _model!.close();
      _model = null;
    }

    _chatSupportsImages = false;
  }

  Future<void> initialize({bool forceReload = false}) async {
    if (_modelReady && !forceReload) {
      return;
    }

    if (!_runtimeInitialized) {
      await FlutterGemma.initialize();
      _runtimeInitialized = true;
    }

    final hasPermission = await _requestStoragePermission();
    if (!hasPermission) {
      _lastInitializationIssue =
          'Storage permission denied. JanSetu cannot read the Gemma model in Downloads.';
      throw StateError(_lastInitializationIssue!);
    }

    final resolvedPath = await resolveModelPath();
    if (resolvedPath == null) {
      _lastInitializationIssue =
          'Gemma model not found. Expected it at $preferredModelPath.';
      throw StateError(_lastInitializationIssue!);
    }

    final registeredActivePath = await _getRegisteredActiveModelPath();
    final needsReinstall =
        forceReload ||
        !_modelReady ||
        !FlutterGemma.hasActiveModel() ||
        registeredActivePath != resolvedPath;

    if (needsReinstall) {
      developer.log(
        'Activating Gemma model from $resolvedPath (previous active: ${registeredActivePath ?? 'none'})',
        name: 'LlmService',
      );
      await _disposeSession();
      await FlutterGemma.installModel(
        modelType: ModelType.gemmaIt,
        fileType: ModelFileType.task,
      ).fromFile(resolvedPath).install();
    } else {
      developer.log(
        'Reusing active Gemma model at $resolvedPath',
        name: 'LlmService',
      );
    }

    _activeModelPath = resolvedPath;
    _lastInitializationIssue = null;
    _modelReady = true;
  }

  Future<void> _ensureChat({required bool supportImage}) async {
    await initialize();

    if (_chat != null &&
        _model != null &&
        _chatSupportsImages == supportImage) {
      return;
    }

    await _disposeSession();

    _model = await FlutterGemma.getActiveModel(
      maxTokens: 1024,
      supportImage: supportImage,
      maxNumImages: supportImage ? 1 : null,
    );
    _chat = await _model!.createChat(supportImage: supportImage);
    _chatSupportsImages = supportImage;

    developer.log(
      'Created Gemma chat session. supportImage=$supportImage path=$_activeModelPath',
      name: 'LlmService',
    );
  }

  Stream<String> getResponseStream(Message prompt) async* {
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
          final msg =
              processed.error?.message ??
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
        throw StateError('Model session could not be created.');
      }

      await _chat!.addQuery(finalPrompt);
      await for (final response in _chat!.generateChatResponseAsync()) {
        if (response is TextResponse) {
          yield response.token;
        }
      }
    } catch (error, stackTrace) {
      developer.log(
        'Multimodal/text inference failed: $error',
        name: 'LlmService',
        stackTrace: stackTrace,
      );
      final fallback = prompt.hasImage
          ? 'Image processing failed in the current Gemma session. ${_lastInitializationIssue ?? 'Try retaking the image with clearer lighting.'}'
          : _lastInitializationIssue ??
                'The model session failed while generating a response.';
      for (final word in fallback.split(' ')) {
        await Future.delayed(const Duration(milliseconds: 40));
        yield '$word ';
      }
    }
  }

  Future<void> clearChat() async {
    await _chat?.clearHistory();
  }

  String _buildGuidedPrompt(String userPrompt) {
    final cleanedPrompt = userPrompt.trim();
    return '$_jansetuInstruction\n\nUser input:\n$cleanedPrompt';
  }
}
