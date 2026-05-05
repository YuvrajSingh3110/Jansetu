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

  /// Actively on the personal details (gender/age) step.
  personalDetails,

  /// Onboarding finished — navigate to home.
  completed,

  /// An error occurred while persisting.
  error,
}

class OnboardingState extends Equatable {
  static const Object _unset = Object();

  final OnboardingStatus status;
  final AppLanguage? selectedLanguage;
  final UserRole? selectedRole;
  final String? selectedGender;
  final int selectedAge;
  final String? errorMessage;

  const OnboardingState({
    this.status = OnboardingStatus.initial,
    this.selectedLanguage,
    this.selectedRole,
    this.selectedGender,
    this.selectedAge = 18,
    this.errorMessage,
  });

  OnboardingState copyWith({
    OnboardingStatus? status,
    Object? selectedLanguage = _unset,
    Object? selectedRole = _unset,
    Object? selectedGender = _unset,
    int? selectedAge,
    Object? errorMessage = _unset,
  }) {
    return OnboardingState(
      status: status ?? this.status,
      selectedLanguage: identical(selectedLanguage, _unset)
          ? this.selectedLanguage
          : selectedLanguage as AppLanguage?,
      selectedRole: identical(selectedRole, _unset)
          ? this.selectedRole
          : selectedRole as UserRole?,
      selectedGender: identical(selectedGender, _unset)
          ? this.selectedGender
          : selectedGender as String?,
      selectedAge: selectedAge ?? this.selectedAge,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }

  @override
  List<Object?> get props => [
    status,
    selectedLanguage,
    selectedRole,
    selectedGender,
    selectedAge,
    errorMessage,
  ];
}
