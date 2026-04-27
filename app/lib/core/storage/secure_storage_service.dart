import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Thin wrapper around [FlutterSecureStorage] that centralises
/// all key names and provides typed read/write helpers.
class SecureStorageService {
  SecureStorageService._internal();

  static final SecureStorageService _instance =
      SecureStorageService._internal();

  factory SecureStorageService() => _instance;

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // ── Storage keys ────────────────────────────────────────────────
  static const String _keyLanguage = 'jansetu_language';
  static const String _keyUserRole = 'jansetu_user_role';
  static const String _keyOnboardingComplete = 'jansetu_onboarding_complete';
  static const String _keyAshaWorkerProfile = 'jansetu_asha_worker_profile';

  // ── Language ────────────────────────────────────────────────────
  Future<void> writeLanguage(String languageCode) async {
    await _storage.write(key: _keyLanguage, value: languageCode);
  }

  Future<String?> readLanguage() async {
    return _storage.read(key: _keyLanguage);
  }

  // ── User role ───────────────────────────────────────────────────
  Future<void> writeUserRole(String role) async {
    await _storage.write(key: _keyUserRole, value: role);
  }

  Future<String?> readUserRole() async {
    return _storage.read(key: _keyUserRole);
  }

  // ── Onboarding status ───────────────────────────────────────────
  Future<void> markOnboardingComplete() async {
    await _storage.write(key: _keyOnboardingComplete, value: 'true');
  }

  Future<bool> isOnboardingComplete() async {
    final value = await _storage.read(key: _keyOnboardingComplete);
    return value == 'true';
  }

  Future<void> writeAshaWorkerProfile(String jsonValue) async {
    await _storage.write(key: _keyAshaWorkerProfile, value: jsonValue);
  }

  Future<String?> readAshaWorkerProfile() async {
    return _storage.read(key: _keyAshaWorkerProfile);
  }

  // ── Reset (useful for development / testing) ────────────────────
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
