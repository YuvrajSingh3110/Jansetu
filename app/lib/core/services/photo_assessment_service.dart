import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:jansetu/core/services/health_language_service.dart';
import 'package:jansetu/core/services/llm_service.dart';
import 'package:jansetu/features/onboarding/domain/models/app_language.dart';

class PhotoAssessmentResult {
  const PhotoAssessmentResult({
    required this.title,
    required this.summary,
    required this.primaryFinding,
    required this.recommendation,
    required this.extraNote,
    required this.extraSymptoms,
    required this.severity,
    required this.requiresReferral,
  });

  final String title;
  final String summary;
  final String primaryFinding;
  final String recommendation;
  final String extraNote;
  final List<String> extraSymptoms;
  final String severity;
  final bool requiresReferral;
}

class PhotoAssessmentService {
  PhotoAssessmentService._internal();

  static final PhotoAssessmentService _instance =
      PhotoAssessmentService._internal();

  factory PhotoAssessmentService() => _instance;

  final LlmService _llmService = LlmService();

  static const Map<String, String> _symptomAliases = {
    'fever': 'fever',
    'cough': 'cough',
    'breathlessness': 'breathlessness',
    'shortness of breath': 'breathlessness',
    'diarrhoea': 'diarrhoea',
    'diarrhea': 'diarrhoea',
    'vomiting': 'vomiting',
    'rash': 'rash',
    'headache': 'headache',
    'body ache': 'bodyache',
    'bodyache': 'bodyache',
    'sore throat': 'sore_throat',
    'runny nose': 'runny_nose',
    'malnutrition': 'malnutrition',
    'jaundice': 'jaundice',
    'conjunctivitis': 'conjunctivitis',
    'seizure': 'seizure',
    'unconscious': 'unconscious',
    'bleeding': 'bleeding',
  };

  Future<PhotoAssessmentResult> analyzeImage(
    String imagePath, {
    AppLanguage? language,
  }) async {
    final imageBytes = await File(imagePath).readAsBytes();
    final metrics = await _extractImageMetrics(imagePath);
    final heuristic = _deriveHeuristic(metrics);
    final localeCode = language?.localeCode ?? 'en';
    final targetLanguage = HealthLanguageService.promptLanguageInstruction(
      language,
    );

    final prompt =
        '''
You are assisting an ASHA worker with a field image.
Look at the image first. If the image is unclear, say so directly instead of guessing.
Do not identify a person. Do not give a definitive diagnosis.
Write all worker-facing text in $targetLanguage.
Return symptom codes only in English from this set when visible:
fever, cough, breathlessness, diarrhoea, vomiting, rash, headache, bodyache, sore_throat, runny_nose, malnutrition, jaundice, conjunctivitis, seizure, unconscious, bleeding.

Return exactly:
Summary: <1 cautious sentence describing what is visible and relevant in $targetLanguage>
Finding: <short visible finding or "unclear image" in $targetLanguage>
Symptoms: <comma-separated symptom codes if visible, otherwise "unclear">
Severity: <mild/moderate/severe>
Referral: <yes/no>
Note: <1 short practical next step for the worker in $targetLanguage>
''';

    var summary = HealthLanguageService.fallbackSummary(localeCode, []);
    var primaryFinding = heuristic.finding;
    var extraSymptoms = List<String>.from(heuristic.symptoms);
    var recommendation = HealthLanguageService.fallbackSuggestion(
      localeCode,
      extraSymptoms,
      urgent: heuristic.requiresReferral,
    );
    var extraNote = '';
    var severity = heuristic.severity;
    var requiresReferral = heuristic.requiresReferral;

    try {
      final responseStream = _llmService.getResponseStream(
        Message.withImage(text: prompt, imageBytes: imageBytes, isUser: true),
      );
      final fullResponse = await responseStream.join('');
      final summaryMatch = RegExp(r'Summary:\s*(.*)').firstMatch(fullResponse);
      final findingMatch = RegExp(r'Finding:\s*(.*)').firstMatch(fullResponse);
      final symptomsMatch = RegExp(
        r'Symptoms:\s*(.*)',
      ).firstMatch(fullResponse);
      final severityMatch = RegExp(
        r'Severity:\s*(.*)',
      ).firstMatch(fullResponse);
      final referralMatch = RegExp(
        r'Referral:\s*(.*)',
      ).firstMatch(fullResponse);
      final noteMatch = RegExp(r'Note:\s*(.*)').firstMatch(fullResponse);

      if (summaryMatch != null && summaryMatch.group(1)!.trim().isNotEmpty) {
        summary = summaryMatch.group(1)!.trim();
      }
      if (findingMatch != null && findingMatch.group(1)!.trim().isNotEmpty) {
        primaryFinding = findingMatch.group(1)!.trim();
      }
      final parsedSymptoms = _parseSymptoms(symptomsMatch?.group(1));
      if (parsedSymptoms.isNotEmpty) {
        extraSymptoms = parsedSymptoms;
      }
      final parsedSeverity = _parseSeverity(severityMatch?.group(1));
      if (parsedSeverity != null) {
        severity = parsedSeverity;
      }
      final parsedReferral = _parseReferral(referralMatch?.group(1));
      if (parsedReferral != null) {
        requiresReferral = parsedReferral;
      }
      final localizedGuidance = await _localizePhotoGuidance(
        selectedLanguage: language,
        symptoms: extraSymptoms,
        finding: primaryFinding,
        severity: severity,
        requiresReferral: requiresReferral,
        summaryHint: summaryMatch?.group(1)?.trim() ?? summary,
        noteHint: noteMatch?.group(1)?.trim(),
      );
      summary =
          HealthLanguageService.prefersFallbackForLocale(
            localeCode,
            localizedGuidance.$1,
          )
          ? HealthLanguageService.fallbackSummary(localeCode, extraSymptoms)
          : (localizedGuidance.$1 ??
                HealthLanguageService.fallbackSummary(
                  localeCode,
                  extraSymptoms,
                ));
      recommendation =
          HealthLanguageService.prefersFallbackForLocale(
            localeCode,
            localizedGuidance.$2,
          )
          ? HealthLanguageService.fallbackSuggestion(
              localeCode,
              extraSymptoms,
              urgent: requiresReferral,
            )
          : (localizedGuidance.$2 ??
                HealthLanguageService.fallbackSuggestion(
                  localeCode,
                  extraSymptoms,
                  urgent: requiresReferral,
                ));
      extraNote =
          HealthLanguageService.prefersFallbackForLocale(
            localeCode,
            localizedGuidance.$3,
          )
          ? ''
          : (localizedGuidance.$3 ?? '');
    } catch (_) {
      summary = HealthLanguageService.fallbackSummary(
        localeCode,
        extraSymptoms,
      );
      recommendation = HealthLanguageService.fallbackSuggestion(
        localeCode,
        extraSymptoms,
        urgent: requiresReferral,
      );
      extraNote = '';
    }

    return PhotoAssessmentResult(
      title: 'ASHA AI Assessment',
      summary: summary,
      primaryFinding: primaryFinding,
      recommendation: recommendation,
      extraNote: extraNote,
      extraSymptoms: extraSymptoms,
      severity: severity,
      requiresReferral: requiresReferral,
    );
  }

  Future<(String?, String?, String?)> _localizePhotoGuidance({
    required AppLanguage? selectedLanguage,
    required List<String> symptoms,
    required String finding,
    required String severity,
    required bool requiresReferral,
    required String summaryHint,
    String? noteHint,
  }) async {
    final languageInstruction = HealthLanguageService.promptLanguageInstruction(
      selectedLanguage,
    );
    final prompt =
        '''
Create worker-facing guidance for an ASHA worker from a photo assessment.
Write only in $languageInstruction.
Do not use English unless the language itself is English.

Detected symptom codes:
${symptoms.isEmpty ? 'unclear' : symptoms.join(', ')}
Finding:
$finding
Severity: $severity
Referral needed: ${requiresReferral ? 'yes' : 'no'}
Summary hint: $summaryHint
Note hint: ${noteHint ?? 'none'}

Return exactly:
Summary: <one short visible summary in $languageInstruction>
Suggestion: <one direct action for the ASHA worker in $languageInstruction>
Note: <one short supporting note in $languageInstruction>
''';
    try {
      final response = await _llmService
          .getResponseStream(Message.text(text: prompt, isUser: true))
          .join('');
      return (
        RegExp(r'Summary:\s*(.*)').firstMatch(response)?.group(1)?.trim(),
        RegExp(r'Suggestion:\s*(.*)').firstMatch(response)?.group(1)?.trim(),
        RegExp(r'Note:\s*(.*)').firstMatch(response)?.group(1)?.trim(),
      );
    } catch (_) {
      return (null, null, null);
    }
  }

  List<String> _parseSymptoms(String? rawValue) {
    if (rawValue == null || rawValue.trim().isEmpty) {
      return const [];
    }

    final lower = rawValue.toLowerCase();
    if (lower.contains('unclear')) {
      return const [];
    }

    final matches = <String>{};
    for (final entry in _symptomAliases.entries) {
      if (lower.contains(entry.key)) {
        matches.add(entry.value);
      }
    }
    return matches.toList();
  }

  String? _parseSeverity(String? rawValue) {
    final lower = rawValue?.trim().toLowerCase();
    if (lower == null || lower.isEmpty) {
      return null;
    }
    if (lower.contains('severe')) return 'severe';
    if (lower.contains('moderate')) return 'moderate';
    if (lower.contains('mild')) return 'mild';
    return null;
  }

  bool? _parseReferral(String? rawValue) {
    final lower = rawValue?.trim().toLowerCase();
    if (lower == null || lower.isEmpty) {
      return null;
    }
    if (lower.startsWith('y')) return true;
    if (lower.startsWith('n')) return false;
    return null;
  }

  Future<_ImageMetrics> _extractImageMetrics(String imagePath) async {
    final bytes = await File(imagePath).readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (byteData == null) {
      return const _ImageMetrics.empty();
    }

    final rgba = byteData.buffer.asUint8List();
    var redSum = 0.0;
    var greenSum = 0.0;
    var blueSum = 0.0;
    var yellowPixels = 0;
    var highContrastPixels = 0;

    final pixelCount = math.max(1, rgba.length ~/ 4);

    for (var offset = 0; offset < rgba.length; offset += 4) {
      final red = rgba[offset].toDouble();
      final green = rgba[offset + 1].toDouble();
      final blue = rgba[offset + 2].toDouble();

      redSum += red;
      greenSum += green;
      blueSum += blue;

      if (red > 120 && green > 100 && blue < 110) {
        yellowPixels += 1;
      }

      final contrast = (red - green).abs() + (red - blue).abs();
      if (contrast > 120) {
        highContrastPixels += 1;
      }
    }

    final avgRed = redSum / pixelCount;
    final avgGreen = greenSum / pixelCount;
    final avgBlue = blueSum / pixelCount;
    final avgOverall = math.max(1, avgRed + avgGreen + avgBlue);

    return _ImageMetrics(
      width: image.width,
      height: image.height,
      avgRed: avgRed,
      avgGreen: avgGreen,
      avgBlue: avgBlue,
      redDominance: (avgRed - math.max(avgGreen, avgBlue)) / 255,
      yellowScore: yellowPixels / pixelCount,
      contrast:
          ((avgRed - avgBlue).abs() + (avgGreen - avgBlue).abs()) / avgOverall,
      textureScore: highContrastPixels / pixelCount,
    );
  }

  _HeuristicFinding _deriveHeuristic(_ImageMetrics metrics) {
    if (metrics.redDominance > 0.12 && metrics.textureScore > 0.18) {
      return const _HeuristicFinding(
        finding: 'Inflammatory rash-like pattern',
        recommendation:
            'Refer to PHC if fever, breathing issues, or spreading rash are present.',
        symptoms: ['rash', 'fever'],
        severity: 'moderate',
        requiresReferral: true,
      );
    }

    if (metrics.yellowScore > 0.22) {
      return const _HeuristicFinding(
        finding: 'Yellow-toned discoloration visible',
        recommendation:
            'Check eyes or skin clinically and monitor for jaundice symptoms.',
        symptoms: ['jaundice'],
        severity: 'moderate',
        requiresReferral: false,
      );
    }

    if (metrics.contrast > 0.18 && metrics.textureScore > 0.24) {
      return const _HeuristicFinding(
        finding: 'Surface lesion or wound-like contrast area',
        recommendation:
            'Document the lesion and escalate if swelling, pus, or fever is present.',
        symptoms: ['bleeding'],
        severity: 'mild',
        requiresReferral: false,
      );
    }

    return const _HeuristicFinding(
      finding: 'Non-specific skin surface concern',
      recommendation:
          'Retake in better light if unclear and follow local escalation rules.',
      symptoms: ['rash'],
      severity: 'mild',
      requiresReferral: false,
    );
  }
}

class _ImageMetrics {
  const _ImageMetrics({
    required this.width,
    required this.height,
    required this.avgRed,
    required this.avgGreen,
    required this.avgBlue,
    required this.redDominance,
    required this.yellowScore,
    required this.contrast,
    required this.textureScore,
  });

  const _ImageMetrics.empty()
    : width = 0,
      height = 0,
      avgRed = 0,
      avgGreen = 0,
      avgBlue = 0,
      redDominance = 0,
      yellowScore = 0,
      contrast = 0,
      textureScore = 0;

  final int width;
  final int height;
  final double avgRed;
  final double avgGreen;
  final double avgBlue;
  final double redDominance;
  final double yellowScore;
  final double contrast;
  final double textureScore;
}

class _HeuristicFinding {
  const _HeuristicFinding({
    required this.finding,
    required this.recommendation,
    required this.symptoms,
    required this.severity,
    required this.requiresReferral,
  });

  final String finding;
  final String recommendation;
  final List<String> symptoms;
  final String severity;
  final bool requiresReferral;
}
