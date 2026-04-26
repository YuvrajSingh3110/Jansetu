import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jansetu/core/services/photo_assessment_service.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class PhotoAssessmentScreen extends StatefulWidget {
  const PhotoAssessmentScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onSave,
    required this.saveButtonLabel,
  });

  final String title;
  final String subtitle;
  final Future<void> Function(String imagePath, PhotoAssessmentResult result) onSave;
  final String saveButtonLabel;

  @override
  State<PhotoAssessmentScreen> createState() => _PhotoAssessmentScreenState();
}

class _PhotoAssessmentScreenState extends State<PhotoAssessmentScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  final PhotoAssessmentService _assessmentService = PhotoAssessmentService();

  String? _savedImagePath;
  PhotoAssessmentResult? _result;
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
      final result = await _assessmentService.analyzeImage(savedFile.path);

      if (!mounted) return;
      setState(() {
        _savedImagePath = savedFile.path;
        _result = result;
      });
    } finally {
      if (mounted) {
        setState(() => _isCapturing = false);
      }
    }
  }

  Future<void> _save() async {
    if (_savedImagePath == null || _result == null || _isSaving) return;
    setState(() => _isSaving = true);
    await widget.onSave(_savedImagePath!, _result!);
    if (!mounted) return;
    setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: Text(widget.title),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(28),
          child: Padding(
            padding: const EdgeInsets.only(left: 20, right: 20, bottom: 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                widget.subtitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
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
              title: result?.title ?? 'Assessment result',
              background: const Color(0xFFFCE8E8),
              titleColor: const Color(0xFFAA3D3D),
              child: Text(
                result?.summary ??
                    'Capture an image to run the shared photo assessment pipeline.',
                style: const TextStyle(
                  fontSize: 18,
                  height: 1.45,
                  color: Color(0xFFA63D3D),
                ),
              ),
            ),
            const SizedBox(height: 14),
            _AssessmentCard(
              title: 'What we found',
              background: const Color(0xFFF8EFD8),
              titleColor: const Color(0xFF7A5B00),
              child: Text(
                result == null
                    ? 'The same capture and assessment logic is shared across village and ASHA flows.'
                    : '${result.primaryFinding}\n${result.recommendation}\n${result.extraNote}',
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
                    onPressed: _savedImagePath == null || result == null ? null : _save,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 50),
                      backgroundColor: const Color(0xFF0E7B60),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(_isSaving ? 'Saving...' : widget.saveButtonLabel),
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
