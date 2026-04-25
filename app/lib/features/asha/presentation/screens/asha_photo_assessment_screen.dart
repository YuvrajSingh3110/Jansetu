import 'package:flutter/material.dart';
import 'package:jansetu/features/asha/presentation/asha_navigation.dart';
import 'package:jansetu/features/asha/presentation/widgets/asha_scaffold.dart';
import 'package:jansetu/sync_queue.dart';

class AshaPhotoAssessmentScreen extends StatelessWidget {
  const AshaPhotoAssessmentScreen({super.key});

  Future<void> _queueAssessment(BuildContext context) async {
    await SyncQueue.queueReport(
      type: 'photo_assessment',
      payload: const {
        'condition': 'possible_measles',
        'confidence': 'high',
        'recommendation': 'refer_phc',
        'nutrition_flag': 'muac_check_under_5',
      },
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Photo assessment added to report queue.')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AshaScaffold(
      title: 'Photo assessment',
      subtitle: 'E4B vision - on device',
      activeTab: AshaTab.home,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFD0D8E2)),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.photo_camera_outlined,
                    size: 34,
                    color: Color(0xFF7B8596),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Take or upload photo',
                    style: TextStyle(
                      fontSize: 18,
                      color: Color(0xFF697587),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _AssessmentCard(
              title: 'Assessment result',
              background: const Color(0xFFFCE8E8),
              titleColor: const Color(0xFFAA3D3D),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Maculopapular rash on torso,',
                    style: _detailStyle,
                  ),
                  Text(
                    'pattern consistent with measles.',
                    style: _detailStyle,
                  ),
                  SizedBox(height: 10),
                  Text('High confidence.', style: _detailStyle),
                  SizedBox(height: 14),
                  Text('Possible measles', style: _highlightStyle),
                  SizedBox(height: 8),
                  Text(
                    'Refer to PHC - Notify block officer',
                    style: _highlightStyle,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _AssessmentCard(
              title: '',
              background: const Color(0xFFF8EFD8),
              titleColor: const Color(0xFF7A5B00),
              child: const Text(
                'Malnutrition indicators not detected. MUAC check recommended for children under 5.',
                style: TextStyle(
                  fontSize: 18,
                  height: 1.45,
                  color: Color(0xFF6E570C),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 50),
                      foregroundColor: const Color(0xFF374355),
                      side: const BorderSide(color: Color(0xFFD7DDE7)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Retake'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _queueAssessment(context),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 50),
                      backgroundColor: const Color(0xFF0E7B60),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Add to report'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AssessmentCard extends StatelessWidget {
  const _AssessmentCard({
    required this.title,
    required this.background,
    required this.titleColor,
    required this.child,
  });

  final String title;
  final Color background;
  final Color titleColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: titleColor,
                ),
              ),
            ),
          child,
        ],
      ),
    );
  }
}

const TextStyle _detailStyle = TextStyle(
  fontSize: 18,
  height: 1.45,
  color: Color(0xFFA63D3D),
);

const TextStyle _highlightStyle = TextStyle(
  fontSize: 17,
  fontWeight: FontWeight.w600,
  color: Color(0xFF9B3030),
);
