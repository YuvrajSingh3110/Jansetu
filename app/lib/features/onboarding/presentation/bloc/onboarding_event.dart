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

/// User pressed "Continue" on the role selection screen.
class RoleContinuePressed extends OnboardingEvent {
  const RoleContinuePressed();
}

/// User selected a gender.
class GenderSelected extends OnboardingEvent {
  final String gender;
  const GenderSelected(this.gender);

  @override
  List<Object?> get props => [gender];
}

/// User selected an age.
class AgeSelected extends OnboardingEvent {
  final int age;
  const AgeSelected(this.age);

  @override
  List<Object?> get props => [age];
}

/// User confirmed their details → persist everything and finish.
class OnboardingCompleted extends OnboardingEvent {
  const OnboardingCompleted();
}

/// App launch check: has onboarding already been completed?
class OnboardingStatusChecked extends OnboardingEvent {
  const OnboardingStatusChecked();
}

/// Clears any saved onboarding selection from bloc memory and returns to the
/// first onboarding step. Storage clearing happens outside the bloc.
class OnboardingResetRequested extends OnboardingEvent {
  const OnboardingResetRequested();
}
