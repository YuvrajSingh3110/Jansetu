import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jansetu/core/services/speech_service.dart';
import 'package:jansetu/features/asha/data/asha_repository.dart';
import 'package:jansetu/features/asha/presentation/asha_navigation.dart';
import 'package:jansetu/features/asha/presentation/widgets/asha_scaffold.dart';
import 'package:jansetu/features/onboarding/presentation/bloc/onboarding_bloc.dart';
import 'package:jansetu/sync_queue.dart';

class AshaRecordingScreen extends StatefulWidget {
  const AshaRecordingScreen({super.key});

  @override
  State<AshaRecordingScreen> createState() => _AshaRecordingScreenState();
}

class _AshaRecordingScreenState extends State<AshaRecordingScreen> {
  final SpeechService _speechService = SpeechService();
  final AshaRepository _repository = AshaRepository();

  String _transcript = '';
  bool _isListening = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startListening();
    });
  }

  @override
  void dispose() {
    _speechService.stopListening();
    super.dispose();
  }

  Future<void> _startListening() async {
    final localeCode =
        context.read<OnboardingBloc>().state.selectedLanguage?.localeCode ?? 'hi';
    final localeId = switch (localeCode) {
      'hi' => 'hi_IN',
      'bn' => 'bn_IN',
      'pa' => 'pa_IN',
      _ => 'en_IN',
    };

    await _speechService.startListening(
      localeId: localeId,
      onResult: (text) {
        if (!mounted) return;
        setState(() {
          _transcript = text;
          _isListening = true;
        });
      },
    );

    if (!mounted) return;
    setState(() {
      _isListening = _speechService.isListening;
    });
  }

  Future<void> _stopListening() async {
    await _speechService.stopListening();
    if (!mounted) return;
    setState(() {
      _isListening = false;
    });
  }

  Future<void> _saveReport() async {
    if (_transcript.trim().isEmpty || _isSaving) return;
    setState(() => _isSaving = true);
    await _stopListening();
    final payload = await _repository.buildReportPayload(transcript: _transcript);
      await SyncQueue.queueReport(type: 'chw_report', payload: payload);
    if (!mounted) return;
    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('ashaRecordingSaved'.tr())),
    );
    Navigator.of(context).pop();
  }

  List<String> _deriveTags() {
    final lower = _transcript.toLowerCase();
    final tags = <String>[];
    if (lower.contains('female') || lower.contains('mahila')) tags.add('F');
    if (lower.contains('male')) tags.add('M');
    if (lower.contains('fever') || lower.contains('bukhar')) tags.add('Fever');
    if (lower.contains('cough') || lower.contains('khansi')) tags.add('Cough');
    if (lower.contains('breath') || lower.contains('saans')) tags.add('Breathlessness');
    if (lower.contains('rash') || lower.contains('daane')) tags.add('Rash');
    if (tags.isEmpty) tags.add('Listening');
    return tags.take(5).toList();
  }

  @override
  Widget build(BuildContext context) {
    final tags = _deriveTags();
    final hasUrgentFlag = tags.contains('Breathlessness');

    return AshaScaffold(
      title: 'ashaRecordingTitle'.tr(),
      subtitle: _isListening
          ? 'ashaRecordingSubtitleLive'.tr()
          : 'ashaRecordingSubtitleRetry'.tr(),
      activeTab: AshaTab.home,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _LanguageChip(
                  label: context.locale.languageCode.toUpperCase(),
                  active: true,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: const Color(0xFFD7EEE7),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  8,
                  (index) => _WaveBar(
                    height: _isListening
                        ? 18 + (index.isEven ? 12 : 26)
                        : 12,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'ashaRecordingLiveTranscript'.tr(),
              style: TextStyle(fontSize: 13, color: Color(0xFF6C7889)),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _transcript.isEmpty
                    ? 'ashaRecordingListening'.tr()
                    : _transcript,
                style: const TextStyle(
                  fontSize: 18,
                  height: 1.4,
                  color: Color(0xFF243142),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'ashaRecordingExtracted'.tr(),
              style: TextStyle(fontSize: 13, color: Color(0xFF6C7889)),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: tags
                  .map(
                    (tag) => _TagChip(
                      label: tag,
                      bg: tag == 'Breathlessness'
                          ? const Color(0xFFFBE0E0)
                          : const Color(0xFFE3F2E9),
                      fg: tag == 'Breathlessness'
                          ? const Color(0xFFAF3F3F)
                          : const Color(0xFF276F46),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: hasUrgentFlag
                    ? const Color(0xFFFBE7E7)
                    : const Color(0xFFF8F2DF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                hasUrgentFlag
                    ? 'ashaRecordingUrgent'.tr()
                    : 'ashaRecordingNoUrgent'.tr(),
                style: TextStyle(
                  fontSize: 18,
                  height: 1.4,
                  color: hasUrgentFlag
                      ? const Color(0xFFA63D3D)
                      : const Color(0xFF6E570C),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      await _stopListening();
                      if (!mounted) return;
                      setState(() {
                        _transcript = '';
                      });
                      await _startListening();
                    },
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 50),
                      foregroundColor: const Color(0xFF374355),
                      side: const BorderSide(color: Color(0xFFD7DDE7)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text('ashaRetake'.tr()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _transcript.trim().isEmpty || _isSaving ? null : _saveReport,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 50),
                      backgroundColor: const Color(0xFF0E7B60),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      _isSaving ? 'ashaSaving'.tr() : 'ashaConfirmSave'.tr(),
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

class _LanguageChip extends StatelessWidget {
  const _LanguageChip({required this.label, this.active = false});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: active ? const Color(0xFF0E7B60) : Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: active ? const Color(0xFF0E7B60) : const Color(0xFFCDD4DE),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: active ? Colors.white : const Color(0xFF435064),
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _WaveBar extends StatelessWidget {
  const _WaveBar({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: 4,
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF0E7B60),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({
    required this.label,
    required this.bg,
    required this.fg,
  });

  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
