import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jansetu/core/services/health_language_service.dart';
import 'package:jansetu/core/services/photo_assessment_service.dart';
import 'package:jansetu/core/services/tts_service.dart';
import 'package:jansetu/core/widgets/sparkle_loader.dart';
import 'package:jansetu/features/onboarding/domain/models/app_language.dart';
import 'package:jansetu/features/onboarding/presentation/bloc/onboarding_bloc.dart';
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
  final Future<void> Function(String imagePath, PhotoAssessmentResult result)
  onSave;
  final String saveButtonLabel;

  @override
  State<PhotoAssessmentScreen> createState() => _PhotoAssessmentScreenState();
}

class _PhotoAssessmentScreenState extends State<PhotoAssessmentScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  final PhotoAssessmentService _assessmentService = PhotoAssessmentService();
  final TtsService _ttsService = TtsService();

  String? _savedImagePath;
  PhotoAssessmentResult? _result;
  bool _isCapturing = false;
  bool _isAnalyzing = false;
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
        _result = null;
        _isAnalyzing = true;
      });

      final selectedLanguage =
          context.read<OnboardingBloc>().state.selectedLanguage ??
          AppLanguage.fromCode(context.locale.languageCode);
      final result = await _assessmentService.analyzeImage(
        savedFile.path,
        language: selectedLanguage,
      );

      if (!mounted) return;
      setState(() {
        _result = result;
        _isAnalyzing = false;
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

  Future<void> _speakSuggestion() async {
    final result = _result;
    if (result == null) return;
    final localeCode = context.locale.languageCode;
    final spokenText = '${result.recommendation} ${result.extraNote}'.trim();
    if (spokenText.isEmpty) return;
    await _ttsService.stop();
    await _ttsService.setLanguageForLocale(localeCode);
    _ttsService.speak(spokenText);
  }

  @override
  void dispose() {
    _ttsService.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    final localeCode = context.locale.languageCode;
    final localizedSymptoms = result == null
        ? const <String>[]
        : HealthLanguageService.localizedSymptoms(
            result.extraSymptoms,
            localeCode,
          );
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
                            _isCapturing
                                ? 'ashaPhotoOpeningCamera'.tr()
                                : 'ashaPhotoTakeCapture'.tr(),
                            style: const TextStyle(
                              fontSize: 18,
                              color: Color(0xFF697587),
                            ),
                          ),
                        ],
                      )
                    : Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.file(
                              File(_savedImagePath!),
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                          ),
                          if (_isAnalyzing)
                            Container(
                              color: Colors.black.withValues(alpha: 0.28),
                              alignment: Alignment.center,
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                ),
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: SparkleLoader(
                                  label: 'ashaPhotoGemmaRunning'.tr(),
                                  caption: 'ashaPhotoGemmaCaption'.tr(),
                                ),
                              ),
                            ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 14),
            _AssessmentCard(
              title: result?.title ?? 'Assessment result',
              background: const Color(0xFFFCE8E8),
              titleColor: const Color(0xFFAA3D3D),
              child: _isAnalyzing
                  ? SparkleLoader(
                      label: 'ashaPhotoGemmaResponse'.tr(),
                      caption: 'ashaPhotoGemmaResponseCaption'.tr(),
                    )
                  : Text(
                      result?.summary ?? 'ashaPhotoCapturePrompt'.tr(),
                      style: const TextStyle(
                        fontSize: 18,
                        height: 1.45,
                        color: Color(0xFFA63D3D),
                      ),
                    ),
            ),
            const SizedBox(height: 14),
            _AssessmentCard(
              title: 'ashaPhotoSignals'.tr(),
              background: const Color(0xFFF8F5E8),
              titleColor: const Color(0xFF7A5B00),
              child: _isAnalyzing
                  ? SparkleLoader(
                      label: 'ashaPhotoSignals'.tr(),
                      caption: 'ashaPhotoSignalsCaption'.tr(),
                      compact: true,
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          result == null
                              ? 'ashaPhotoSharedPipeline'.tr()
                              : '${result.primaryFinding}\n${result.recommendation}\n${result.extraNote}',
                          style: const TextStyle(
                            fontSize: 18,
                            height: 1.45,
                            color: Color(0xFF6E570C),
                          ),
                        ),
                        if (localizedSymptoms.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: localizedSymptoms
                                .map((symptom) => _SymptomChip(label: symptom))
                                .toList(),
                          ),
                        ],
                      ],
                    ),
            ),
            const SizedBox(height: 14),
            _AssessmentCard(
              title: 'ashaPhotoWorkerNote'.tr(),
              background: const Color(0xFFE8F1FB),
              titleColor: const Color(0xFF2368AF),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result == null
                        ? 'ashaPhotoWorkerNotePlaceholder'.tr()
                        : '${result.recommendation}\n${result.extraNote}'
                              .trim(),
                    style: const TextStyle(
                      fontSize: 17,
                      height: 1.45,
                      color: Color(0xFF23415F),
                    ),
                  ),
                  if (result != null) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _speakSuggestion,
                        icon: const Icon(Icons.volume_up_outlined),
                        label: Text(
                          HealthLanguageService.hearSuggestionLabel(localeCode),
                        ),
                      ),
                    ),
                  ],
                ],
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
                    child: Text(
                      _savedImagePath == null
                          ? 'ashaPhotoOpenCamera'.tr()
                          : 'ashaRetake'.tr(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed:
                        _savedImagePath == null ||
                            result == null ||
                            _isAnalyzing
                        ? null
                        : _save,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 50),
                      backgroundColor: const Color(0xFF0E7B60),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      _isSaving ? 'Saving...' : widget.saveButtonLabel,
                    ),
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

class _SymptomChip extends StatelessWidget {
  const _SymptomChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2E9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF276F46),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
