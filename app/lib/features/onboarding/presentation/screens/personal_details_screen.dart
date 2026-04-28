import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:jansetu/core/theme/app_theme.dart';
import 'package:jansetu/features/onboarding/presentation/bloc/onboarding_bloc.dart';
import 'package:jansetu/features/onboarding/presentation/bloc/onboarding_event.dart';
import 'package:jansetu/features/onboarding/presentation/bloc/onboarding_state.dart';

class PersonalDetailsScreen extends StatelessWidget {
  const PersonalDetailsScreen({super.key});

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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 32),
                        _buildGenderSection(context, state),
                        const SizedBox(height: 32),
                        _buildAgeSection(context, state),
                        const Spacer(),
                        _buildContinueButton(context, state),
                        const SizedBox(height: 16),
                        _buildPrivacyDisclaimer(),
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
            'personalDetailsTitle'.tr(),
            style: AppTextStyles.headerTitle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'personalDetailsSubtitle'.tr(),
            style: AppTextStyles.headerSubtitle.copyWith(fontSize: 15),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildGenderSection(BuildContext context, OnboardingState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'genderLabel'.tr(),
          style: AppTextStyles.roleTitle.copyWith(fontSize: 18),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildGenderCard(
              context,
              label: 'male'.tr(),
              isSelected: state.selectedGender == 'male',
              onTap: () => context.read<OnboardingBloc>().add(const GenderSelected('male')),
            ),
            const SizedBox(width: 16),
            _buildGenderCard(
              context,
              label: 'female'.tr(),
              isSelected: state.selectedGender == 'female',
              onTap: () => context.read<OnboardingBloc>().add(const GenderSelected('female')),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGenderCard(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.cardFill,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.borderLight,
              width: 2,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.buttonText.copyWith(
              color: isSelected ? Colors.white : AppColors.textPrimary,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAgeSection(BuildContext context, OnboardingState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ageLabel'.tr(),
          style: AppTextStyles.roleTitle.copyWith(fontSize: 18),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.cardFill,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: state.selectedAge,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down),
              onChanged: (value) {
                if (value != null) {
                  context.read<OnboardingBloc>().add(AgeSelected(value));
                }
              },
              items: List.generate(100, (index) => index + 1)
                  .map((age) => DropdownMenuItem(
                        value: age,
                        child: Text(age.toString()),
                      ))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContinueButton(BuildContext context, OnboardingState state) {
    final isEnabled = state.selectedGender != null;
    return AnimatedOpacity(
      opacity: isEnabled ? 1.0 : 0.45,
      duration: const Duration(milliseconds: 200),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: isEnabled
              ? () {
                  context.read<OnboardingBloc>().add(const OnboardingCompleted());
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.4),
            foregroundColor: AppColors.textOnPrimary,
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

  Widget _buildPrivacyDisclaimer() {
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
              'privacyDisclaimer'.tr(),
              style: AppTextStyles.footerText,
            ),
          ),
        ],
      ),
    );
  }
}
