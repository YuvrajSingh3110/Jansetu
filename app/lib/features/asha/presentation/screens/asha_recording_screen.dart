import 'dart:async';
import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:jansetu/core/services/health_language_service.dart';
import 'package:jansetu/core/services/llm_service.dart';
import 'package:jansetu/core/services/speech_service.dart';
import 'package:jansetu/core/services/tts_service.dart';
import 'package:jansetu/core/widgets/sparkle_loader.dart';
import 'package:jansetu/features/asha/data/asha_repository.dart';
import 'package:jansetu/features/asha/presentation/asha_navigation.dart';
import 'package:jansetu/features/onboarding/domain/models/app_language.dart';
import 'package:jansetu/features/asha/presentation/widgets/asha_scaffold.dart';
import 'package:jansetu/features/onboarding/presentation/bloc/onboarding_bloc.dart';
import 'package:jansetu/sync_queue.dart';

class AshaRecordingScreen extends StatefulWidget {
  const AshaRecordingScreen({super.key});

  @override
  State<AshaRecordingScreen> createState() => _AshaRecordingScreenState();
}

class _AshaRecordingScreenState extends State<AshaRecordingScreen> {
  static const List<double> _idleSoundLevels = [
    0.12,
    0.18,
    0.26,
    0.20,
    0.28,
    0.16,
    0.22,
    0.14,
  ];

  final SpeechService _speechService = SpeechService();
  final AshaRepository _repository = AshaRepository();
  final LlmService _llmService = LlmService();
  final TtsService _ttsService = TtsService();

  String _transcript = '';
  bool _isListening = false;
  bool _isPreparingRecorder = false;
  bool _isSaving = false;
  bool _isAnalyzingTranscript = false;
  String? _analysisSummary;
  String? _analysisSuggestion;
  String? _analysisRisk;
  List<String> _analysisSymptoms = const [];
  late final List<double> _soundLevels = List<double>.from(_idleSoundLevels);
  Timer? _analysisDebounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startListening();
    });
  }

  @override
  void dispose() {
    _analysisDebounce?.cancel();
    _speechService.stopListening();
    _ttsService.stop();
    super.dispose();
  }

  Future<void> _startListening() async {
    if (_isPreparingRecorder) return;
    final localeCode =
        context.read<OnboardingBloc>().state.selectedLanguage?.localeCode ??
        'hi';
    final localeId = switch (localeCode) {
      'hi' => 'hi_IN',
      'bn' => 'bn_IN',
      'pa' => 'pa_IN',
      _ => 'en_IN',
    };

    setState(() {
      _isPreparingRecorder = true;
      _isListening = true;
      _analysisSummary = null;
      _analysisSuggestion = null;
      _analysisRisk = null;
      _analysisSymptoms = const [];
      _isAnalyzingTranscript = false;
      _resetVisualizer(active: true);
    });

    try {
      await _speechService.startListening(
        localeId: localeId,
        onResult: (text, isFinal) {
          if (!mounted) return;
          setState(() {
            _transcript = text;
            _isListening = true;
          });
          if (isFinal) {
            _finishListeningUi(runAnalysis: true);
          } else {
            _scheduleTranscriptAnalysis(text);
          }
        },
        onStatusChanged: (status) {
          if (!mounted) return;
          final normalized = status.toLowerCase();
          if (normalized.contains('notlistening') ||
              normalized.contains('done')) {
            _finishListeningUi(runAnalysis: true);
            return;
          }
          if (normalized.contains('listening')) {
            setState(() {
              _isListening = true;
              _isPreparingRecorder = false;
            });
          }
        },
        onError: (_) {
          if (!mounted) return;
          _finishListeningUi(runAnalysis: true);
        },
        onSoundLevelChange: (level) {
          if (!mounted) return;
          final normalized = _normalizeSoundLevel(level);
          setState(() {
            _soundLevels
              ..removeAt(0)
              ..add(normalized);
          });
        },
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPreparingRecorder = false;
          _isListening = _speechService.isListening;
        });
      }
    }
  }

  Future<void> _stopListening() async {
    await _speechService.stopListening();
    if (!mounted) return;
    _finishListeningUi(runAnalysis: true);
  }

  Future<void> _saveReport() async {
    if (_transcript.trim().isEmpty || _isSaving) return;
    setState(() => _isSaving = true);
    await _stopListening();
    final payload = await _repository.buildReportPayload(
      transcript: _transcript,
    );
    await SyncQueue.queueReport(type: 'chw_report', payload: payload);
    if (!mounted) return;
    setState(() => _isSaving = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('ashaRecordingSaved'.tr())));
    Navigator.of(context).pop();
  }

  void _scheduleTranscriptAnalysis(String text) {
    _analysisDebounce?.cancel();
    if (text.trim().length < 18) {
      setState(() {
        _analysisSummary = null;
        _analysisSuggestion = null;
        _analysisRisk = null;
        _analysisSymptoms = const [];
        _isAnalyzingTranscript = false;
      });
      return;
    }

    _analysisDebounce = Timer(const Duration(milliseconds: 900), () {
      _runTranscriptAnalysis(text);
    });
  }

  void _finishListeningUi({required bool runAnalysis}) {
    if (!mounted) return;
    final latestTranscript = _transcript;
    setState(() {
      _isListening = false;
      _isPreparingRecorder = false;
      _resetVisualizer(active: false);
    });
    if (runAnalysis) {
      _scheduleTranscriptAnalysis(latestTranscript);
    }
  }

  void _resetVisualizer({required bool active}) {
    for (var index = 0; index < _soundLevels.length; index += 1) {
      _soundLevels[index] = active ? _idleSoundLevels[index] : 0.0;
    }
  }

  double _normalizeSoundLevel(double level) {
    if (!level.isFinite) {
      return 0.18;
    }
    final adjusted = ((level + 5) / 18).clamp(0.08, 1.0);
    return adjusted.toDouble();
  }

  Future<void> _runTranscriptAnalysis(String transcript) async {
    if (transcript.trim().length < 18) return;
    setState(() => _isAnalyzingTranscript = true);
    final selectedLanguage =
        context.read<OnboardingBloc>().state.selectedLanguage ??
        AppLanguage.fromCode(context.locale.languageCode);
    final localeCode = selectedLanguage?.localeCode ?? 'en';
    final targetLanguage = HealthLanguageService.promptLanguageInstruction(
      selectedLanguage,
    );
    final prompt =
        '''
ASHA worker transcript:
$transcript

Write worker-facing text in $targetLanguage.
Use symptom codes in English only from this set:
fever, cough, breathlessness, diarrhoea, vomiting, rash, headache, bodyache, sore_throat, runny_nose, malnutrition, jaundice, conjunctivitis, seizure, unconscious, bleeding.

Return exactly:
Symptoms: <comma-separated symptom codes or "unclear">
Summary: <one short surveillance summary in $targetLanguage>
Suggestion: <one short action for the ASHA worker in $targetLanguage>
Risk: <one short risk note in $targetLanguage>
''';

    try {
      final response = await _llmService
          .getResponseStream(Message.text(text: prompt, isUser: true))
          .join('');
      final symptomsMatch = RegExp(r'Symptoms:\s*(.*)').firstMatch(response);
      final summaryMatch = RegExp(r'Summary:\s*(.*)').firstMatch(response);
      final suggestionMatch = RegExp(
        r'Suggestion:\s*(.*)',
      ).firstMatch(response);
      final riskMatch = RegExp(r'Risk:\s*(.*)').firstMatch(response);
      if (!mounted || transcript != _transcript) return;
      final parsedSymptoms = _parseSymptoms(symptomsMatch?.group(1));
      final fallbackSymptoms = parsedSymptoms.isNotEmpty
          ? parsedSymptoms
          : HealthLanguageService.extractSymptomsFromTranscript(transcript);
      final localizedResponse = await _localizeRecorderGuidance(
        transcript: transcript,
        symptoms: fallbackSymptoms,
        selectedLanguage: selectedLanguage,
        summaryHint: summaryMatch?.group(1)?.trim(),
        suggestionHint: suggestionMatch?.group(1)?.trim(),
        riskHint: riskMatch?.group(1)?.trim(),
      );
      if (!mounted || transcript != _transcript) return;
      setState(() {
        _analysisSymptoms = fallbackSymptoms;
        _analysisSummary =
            HealthLanguageService.prefersFallbackForLocale(
              localeCode,
              localizedResponse.$1,
            )
            ? HealthLanguageService.fallbackSummary(
                localeCode,
                fallbackSymptoms,
              )
            : (localizedResponse.$1 ??
                  HealthLanguageService.fallbackSummary(
                    localeCode,
                    fallbackSymptoms,
                  ));
        _analysisSuggestion =
            HealthLanguageService.prefersFallbackForLocale(
              localeCode,
              localizedResponse.$2,
            )
            ? HealthLanguageService.fallbackSuggestion(
                localeCode,
                fallbackSymptoms,
                urgent: fallbackSymptoms.contains('breathlessness'),
              )
            : (localizedResponse.$2 ??
                  HealthLanguageService.fallbackSuggestion(
                    localeCode,
                    fallbackSymptoms,
                    urgent: fallbackSymptoms.contains('breathlessness'),
                  ));
        _analysisRisk =
            HealthLanguageService.prefersFallbackForLocale(
              localeCode,
              localizedResponse.$3,
            )
            ? null
            : localizedResponse.$3;
        _isAnalyzingTranscript = false;
      });
    } catch (_) {
      if (!mounted || transcript != _transcript) return;
      final fallbackSymptoms =
          HealthLanguageService.extractSymptomsFromTranscript(transcript);
      setState(() {
        _analysisSummary = HealthLanguageService.fallbackSummary(
          localeCode,
          fallbackSymptoms,
        );
        _analysisSuggestion = HealthLanguageService.fallbackSuggestion(
          localeCode,
          fallbackSymptoms,
          urgent: fallbackSymptoms.contains('breathlessness'),
        );
        _analysisRisk = null;
        _analysisSymptoms = fallbackSymptoms;
        _isAnalyzingTranscript = false;
      });
    }
  }

  Future<(String?, String?, String?)> _localizeRecorderGuidance({
    required String transcript,
    required List<String> symptoms,
    required AppLanguage? selectedLanguage,
    String? summaryHint,
    String? suggestionHint,
    String? riskHint,
  }) async {
    final languageInstruction = HealthLanguageService.promptLanguageInstruction(
      selectedLanguage,
    );
    final prompt =
        '''
Create worker-facing guidance for an ASHA worker.
Write only in $languageInstruction.
Do not use English unless the language itself is English.

Transcript:
$transcript

Detected symptom codes:
${symptoms.isEmpty ? 'unclear' : symptoms.join(', ')}

Hints:
Summary hint: ${summaryHint ?? 'none'}
Suggestion hint: ${suggestionHint ?? 'none'}
Risk hint: ${riskHint ?? 'none'}

Return exactly:
Summary: <one short summary in $languageInstruction>
Suggestion: <one direct action for the ASHA worker in $languageInstruction>
Risk: <one short risk note in $languageInstruction>
''';
    try {
      final response = await _llmService
          .getResponseStream(Message.text(text: prompt, isUser: true))
          .join('');
      return (
        RegExp(r'Summary:\s*(.*)').firstMatch(response)?.group(1)?.trim(),
        RegExp(r'Suggestion:\s*(.*)').firstMatch(response)?.group(1)?.trim(),
        RegExp(r'Risk:\s*(.*)').firstMatch(response)?.group(1)?.trim(),
      );
    } catch (_) {
      return (null, null, null);
    }
  }

  List<String> _deriveFallbackSymptoms() {
    return HealthLanguageService.extractSymptomsFromTranscript(_transcript);
  }

  List<String> _parseSymptoms(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return const [];
    }
    final lower = raw.toLowerCase();
    if (lower.contains('unclear')) {
      return const [];
    }
    const known = [
      'fever',
      'cough',
      'breathlessness',
      'diarrhoea',
      'vomiting',
      'rash',
      'headache',
      'bodyache',
      'sore_throat',
      'runny_nose',
      'malnutrition',
      'jaundice',
      'conjunctivitis',
      'seizure',
      'unconscious',
      'bleeding',
    ];
    return [
      for (final code in known)
        if (lower.contains(code)) code,
    ];
  }

  Future<void> _speakSuggestion() async {
    final localeCode = context.locale.languageCode;
    final segments = [
      _analysisSuggestion,
      _analysisRisk,
    ].where((value) => value != null && value.trim().isNotEmpty).join(' ');
    if (segments.trim().isEmpty) {
      return;
    }
    await _ttsService.stop();
    await _ttsService.setLanguageForLocale(localeCode);
    _ttsService.speak(segments);
  }

  @override
  Widget build(BuildContext context) {
    final localeCode = context.locale.languageCode;
    final symptomCodes = _analysisSymptoms.isNotEmpty
        ? _analysisSymptoms
        : _deriveFallbackSymptoms();
    final localizedSymptoms = HealthLanguageService.localizedSymptoms(
      symptomCodes,
      localeCode,
    );
    final hasUrgentFlag = symptomCodes.contains('breathlessness');

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
              child: _isListening
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _soundLevels.length,
                        (index) =>
                            _WaveBar(height: 10 + (_soundLevels[index] * 44)),
                      ),
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _transcript.trim().isEmpty
                              ? Icons.mic_none_rounded
                              : Icons.replay_circle_filled_rounded,
                          size: 34,
                          color: const Color(0xFF0E7B60),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _transcript.trim().isEmpty
                              ? 'Tap retake to start recording'
                              : 'Recording complete. Review or retake.',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2C5F4C),
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 10),
            Text(
              'ashaRecordingLiveTranscript'.tr(),
              style: const TextStyle(fontSize: 13, color: Color(0xFF6C7889)),
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
                    ? (_isListening
                          ? 'ashaRecordingListening'.tr()
                          : 'Start speaking to capture the visit summary.')
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
              style: const TextStyle(fontSize: 13, color: Color(0xFF6C7889)),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: localizedSymptoms.isEmpty
                  ? const []
                  : localizedSymptoms
                        .map(
                          (tag) => _TagChip(
                            label: tag,
                            bg:
                                tag ==
                                    HealthLanguageService.localizedSymptom(
                                      'breathlessness',
                                      localeCode,
                                    )
                                ? const Color(0xFFFBE0E0)
                                : const Color(0xFFE3F2E9),
                            fg:
                                tag ==
                                    HealthLanguageService.localizedSymptom(
                                      'breathlessness',
                                      localeCode,
                                    )
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
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF2FB),
                borderRadius: BorderRadius.circular(16),
              ),
              child: _isAnalyzingTranscript
                  ? SparkleLoader(
                      label: 'ashaRecordingGemmaThinking'.tr(),
                      caption: 'ashaRecordingGemmaCaption'.tr(),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ashaRecordingGemmaSummaryTitle'.tr(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF23415F),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _analysisSummary ??
                              'ashaRecordingGemmaSummaryPlaceholder'.tr(),
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.4,
                            color: Color(0xFF35536D),
                          ),
                        ),
                        if ((_analysisRisk ?? '').isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            _analysisRisk!,
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.35,
                              color: Color(0xFF4B5C72),
                            ),
                          ),
                        ],
                        if ((_analysisSuggestion ?? '').isNotEmpty ||
                            (_analysisSummary ?? '').isNotEmpty) ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _speakSuggestion,
                              icon: const Icon(Icons.volume_up_outlined),
                              label: Text(
                                HealthLanguageService.hearSuggestionLabel(
                                  localeCode,
                                ),
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
                    onPressed: () async {
                      await _stopListening();
                      if (!mounted) return;
                      setState(() {
                        _transcript = '';
                        _analysisSummary = null;
                        _analysisSuggestion = null;
                        _analysisRisk = null;
                        _analysisSymptoms = const [];
                        _isAnalyzingTranscript = false;
                        _resetVisualizer(active: false);
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
                    onPressed: _transcript.trim().isEmpty || _isSaving
                        ? null
                        : _saveReport,
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
      height: math.max(10, height),
      margin: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF0E7B60),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label, required this.bg, required this.fg});

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
        style: TextStyle(color: fg, fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }
}
