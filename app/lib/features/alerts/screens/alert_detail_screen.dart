import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:jansetu/core/services/tts_service.dart';
import 'package:jansetu/core/theme/app_theme.dart';

class AlertDetailScreen extends StatefulWidget {
  const AlertDetailScreen({super.key});

  @override
  State<AlertDetailScreen> createState() => _AlertDetailScreenState();
}

class _AlertDetailScreenState extends State<AlertDetailScreen> {
  final TtsService _ttsService = TtsService();
  bool _isReading = false;

  Future<void> _listenToAlert() async {
    final localeCode = context.locale.languageCode;
    await _ttsService.stop();
    await _ttsService.setLanguageForLocale(localeCode);

    final spokenText = [
      'alertDetailTitle'.tr(),
      'alertDetailBody'.tr(),
      'alertActionHeader'.tr(),
      'alertAction1Title'.tr(),
      'alertAction1Body'.tr(),
      'alertAction2Title'.tr(),
      'alertAction2Body'.tr(),
      'alertAction3Title'.tr(),
      'alertAction3Body'.tr(),
    ].join('. ');

    if (!mounted) return;
    setState(() {
      _isReading = true;
    });
    _ttsService.speak(spokenText);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() {
      _isReading = false;
    });
  }

  @override
  void dispose() {
    _ttsService.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _AlertHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _AlertSummaryCard(),
                    const SizedBox(height: 28),
                    Text(
                      'alertActionHeader'.tr(),
                      style: AppTextStyles.roleTitle.copyWith(fontSize: 22),
                    ),
                    const SizedBox(height: 18),
                    _AlertActionItem(
                      stepNumber: '1',
                      title: 'alertAction1Title'.tr(),
                      body: 'alertAction1Body'.tr(),
                    ),
                    const SizedBox(height: 22),
                    _AlertActionItem(
                      stepNumber: '2',
                      title: 'alertAction2Title'.tr(),
                      body: 'alertAction2Body'.tr(),
                    ),
                    const SizedBox(height: 22),
                    _AlertActionItem(
                      stepNumber: '3',
                      title: 'alertAction3Title'.tr(),
                      body: 'alertAction3Body'.tr(),
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 64,
                      child: ElevatedButton(
                        onPressed: _listenToAlert,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF177B63),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: Text(
                          _isReading
                              ? 'alertListenPlaying'.tr()
                              : 'alertListenButton'.tr(),
                          style: AppTextStyles.buttonText.copyWith(fontSize: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      decoration: const BoxDecoration(
        color: Color(0xFFAF2F2F),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.white,
                size: 34,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'alertHeaderTitle'.tr(),
                  style: AppTextStyles.headerTitle.copyWith(fontSize: 26),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'alertHeaderSubtitle'.tr(),
            style: AppTextStyles.headerSubtitle.copyWith(
              fontSize: 15,
              color: Colors.white.withValues(alpha: 0.92),
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertSummaryCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFCEDEE),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF5B9BC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'alertDetailTitle'.tr(),
            style: AppTextStyles.roleTitle.copyWith(
              fontSize: 22,
              color: const Color(0xFFAF2F2F),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'alertDetailBody'.tr(),
            style: AppTextStyles.roleSubtitle.copyWith(
              fontSize: 18,
              color: const Color(0xFF7F1D1D),
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertActionItem extends StatelessWidget {
  const _AlertActionItem({
    required this.stepNumber,
    required this.title,
    required this.body,
  });

  final String stepNumber;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: const BoxDecoration(
            color: Color(0xFFDDF3E9),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              stepNumber,
              style: AppTextStyles.roleTitle.copyWith(
                color: const Color(0xFF0E6A4F),
                fontSize: 20,
              ),
            ),
          ),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.roleTitle.copyWith(fontSize: 19),
              ),
              const SizedBox(height: 10),
              Text(
                body,
                style: AppTextStyles.roleSubtitle.copyWith(
                  fontSize: 16,
                  height: 1.55,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
