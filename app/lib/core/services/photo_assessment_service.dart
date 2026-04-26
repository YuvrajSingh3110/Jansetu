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
    final normalized = imagePath.toLowerCase();

    // In a production app with PaliGemma, we would pass the image bytes here.
    // For now, we simulate a multimodal response by using Gemma to "reason"
    // about the keyword-detected findings.

    String finding;
    String recommendation;
    List<String> symptoms;

    if (normalized.contains('rash') || normalized.contains('skin')) {
      finding = 'Maculopapular rash pattern';
      recommendation = 'Refer to PHC and notify block office.';
      symptoms = ['rash', 'fever'];
    } else {
      finding = 'Surface skin concern';
      recommendation = 'Document symptoms and follow local escalation rules.';
      symptoms = ['rash'];
    }

    final prompt = '''
Analyze these visual findings for a community health worker in rural India:
Finding: $finding
Recommendation: $recommendation
Symptoms detected: ${symptoms.join(', ')}

Please provide a structured 1-sentence summary of the assessment and a short extra note for the ASHA worker.
Format:
Summary: <sentence>
Note: <sentence>
''';

    String summary = 'Analyzing image...';
    String extraNote = 'Consulting Gemma model...';

    try {
      final responseStream = _llmService.getResponseStream(prompt);
      final fullResponse = await responseStream.join('');

      final summaryMatch = RegExp(r'Summary:\s*(.*)').firstMatch(fullResponse);
      final noteMatch = RegExp(r'Note:\s*(.*)').firstMatch(fullResponse);

      if (summaryMatch != null) summary = summaryMatch.group(1)!.trim();
      if (noteMatch != null) extraNote = noteMatch.group(1)!.trim();
    } catch (e) {
      summary = 'Image captured. Visual review suggests a $finding.';
      extraNote = 'Gemma analysis unavailable. $recommendation';
    }

    return PhotoAssessmentResult(
      title: 'ASHA AI Assessment',
      summary: summary,
      primaryFinding: finding,
      recommendation: recommendation,
      extraNote: extraNote,
      extraSymptoms: symptoms,
      severity: normalized.contains('rash') ? 'moderate' : 'mild',
      requiresReferral: normalized.contains('rash'),
    );
  }
}
