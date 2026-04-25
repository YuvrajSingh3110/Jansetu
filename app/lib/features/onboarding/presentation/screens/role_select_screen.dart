import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:jansetu/core/theme/app_theme.dart';
import 'package:jansetu/features/onboarding/domain/models/user_role.dart';
import 'package:jansetu/features/onboarding/presentation/bloc/onboarding_bloc.dart';
import 'package:jansetu/features/onboarding/presentation/bloc/onboarding_event.dart';
import 'package:jansetu/features/onboarding/presentation/bloc/onboarding_state.dart';
import 'package:jansetu/features/onboarding/presentation/widgets/role_card.dart';

/// Screen 2 of onboarding — role selection.
///
/// All visible text is driven by the language chosen on screen 1.
class RoleSelectScreen extends StatelessWidget {
  const RoleSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OnboardingBloc, OnboardingState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 32),
                        _buildRoleCards(context, state),
                        const Spacer(),
                        _buildContinueButton(context, state),
                        const SizedBox(height: 16),
                        _buildPrivacyNotice(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Green gradient header with localised title.
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      decoration: const BoxDecoration(
        gradient: AppColors.headerGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          Text(
            'whoAreYou'.tr(),
            style: AppTextStyles.headerTitle,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Vertically stacked role cards with localised labels.
  Widget _buildRoleCards(
    BuildContext context,
    OnboardingState state,
  ) {
    return Column(
      children: UserRole.values.map((role) {
        final title = role == UserRole.healthWorker
            ? 'healthWorkerTitle'.tr()
            : 'villagePersonTitle'.tr();
        final subtitle = role == UserRole.healthWorker
            ? 'healthWorkerSubtitle'.tr()
            : 'villagePersonSubtitle'.tr();

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: RoleCard(
            role: role,
            localizedTitle: title,
            localizedSubtitle: subtitle,
            isSelected: state.selectedRole == role,
            onTap: () {
              context.read<OnboardingBloc>().add(RoleSelected(role));
            },
          ),
        );
      }).toList(),
    );
  }

  /// CTA button — enabled only after role selection.
  Widget _buildContinueButton(
    BuildContext context,
    OnboardingState state,
  ) {
    final isEnabled = state.selectedRole != null;
    return AnimatedOpacity(
      opacity: isEnabled ? 1.0 : 0.45,
      duration: const Duration(milliseconds: 200),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: isEnabled
              ? () {
                  context
                      .read<OnboardingBloc>()
                      .add(const OnboardingCompleted());
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
  }

  /// Localised privacy notice footer.
  Widget _buildPrivacyNotice() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.cardFill,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.shield_outlined,
            size: 20,
            color: AppColors.textMuted,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'privacyNotice'.tr(),
              style: AppTextStyles.footerText,
            ),
          ),
        ],
      ),
    );
  }
}
