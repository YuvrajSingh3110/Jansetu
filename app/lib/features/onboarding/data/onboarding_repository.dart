import 'package:jansetu/core/storage/secure_storage_service.dart';
import 'package:jansetu/features/onboarding/domain/models/app_language.dart';
import 'package:jansetu/features/onboarding/domain/models/user_role.dart';
import 'package:jansetu/features/onboarding/domain/repositories/onboarding_repository.dart';

/// Concrete implementation that delegates to [SecureStorageService].
class OnboardingRepository implements OnboardingRepositoryInterface {
  final SecureStorageService _storage;

  OnboardingRepository({SecureStorageService? storage})
      : _storage = storage ?? SecureStorageService();

  @override
  Future<void> saveLanguage(AppLanguage language) async {
    await _storage.writeLanguage(language.localeCode);
  }

  @override
  Future<AppLanguage?> getSavedLanguage() async {
    final code = await _storage.readLanguage();
    if (code == null) return null;
    return AppLanguage.fromCode(code);
  }

  @override
  Future<void> saveUserRole(UserRole role) async {
    await _storage.writeUserRole(role.name);
  }

  @override
  Future<UserRole?> getSavedUserRole() async {
    final name = await _storage.readUserRole();
    if (name == null) return null;
    return UserRole.fromName(name);
  }

  @override
  Future<void> saveGender(String gender) async {
    await _storage.writeGender(gender);
  }

  @override
  Future<String?> getSavedGender() async {
    return _storage.readGender();
  }

  @override
  Future<void> saveAge(int age) async {
    await _storage.writeAge(age);
  }

  @override
  Future<int?> getSavedAge() async {
    return _storage.readAge();
  }

  @override
  Future<void> completeOnboarding() async {
    await _storage.markOnboardingComplete();
  }

  @override
  Future<bool> isOnboardingComplete() async {
    return _storage.isOnboardingComplete();
  }

  @override
  Future<void> clearAll() async {
    await _storage.clearAll();
  }
}
