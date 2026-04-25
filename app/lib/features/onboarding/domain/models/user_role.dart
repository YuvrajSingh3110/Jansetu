/// The two primary user personas in Jansetu.
enum UserRole {
  healthWorker(
    title: 'ASHA / ANM / CHW',
    hindiTitle: 'स्वास्थ्य कार्यकर्ता',
    subtitle: 'Health worker — report cases',
    hindiSubtitle: 'स्वास्थ्य कार्यकर्ता — मामले रिपोर्ट करें',
  ),
  villagePerson(
    title: 'ग्रामवासी · Village person',
    hindiTitle: 'ग्रामवासी',
    subtitle: 'Check symptoms, get guidance',
    hindiSubtitle: 'लक्षण जांचें, मार्गदर्शन पाएं',
  );

  const UserRole({
    required this.title,
    required this.hindiTitle,
    required this.subtitle,
    required this.hindiSubtitle,
  });

  final String title;
  final String hindiTitle;
  final String subtitle;
  final String hindiSubtitle;

  /// Reverse-lookup from persisted name string.
  static UserRole? fromName(String name) {
    try {
      return UserRole.values.firstWhere((r) => r.name == name);
    } catch (_) {
      return null;
    }
  }
}
