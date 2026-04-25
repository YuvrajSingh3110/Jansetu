import 'package:equatable/equatable.dart';
import 'package:jansetu/features/onboarding/domain/models/app_language.dart';
import 'package:jansetu/features/onboarding/domain/models/user_role.dart';

/// Possible statuses during onboarding.
enum OnboardingStatus {
  /// Initial / loading state (checking secure storage).
  initial,

  /// Actively on the language selection step.
  languageSelect,

  /// Actively on the role selection step.
  roleSelect,

  /// Onboarding finished — navigate to home.
  completed,

  /// An error occurred while persisting.
  error,
}

class OnboardingState extends Equatable {
  final OnboardingStatus status;
  final AppLanguage? selectedLanguage;
  final UserRole? selectedRole;
  final String? errorMessage;

  const OnboardingState({
    this.status = OnboardingStatus.initial,
    this.selectedLanguage,
    this.selectedRole,
    this.errorMessage,
  });

  OnboardingState copyWith({
    OnboardingStatus? status,
    AppLanguage? selectedLanguage,
    UserRole? selectedRole,
    String? errorMessage,
  }) {
    return OnboardingState(
      status: status ?? this.status,
      selectedLanguage: selectedLanguage ?? this.selectedLanguage,
      selectedRole: selectedRole ?? this.selectedRole,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        selectedLanguage,
        selectedRole,
        errorMessage,
      ];
}
