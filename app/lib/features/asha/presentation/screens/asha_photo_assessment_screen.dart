import 'package:easy_localization/easy_localization.dart';
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
      title: 'ashaPhotoTitle'.tr(),
      subtitle: 'ashaPhotoSubtitle'.tr(),
      saveButtonLabel: 'ashaPhotoAddToReport'.tr(),
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
          SnackBar(content: Text('ashaPhotoQueued'.tr())),
        );
        Navigator.of(context).pop();
      },
    );
  }
}
