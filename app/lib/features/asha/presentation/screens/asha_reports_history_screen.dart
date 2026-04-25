import 'package:flutter/material.dart';
import 'package:jansetu/features/asha/presentation/asha_navigation.dart';
import 'package:jansetu/features/asha/presentation/widgets/asha_scaffold.dart';

class AshaReportsHistoryScreen extends StatelessWidget {
  const AshaReportsHistoryScreen({super.key});

  static const _items = [
    _ReportHistoryItem(
      leading: 'F',
      title: 'F/35 - Fever,\nbreathlessness',
      subtitle: 'Today 9:42 - Pending sync',
      status: 'Queued',
      statusColor: Color(0xFF9C6A00),
      statusBackground: Color(0xFFF9EACA),
      leadingBackground: Color(0xFFFBE7E7),
    ),
    _ReportHistoryItem(
      leading: 'M',
      title: 'M/8 - Possible\nmeasles',
      subtitle: 'Today 9:45 - Pending sync',
      status: 'Refer',
      statusColor: Color(0xFFB14040),
      statusBackground: Color(0xFFFCE7E7),
      leadingBackground: Color(0xFFFBE7E7),
    ),
    _ReportHistoryItem(
      leading: 'Y',
      title: 'M/60 - Diarrhoea',
      subtitle: 'Yesterday - Synced',
      status: 'Sent',
      statusColor: Color(0xFF1E8A65),
      statusBackground: Color(0xFFE4F3EC),
      leadingBackground: Color(0xFFE4F3EC),
    ),
    _ReportHistoryItem(
      leading: 'Y',
      title: 'F/28 - Prenatal\ncheck',
      subtitle: 'Yesterday - Synced',
      status: 'Sent',
      statusColor: Color(0xFF1E8A65),
      statusBackground: Color(0xFFE4F3EC),
      leadingBackground: Color(0xFFE4F3EC),
    ),
    _ReportHistoryItem(
      leading: 'Y',
      title: 'M/4 - Malnutrition',
      subtitle: 'Apr 19 - Synced',
      status: 'Sent',
      statusColor: Color(0xFF1E8A65),
      statusBackground: Color(0xFFE4F3EC),
      leadingBackground: Color(0xFFE4F3EC),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return AshaScaffold(
      title: 'My reports',
      subtitle: 'This month - 48 total',
      activeTab: AshaTab.reports,
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = _items[index];
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
