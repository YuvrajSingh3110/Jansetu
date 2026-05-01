import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:jansetu/core/services/llm_service.dart';

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

  Future<PhotoAssessmentResult> analyzeImage(String imagePath) async {
    final metrics = await _extractImageMetrics(imagePath);
    final heuristic = _deriveHeuristic(metrics);

    final prompt = '''
You are assisting an ASHA worker. This is not a definitive diagnosis.
Use the image-derived signals below to produce a short, cautious field summary.

Image signals:
- resolution: ${metrics.width}x${metrics.height}
- average red: ${metrics.avgRed.toStringAsFixed(1)}
- average green: ${metrics.avgGreen.toStringAsFixed(1)}
- average blue: ${metrics.avgBlue.toStringAsFixed(1)}
- red dominance: ${metrics.redDominance.toStringAsFixed(3)}
- yellow score: ${metrics.yellowScore.toStringAsFixed(3)}
- contrast score: ${metrics.contrast.toStringAsFixed(3)}
- texture score: ${metrics.textureScore.toStringAsFixed(3)}
- heuristic finding: ${heuristic.finding}
- recommended action: ${heuristic.recommendation}
- candidate symptoms: ${heuristic.symptoms.join(', ')}

Return exactly:
Summary: <1 cautious sentence for the worker>
Note: <1 short practical note>
''';

    var summary = 'Image captured. Reviewing visible skin features.';
    var extraNote = heuristic.recommendation;

    try {
      final responseStream = _llmService.getResponseStream(prompt);
      final fullResponse = await responseStream.join('');
      final summaryMatch = RegExp(r'Summary:\s*(.*)').firstMatch(fullResponse);
      final noteMatch = RegExp(r'Note:\s*(.*)').firstMatch(fullResponse);

      if (summaryMatch != null && summaryMatch.group(1)!.trim().isNotEmpty) {
        summary = summaryMatch.group(1)!.trim();
      }
      if (noteMatch != null && noteMatch.group(1)!.trim().isNotEmpty) {
        extraNote = noteMatch.group(1)!.trim();
      }
    } catch (_) {
      summary = 'Image review suggests ${heuristic.finding.toLowerCase()}.';
      extraNote = 'Gemma guidance unavailable. ${heuristic.recommendation}';
    }

    return PhotoAssessmentResult(
      title: 'ASHA AI Assessment',
      summary: summary,
      primaryFinding: heuristic.finding,
      recommendation: heuristic.recommendation,
      extraNote: extraNote,
      extraSymptoms: heuristic.symptoms,
      severity: heuristic.severity,
      requiresReferral: heuristic.requiresReferral,
    );
  }

  Future<_ImageMetrics> _extractImageMetrics(String imagePath) async {
    final bytes = await File(imagePath).readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final byteData =
        await image.toByteData(format: ui.ImageByteFormat.rawRgba);
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
      contrast: ((avgRed - avgBlue).abs() + (avgGreen - avgBlue).abs()) /
          avgOverall,
      textureScore: highContrastPixels / pixelCount,
    );
  }

  _HeuristicFinding _deriveHeuristic(_ImageMetrics metrics) {
    if (metrics.redDominance > 0.12 && metrics.textureScore > 0.18) {
      return const _HeuristicFinding(
        finding: 'Inflammatory rash-like pattern',
        recommendation: 'Refer to PHC if fever, breathing issues, or spreading rash are present.',
        symptoms: ['rash', 'fever'],
        severity: 'moderate',
        requiresReferral: true,
      );
    }

    if (metrics.yellowScore > 0.22) {
      return const _HeuristicFinding(
        finding: 'Yellow-toned discoloration visible',
        recommendation: 'Check eyes/skin clinically and monitor for jaundice symptoms.',
        symptoms: ['jaundice'],
        severity: 'moderate',
        requiresReferral: false,
      );
    }

    if (metrics.contrast > 0.18 && metrics.textureScore > 0.24) {
      return const _HeuristicFinding(
        finding: 'Surface lesion or wound-like contrast area',
        recommendation: 'Cleanly document the lesion and escalate if swelling, pus, or fever is present.',
        symptoms: ['bleeding'],
        severity: 'mild',
        requiresReferral: false,
      );
    }

    return const _HeuristicFinding(
      finding: 'Non-specific skin surface concern',
      recommendation: 'Document symptoms, retake in better light if unclear, and follow local escalation rules.',
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
