import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jansetu/core/theme/app_theme.dart';
import 'package:jansetu/features/onboarding/domain/models/app_language.dart';
import 'package:jansetu/features/onboarding/presentation/bloc/onboarding_bloc.dart';
import 'package:jansetu/features/onboarding/presentation/bloc/onboarding_event.dart';
import 'package:jansetu/features/onboarding/presentation/bloc/onboarding_state.dart';
import 'package:jansetu/features/onboarding/presentation/widgets/language_card.dart';

import 'package:easy_localization/easy_localization.dart';

/// Screen 1 of onboarding — language selection.
///
/// Layout (top → bottom):
///   • Green gradient header with app logo + "Aarogya Sentinel"
///   • Bilingual subtitle "अपनी भाषा चुनें · Select language"
///   • 2×3 grid of language cards
///   • Full-width "आगे बढ़ें · Continue" button
class LanguageSelectScreen extends StatelessWidget {
  const LanguageSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────
            _buildHeader(),

            // ── Body ────────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 28),
                    Text(
                      'selectLanguage'.tr(),
                      style: AppTextStyles.subtitle,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    _buildLanguageGrid(),
                    const Spacer(),
                    _buildContinueButton(context),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Green gradient header with concentric-ring logo and title.
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36),
      decoration: const BoxDecoration(
        gradient: AppColors.headerGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          // App logo — concentric rings icon
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Jansetu',
            style: AppTextStyles.appTitle.copyWith(
              color: AppColors.textOnPrimary,
            ),
          ),
        ],
      ),
    );
  }

  /// 2×3 grid of language cards, driven by BLoC state.
  Widget _buildLanguageGrid() {
    return BlocBuilder<OnboardingBloc, OnboardingState>(
      buildWhen: (prev, curr) =>
          prev.selectedLanguage != curr.selectedLanguage,
      builder: (context, state) {
        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 1.55,
          children: AppLanguage.values.map((lang) {
            return LanguageCard(
              language: lang,
              isSelected: state.selectedLanguage == lang,
              onTap: () {
                context.read<OnboardingBloc>().add(LanguageSelected(lang));
              },
            );
          }).toList(),
        );
      },
    );
  }

  /// Full-width CTA button. Disabled (greyed out) until a language
  /// is selected.
  Widget _buildContinueButton(BuildContext context) {
    return BlocBuilder<OnboardingBloc, OnboardingState>(
      buildWhen: (prev, curr) =>
          prev.selectedLanguage != curr.selectedLanguage,
      builder: (context, state) {
        final isEnabled = state.selectedLanguage != null;
        return AnimatedOpacity(
          opacity: isEnabled ? 1.0 : 0.45,
          duration: const Duration(milliseconds: 200),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: isEnabled
                  ? () async {
                      await context.setLocale(Locale(state.selectedLanguage!.localeCode));
                      if (context.mounted) {
                        context
                            .read<OnboardingBloc>()
                            .add(const LanguageContinuePressed());
                      }
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor:
                    AppColors.primary.withValues(alpha: 0.4),
                foregroundColor: AppColors.textOnPrimary,
                disabledForegroundColor:
                    AppColors.textOnPrimary.withValues(alpha: 0.6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: Text(
                'continueButton'.tr(),
                style: AppTextStyles.buttonText,
              ),
            ),
          ),
        );
      },
    );
  }
}
