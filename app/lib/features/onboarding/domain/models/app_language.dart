/// Supported languages in Jansetu.
///
/// Each variant carries its native-script label, English name,
/// and BCP-47 locale code so the UI can render bilingually and
/// the system can be localised later.
enum AppLanguage {
  english(nativeLabel: 'English', englishLabel: 'English', localeCode: 'en'),
  hindi(nativeLabel: 'हिंदी', englishLabel: 'Hindi', localeCode: 'hi'),
  odia(nativeLabel: 'ଓଡ଼ିଆ', englishLabel: 'Odia', localeCode: 'or'),
  bengali(nativeLabel: 'বাংলা', englishLabel: 'Bengali', localeCode: 'bn'),
  punjabi(nativeLabel: 'ਪੰਜਾਬੀ', englishLabel: 'Punjabi', localeCode: 'pa'),
  bhojpuri(
      nativeLabel: 'भोजपुरी', englishLabel: 'Bhojpuri', localeCode: 'bho');

  const AppLanguage({
    required this.nativeLabel,
    required this.englishLabel,
    required this.localeCode,
  });

  final String nativeLabel;
  final String englishLabel;
  final String localeCode;

  /// Reverse-lookup from persisted locale code string.
  static AppLanguage? fromCode(String code) {
    try {
      return AppLanguage.values.firstWhere((l) => l.localeCode == code);
    } catch (_) {
      return null;
    }
  }
}
