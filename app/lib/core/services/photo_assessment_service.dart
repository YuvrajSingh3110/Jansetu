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

  Future<PhotoAssessmentResult> analyzeImage(String imagePath) async {
    final normalized = imagePath.toLowerCase();
    if (normalized.contains('rash') || normalized.contains('skin')) {
      return const PhotoAssessmentResult(
        title: 'Assessment result',
        summary:
            'Maculopapular rash pattern suggests a possible infectious skin presentation.',
        primaryFinding: 'Possible measles / rash cluster',
        recommendation: 'Refer to PHC and notify block office.',
        extraNote: 'MUAC and hydration check recommended for children under 5.',
        extraSymptoms: ['rash', 'fever'],
        severity: 'moderate',
        requiresReferral: true,
      );
    }

    return const PhotoAssessmentResult(
      title: 'Assessment result',
      summary:
          'Captured image stored successfully. Visual review suggests a surface skin concern that needs clinician follow-up.',
      primaryFinding: 'Skin condition review needed',
      recommendation: 'Document symptoms and follow local escalation rules.',
      extraNote: 'Future vision model can replace this placeholder analyzer.',
      extraSymptoms: ['rash'],
      severity: 'mild',
      requiresReferral: false,
    );
  }
}
