import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jansetu/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:jansetu/features/onboarding/presentation/bloc/onboarding_event.dart';
import 'package:jansetu/features/onboarding/presentation/bloc/onboarding_state.dart';

class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  final OnboardingRepositoryInterface _repository;

  OnboardingBloc({required OnboardingRepositoryInterface repository})
      : _repository = repository,
        super(const OnboardingState()) {
    on<OnboardingStatusChecked>(_onStatusChecked);
    on<LanguageSelected>(_onLanguageSelected);
    on<LanguageContinuePressed>(_onLanguageContinue);
    on<RoleSelected>(_onRoleSelected);
    on<OnboardingCompleted>(_onCompleted);
  }

  /// Check if the user already completed onboarding (app start-up).
  Future<void> _onStatusChecked(
    OnboardingStatusChecked event,
    Emitter<OnboardingState> emit,
  ) async {
    try {
      final isComplete = await _repository.isOnboardingComplete();
      if (isComplete) {
        final savedLanguage = await _repository.getSavedLanguage();
        final savedRole = await _repository.getSavedUserRole();
        emit(state.copyWith(
          status: OnboardingStatus.completed,
          selectedLanguage: savedLanguage,
          selectedRole: savedRole,
        ));
      } else {
        emit(state.copyWith(status: OnboardingStatus.languageSelect));
      }
    } catch (e) {
      emit(state.copyWith(
        status: OnboardingStatus.languageSelect,
        errorMessage: e.toString(),
      ));
    }
  }

  /// User tapped a language card.
  void _onLanguageSelected(
    LanguageSelected event,
    Emitter<OnboardingState> emit,
  ) {
    emit(state.copyWith(selectedLanguage: event.language));
  }

  /// User pressed "Continue" after selecting a language.
  Future<void> _onLanguageContinue(
    LanguageContinuePressed event,
    Emitter<OnboardingState> emit,
  ) async {
    if (state.selectedLanguage == null) return;
    try {
      await _repository.saveLanguage(state.selectedLanguage!);
      emit(state.copyWith(status: OnboardingStatus.roleSelect));
    } catch (e) {
      emit(state.copyWith(
        status: OnboardingStatus.error,
        errorMessage: 'Failed to save language: $e',
      ));
    }
  }

  /// User tapped a role card.
  void _onRoleSelected(
    RoleSelected event,
    Emitter<OnboardingState> emit,
  ) {
    emit(state.copyWith(selectedRole: event.role));
  }

  /// User confirmed role → persist everything and mark complete.
  Future<void> _onCompleted(
    OnboardingCompleted event,
    Emitter<OnboardingState> emit,
  ) async {
    if (state.selectedRole == null) return;
    try {
      await _repository.saveUserRole(state.selectedRole!);
      await _repository.completeOnboarding();
      emit(state.copyWith(status: OnboardingStatus.completed));
    } catch (e) {
      emit(state.copyWith(
        status: OnboardingStatus.error,
        errorMessage: 'Failed to complete onboarding: $e',
      ));
    }
  }
}
