import 'package:equatable/equatable.dart';
import 'package:jansetu/features/onboarding/domain/models/app_language.dart';
import 'package:jansetu/features/onboarding/domain/models/user_role.dart';

/// Base class for all onboarding events.
sealed class OnboardingEvent extends Equatable {
  const OnboardingEvent();

  @override
  List<Object?> get props => [];
}

/// User tapped a language card.
class LanguageSelected extends OnboardingEvent {
  final AppLanguage language;

  const LanguageSelected(this.language);

  @override
  List<Object?> get props => [language];
}

/// User tapped a role card.
class RoleSelected extends OnboardingEvent {
  final UserRole role;

  const RoleSelected(this.role);

  @override
  List<Object?> get props => [role];
}

/// User pressed "Continue" on the language screen.
class LanguageContinuePressed extends OnboardingEvent {
  const LanguageContinuePressed();
}

/// User confirmed their role → persist everything and finish.
class OnboardingCompleted extends OnboardingEvent {
  const OnboardingCompleted();
}

/// App launch check: has onboarding already been completed?
class OnboardingStatusChecked extends OnboardingEvent {
  const OnboardingStatusChecked();
}
