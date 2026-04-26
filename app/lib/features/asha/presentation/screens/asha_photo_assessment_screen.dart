import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jansetu/features/asha/data/asha_repository.dart';
import 'package:jansetu/features/asha/presentation/asha_navigation.dart';
import 'package:jansetu/features/asha/presentation/widgets/asha_scaffold.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:jansetu/sync_queue.dart';

class AshaPhotoAssessmentScreen extends StatefulWidget {
  const AshaPhotoAssessmentScreen({super.key});

  @override
  State<AshaPhotoAssessmentScreen> createState() => _AshaPhotoAssessmentScreenState();
}

class _AshaPhotoAssessmentScreenState extends State<AshaPhotoAssessmentScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  final AshaRepository _repository = AshaRepository();

  String? _savedImagePath;
  bool _isCapturing = false;
  bool _isSaving = false;

  Future<void> _captureImage() async {
    if (_isCapturing) return;
    setState(() => _isCapturing = true);
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 75,
      );
      if (picked == null || !mounted) return;

      final appDir = await getApplicationDocumentsDirectory();
      final photosDir = Directory(p.join(appDir.path, 'report_photos'));
      if (!await photosDir.exists()) {
        await photosDir.create(recursive: true);
      }

      final targetPath = p.join(
        photosDir.path,
        'photo_${DateTime.now().millisecondsSinceEpoch}${p.extension(picked.path).isEmpty ? '.jpg' : p.extension(picked.path)}',
      );
      final savedFile = await File(picked.path).copy(targetPath);

      if (!mounted) return;
      setState(() {
        _savedImagePath = savedFile.path;
      });
    } finally {
      if (mounted) {
        setState(() => _isCapturing = false);
      }
    }
  }

  Future<void> _queueAssessment() async {
    if (_savedImagePath == null || _isSaving) return;
    setState(() => _isSaving = true);
    final payload = await _repository.buildReportPayload(
      transcript: 'Child with rash and fever, likely measles, refer to PHC',
      hasPhoto: true,
      forceReferral: true,
      extraSymptoms: const ['rash', 'fever'],
    );
    await SyncQueue.queueReport(
      type: 'chw_report',
      payload: payload,
      localImagePath: _savedImagePath,
    );
    if (!mounted) return;
    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Photo assessment added to report queue.')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AshaScaffold(
      title: 'Photo assessment',
      subtitle: _savedImagePath == null
          ? 'Capture image for local triage'
          : 'Image stored locally and ready for queueing',
      activeTab: AshaTab.home,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: _captureImage,
              borderRadius: BorderRadius.circular(18),
              child: Container(
                width: double.infinity,
                height: 220,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFD0D8E2)),
                ),
                child: _savedImagePath == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _isCapturing
                                ? Icons.hourglass_bottom_rounded
                                : Icons.photo_camera_outlined,
                            size: 34,
                            color: const Color(0xFF7B8596),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _isCapturing ? 'Opening camera...' : 'Take or capture photo',
                            style: const TextStyle(
                              fontSize: 18,
                              color: Color(0xFF697587),
                            ),
                          ),
                        ],
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(
                          File(_savedImagePath!),
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 14),
            _AssessmentCard(
              title: 'Assessment result',
              background: const Color(0xFFFCE8E8),
              titleColor: const Color(0xFFAA3D3D),
              child: Text(
                _savedImagePath == null
                    ? 'No on-device disease model integrated yet. Capture an image to store it locally for later analysis.'
                    : 'Image captured and stored in local SQLite metadata. Disease analyzer placeholder: likely skin condition / rash review required.',
                style: const TextStyle(
                  fontSize: 18,
                  height: 1.45,
                  color: Color(0xFFA63D3D),
                ),
              ),
            ),
            const SizedBox(height: 14),
            _AssessmentCard(
              title: 'What happens now',
              background: const Color(0xFFF8EFD8),
              titleColor: const Color(0xFF7A5B00),
              child: Text(
                _savedImagePath == null
                    ? 'After capture, the photo preview will appear here and the path will be saved with the report in SQLite.'
                    : 'When you add this to the report, the app stores the photo path locally and marks the report as hasPhoto=true for sync.',
                style: const TextStyle(
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
                    onPressed: _captureImage,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 50),
                      foregroundColor: const Color(0xFF374355),
                      side: const BorderSide(color: Color(0xFFD7DDE7)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(_savedImagePath == null ? 'Open camera' : 'Retake'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _savedImagePath == null || _isSaving ? null : _queueAssessment,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 50),
                      backgroundColor: const Color(0xFF0E7B60),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(_isSaving ? 'Saving...' : 'Add to report'),
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
          Text(
            title,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
