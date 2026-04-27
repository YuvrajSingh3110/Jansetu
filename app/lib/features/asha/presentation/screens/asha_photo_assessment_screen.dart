import 'package:flutter/material.dart';
import 'package:jansetu/features/asha/data/asha_repository.dart';
import 'package:jansetu/features/photo/presentation/screens/photo_assessment_screen.dart';
import 'package:jansetu/sync_queue.dart';

class AshaPhotoAssessmentScreen extends StatelessWidget {
  const AshaPhotoAssessmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = AshaRepository();
    return PhotoAssessmentScreen(
      title: 'Photo assessment',
      subtitle: 'Shared ASHA and village photo pipeline',
      saveButtonLabel: 'Add to report',
      onSave: (imagePath, result) async {
        final payload = await repository.buildReportPayload(
          transcript:
              '${result.primaryFinding}. ${result.summary}. ${result.recommendation}',
          hasPhoto: true,
          forceReferral: result.requiresReferral,
          extraSymptoms: result.extraSymptoms,
        );
        await SyncQueue.queueReport(
          type: 'chw_report',
          payload: payload,
          localImagePath: imagePath,
        );
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo assessment added to report queue.')),
        );
        Navigator.of(context).pop();
      },
    );
  }
}
