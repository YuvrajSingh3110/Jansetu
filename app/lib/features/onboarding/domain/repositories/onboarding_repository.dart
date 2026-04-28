import 'package:jansetu/features/onboarding/domain/models/app_language.dart';
import 'package:jansetu/features/onboarding/domain/models/user_role.dart';

/// Contract for persisting and retrieving onboarding preferences.
abstract class OnboardingRepositoryInterface {
  Future<void> saveLanguage(AppLanguage language);
  Future<AppLanguage?> getSavedLanguage();

  Future<void> saveUserRole(UserRole role);
  Future<UserRole?> getSavedUserRole();

  Future<void> saveGender(String gender);
  Future<String?> getSavedGender();

  Future<void> saveAge(int age);
  Future<int?> getSavedAge();

  Future<void> completeOnboarding();
  Future<bool> isOnboardingComplete();
}
