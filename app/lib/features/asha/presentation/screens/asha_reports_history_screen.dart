import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:jansetu/features/asha/data/asha_repository.dart';
import 'package:jansetu/features/asha/presentation/asha_navigation.dart';
import 'package:jansetu/features/asha/presentation/widgets/asha_scaffold.dart';

class AshaReportsHistoryScreen extends StatefulWidget {
  const AshaReportsHistoryScreen({super.key});

  @override
  State<AshaReportsHistoryScreen> createState() => _AshaReportsHistoryScreenState();
}

class _AshaReportsHistoryScreenState extends State<AshaReportsHistoryScreen> {
  final AshaRepository _repository = AshaRepository();

  late Future<AshaReportsHistoryData> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = _repository.loadReportsHistory();
  }

  Future<void> _reload() async {
    final future = _repository.loadReportsHistory();
    setState(() => _historyFuture = future);
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return AshaScaffold(
      title: 'navReportsAsha'.tr(),
      subtitle: 'historySubtitle'.tr(),
      activeTab: AshaTab.reports,
      body: FutureBuilder<AshaReportsHistoryData>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'ashaDashboardLoadError'.tr(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF6C7889),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _reload,
                      child: Text('ashaRetry'.tr()),
                    ),
                  ],
                ),
              ),
            );
          }

          final data = snapshot.data ??
              const AshaReportsHistoryData(totalCount: 0, items: []);

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
              itemCount: data.items.length + 1,
              separatorBuilder: (_, index) =>
                  index == 0 ? const SizedBox(height: 14) : const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Text(
                    _monthSummary(context, data.totalCount),
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF6C7889),
                      fontWeight: FontWeight.w600,
                    ),
                  );
                }

                final item = _buildItem(context, data.items[index - 1]);
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: item.leadingBackground,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Text(
                            item.leading,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: const TextStyle(
                                fontSize: 19,
                                height: 1.25,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF233144),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.subtitle,
                              style: const TextStyle(
                                fontSize: 14,
                                height: 1.35,
                                color: Color(0xFF6C7889),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: item.statusBackground,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          item.status,
                          style: TextStyle(
                            color: item.statusColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  _ReportHistoryItem _buildItem(
    BuildContext context,
    AshaReportHistoryItem item,
  ) {
    final localizedSymptoms = item.symptoms.isEmpty
        ? [_term(context, 'general_check')]
        : item.symptoms.map((symptom) => _term(context, symptom)).toList();
    final gender = switch (item.genderCode.toUpperCase()) {
      'F' => _term(context, 'female'),
      'M' => _term(context, 'male'),
      _ => null,
    };
    final titlePrefix = gender == null ? '' : '$gender · ';
    final subtitle = item.isSent
        ? '${_formatRelativeTime(context, item.timestamp)} · ${_term(context, 'sent')}'
        : '${_formatRelativeTime(context, item.timestamp)} · ${_titleCase(item.villageName)}';

    return _ReportHistoryItem(
      leading: item.isSent ? '✓' : ((gender != null && gender.isNotEmpty) ? gender[0] : '•'),
      title: '$titlePrefix${localizedSymptoms.join(', ')}',
      subtitle: subtitle,
      status: _statusLabel(context, item),
      statusColor: item.needsReferral
          ? const Color(0xFFB14040)
          : item.isSent
              ? const Color(0xFF1E8A65)
              : const Color(0xFF9C6A00),
      statusBackground: item.needsReferral
          ? const Color(0xFFFCE7E7)
          : item.isSent
              ? const Color(0xFFE4F3EC)
              : const Color(0xFFF9EACA),
      leadingBackground: item.isSent
          ? const Color(0xFFE4F3EC)
          : const Color(0xFFFBE7E7),
    );
  }
}

class _ReportHistoryItem {
  const _ReportHistoryItem({
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.statusColor,
    required this.statusBackground,
    required this.leadingBackground,
  });

  final String leading;
  final String title;
  final String subtitle;
  final String status;
  final Color statusColor;
  final Color statusBackground;
  final Color leadingBackground;
}

String _statusLabel(BuildContext context, AshaReportHistoryItem item) {
  if (item.needsReferral && !item.isSent) {
    return _term(context, 'refer');
  }
  if (item.isSent) {
    return _term(context, 'sent');
  }
  return _term(context, 'queued');
}

String _monthSummary(BuildContext context, int count) {
  if (context.locale.languageCode == 'hi') {
    return 'इस महीने · $count कुल';
  }
  return 'This month · $count total';
}

String _formatRelativeTime(BuildContext context, DateTime? timestamp) {
  if (timestamp == null) {
    return _term(context, 'unknown');
  }

  final local = timestamp.toLocal();
  final now = DateTime.now();
  final isToday =
      now.year == local.year && now.month == local.month && now.day == local.day;
  final yesterday = now.subtract(const Duration(days: 1));
  final isYesterday = yesterday.year == local.year &&
      yesterday.month == local.month &&
      yesterday.day == local.day;
  final time = DateFormat('h:mm', context.locale.toLanguageTag()).format(local);

  if (isToday) {
    return '${_term(context, 'today')} $time';
  }
  if (isYesterday) {
    return _term(context, 'yesterday');
  }
  return DateFormat.MMMd(context.locale.toLanguageTag()).format(local);
}

String _titleCase(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return trimmed;
  }
  return '${trimmed[0].toUpperCase()}${trimmed.substring(1)}';
}

String _term(BuildContext context, String key) {
  const terms = {
    'en': {
      'male': 'Male',
      'female': 'Female',
      'queued': 'Queued',
      'sent': 'Sent',
      'refer': 'Refer',
      'today': 'Today',
      'yesterday': 'Yesterday',
      'unknown': 'Unknown',
      'general_check': 'General check',
      'fever': 'Fever',
      'cough': 'Cough',
      'breathlessness': 'Breathlessness',
      'diarrhoea': 'Diarrhoea',
      'vomiting': 'Vomiting',
      'rash': 'Rash',
      'headache': 'Headache',
      'bodyache': 'Body ache',
      'sore_throat': 'Sore throat',
      'runny_nose': 'Runny nose',
      'malnutrition': 'Malnutrition',
      'jaundice': 'Jaundice',
      'conjunctivitis': 'Conjunctivitis',
      'seizure': 'Seizure',
      'unconscious': 'Unconscious',
      'bleeding': 'Bleeding',
    },
    'hi': {
      'male': 'पुरुष',
      'female': 'महिला',
      'queued': 'कतार में',
      'sent': 'भेजा गया',
      'refer': 'रेफर',
      'today': 'आज',
      'yesterday': 'कल',
      'unknown': 'अज्ञात',
      'general_check': 'सामान्य जांच',
      'fever': 'बुखार',
      'cough': 'खांसी',
      'breathlessness': 'सांस फूलना',
      'diarrhoea': 'दस्त',
      'vomiting': 'उल्टी',
      'rash': 'चकत्ते',
      'headache': 'सिरदर्द',
      'bodyache': 'शरीर दर्द',
      'sore_throat': 'गले में दर्द',
      'runny_nose': 'नाक बहना',
      'malnutrition': 'कुपोषण',
      'jaundice': 'पीलिया',
      'conjunctivitis': 'आंख आना',
      'seizure': 'दौरा',
      'unconscious': 'बेहोशी',
      'bleeding': 'रक्तस्राव',
    },
  };

  final languageCode = context.locale.languageCode;
  final localized = terms[languageCode]?[key];
  if (localized != null) {
    return localized;
  }
  return terms['en']![key] ?? key.replaceAll('_', ' ');
}
