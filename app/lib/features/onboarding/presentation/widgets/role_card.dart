import 'package:flutter/material.dart';
import 'package:jansetu/core/theme/app_theme.dart';
import 'package:jansetu/features/onboarding/domain/models/user_role.dart';

/// A tappable card for selecting a user role.
///
/// Title and subtitle are passed in as localized strings from the screen.
/// Selected state: green border + light green tint.
/// Unselected: white/grey with subtle border.
class RoleCard extends StatelessWidget {
  const RoleCard({
    super.key,
    required this.role,
    required this.localizedTitle,
    required this.localizedSubtitle,
    required this.isSelected,
    required this.onTap,
  });

  final UserRole role;
  final String localizedTitle;
  final String localizedSubtitle;
  final bool isSelected;
  final VoidCallback onTap;

  IconData get _icon {
    return role == UserRole.healthWorker
        ? Icons.person_rounded
        : Icons.home_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.cardSelected : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.borderSelected : AppColors.borderLight,
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            // ── Icon ──────────────────────────────────────────────
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.cardFill,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                _icon,
                size: 28,
                color: isSelected
                    ? AppColors.textOnPrimary
                    : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 16),

            // ── Text ──────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizedTitle,
                    style: AppTextStyles.roleTitle.copyWith(
                      color: isSelected
                          ? AppColors.primaryDark
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    localizedSubtitle,
                    style: AppTextStyles.roleSubtitle,
                  ),
                ],
              ),
            ),

            // ── Check indicator ───────────────────────────────────
            if (isSelected)
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 18,
                  color: AppColors.textOnPrimary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
