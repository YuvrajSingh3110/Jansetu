import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:jansetu/features/sync_queue/sync_queue_db.dart';

class SyncQueueScreen extends StatefulWidget {
  const SyncQueueScreen({super.key});

  @override
  State<SyncQueueScreen> createState() => _SyncQueueScreenState();
}

class _SyncQueueScreenState extends State<SyncQueueScreen> {
  final SyncQueueDatabase _db = SyncQueueDatabase.instance;

  List<_QueueListItem> _items = const [];
  int _pendingCount = 0;
  int _pendingSize = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final reports = await _db.getAllReports();
    final pendingCount = await _db.getPendingCount();
    final pendingSize = await _db.getPendingSize();
    if (!mounted) return;
    setState(() {
      _items = reports.map(_QueueListItem.fromRow).toList();
      _pendingCount = pendingCount;
      _pendingSize = pendingSize;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
              decoration: const BoxDecoration(
                color: Color(0xFF2368AF),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ashaSyncQueueTitle'.tr(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ashaSyncQueueSubtitle'.tr(),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                        children: [
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8EFD8),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Text(
                              'ashaSyncQueueSummary'
                                  .tr(args: ['$_pendingCount']),
                              style: const TextStyle(
                                height: 1.55,
                                fontSize: 18,
                                color: Color(0xFF7A5B00),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (_items.isEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 30),
                              child: Center(
                                child: Text(
                                  'ashaSyncQueueEmpty'.tr(),
                                  style: const TextStyle(
                                    color: Color(0xFF6C7889),
                                  ),
                                ),
                              ),
                            )
                          else
                            ..._items.map(
                              (item) => Column(
                                children: [
                                  _QueueCell(item: item),
                                  const Divider(
                                    height: 1,
                                    color: Color(0xFFE7EAF0),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              const _LegendDot(color: Color(0xFFF2A324)),
                              const SizedBox(width: 6),
                              Text(
                                'ashaSyncQueuePending'.tr(),
                                style: _legendStyle(),
                              ),
                              const SizedBox(width: 18),
                              const _LegendDot(color: Color(0xFF18A26E)),
                              const SizedBox(width: 6),
                              Text(
                                'ashaSyncQueueSent'.tr(),
                                style: _legendStyle(),
                              ),
                              const Spacer(),
                              Text(
                                'ashaSyncQueueTotal'.tr(
                                  args: [
                                    (_pendingSize / 1024).toStringAsFixed(1),
                                  ],
                                ),
                                style: _legendStyle(),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QueueCell extends StatelessWidget {
  const _QueueCell({required this.item});

  final _QueueListItem item;

  @override
  Widget build(BuildContext context) {
    final statusColor =
        item.isSent ? const Color(0xFF18A26E) : const Color(0xFFF2A324);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: _LegendDot(color: statusColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 18,
                    height: 1.3,
                    color: Color(0xFF182434),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF7D8796),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${(item.payloadSize / 1024).toStringAsFixed(1)} KB',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF8A94A5),
            ),
          ),
        ],
      ),
    );
  }
}

class _QueueListItem {
  const _QueueListItem({
    required this.title,
    required this.subtitle,
    required this.payloadSize,
    required this.isSent,
  });

  final String title;
  final String subtitle;
  final int payloadSize;
  final bool isSent;

  factory _QueueListItem.fromRow(Map<String, dynamic> row) {
    Map<String, dynamic> payload = const {};
    try {
      payload =
          jsonDecode(row['payload']?.toString() ?? '{}') as Map<String, dynamic>;
    } catch (_) {}

    final gender = payload['gender']?.toString() ?? 'U';
    final ageGroup = payload['ageGroup']?.toString() ?? 'adult';
    final ageLabel = switch (ageGroup) {
      'child' => 'Child',
      'elderly' => '60+',
      _ => 'Adult',
    };
    final symptoms = ((payload['symptoms'] as List?) ?? const [])
        .map((item) => item.toString())
        .toList();
    final symptomLabel = symptoms.isEmpty
        ? 'General check'
        : symptoms.map(_prettySymptom).join(', ');
    final village = payload['villageName']?.toString().trim().isNotEmpty == true
        ? payload['villageName']!.toString()
        : payload['villageId']?.toString().replaceFirst('clv', '') ??
            'Village';
    final status = row['status']?.toString() ?? 'PENDING';
    final timestamp = DateTime.tryParse(row['timestamp']?.toString() ?? '');
    final timeLabel =
        timestamp == null ? 'Unknown' : _formatTimestamp(timestamp.toLocal());

    return _QueueListItem(
      title: '$gender/$ageLabel · $symptomLabel',
      subtitle: status == 'SENT'
          ? '$timeLabel · ${'ashaSyncQueueSentShort'.tr()}'
          : '$timeLabel · ${_titleCaseVillage(village)}',
      payloadSize: (row['payload_size'] as num?)?.toInt() ?? 0,
      isSent: status == 'SENT',
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

TextStyle _legendStyle() {
  return const TextStyle(
    fontSize: 14,
    color: Color(0xFF7D8796),
  );
}

String _prettySymptom(String raw) {
  final withSpaces = raw.replaceAll('_', ' ');
  return withSpaces.isEmpty
      ? withSpaces
      : '${withSpaces[0].toUpperCase()}${withSpaces.substring(1)}';
}

String _titleCaseVillage(String value) {
  if (value.isEmpty) return value;
  return '${value[0].toUpperCase()}${value.substring(1)}';
}

String _formatTimestamp(DateTime time) {
  final now = DateTime.now();
  final isToday =
      now.year == time.year && now.month == time.month && now.day == time.day;
  final hour =
      time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
  final minute = time.minute.toString().padLeft(2, '0');
  return isToday ? 'Today $hour:$minute' : 'Yesterday';
}
