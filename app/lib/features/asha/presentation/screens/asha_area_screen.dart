import 'package:flutter/material.dart';
import 'package:jansetu/features/asha/presentation/asha_navigation.dart';
import 'package:jansetu/features/asha/presentation/widgets/asha_scaffold.dart';

class AshaAreaScreen extends StatelessWidget {
  const AshaAreaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AshaScaffold(
      title: 'Area overview',
      subtitle: 'Catchment clusters - offline cache',
      activeTab: AshaTab.area,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
        children: const [
          _AreaIntroCard(),
          SizedBox(height: 14),
          _AreaMetric(
            title: 'Households visited',
            value: '27',
            color: Color(0xFFE3F2E9),
            valueColor: Color(0xFF1E8A65),
          ),
          SizedBox(height: 12),
          _AreaMetric(
            title: 'Follow-ups due',
            value: '6',
            color: Color(0xFFF9EACA),
            valueColor: Color(0xFF9C6A00),
          ),
          SizedBox(height: 12),
          _AreaMetric(
            title: 'Escalations',
            value: '1',
            color: Color(0xFFFCE7E7),
            valueColor: Color(0xFFB14040),
          ),
        ],
      ),
    );
  }
}

class _AreaIntroCard extends StatelessWidget {
  const _AreaIntroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cluster focus',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF233144),
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Rampur hamlet has 3 pending follow-ups, 1 referral, and 2 unsynced reports. This screen can later host a map and outbreak summary.',
            style: TextStyle(
              fontSize: 17,
              height: 1.45,
              color: Color(0xFF4B5A70),
            ),
          ),
        ],
      ),
    );
  }
}

class _AreaMetric extends StatelessWidget {
  const _AreaMetric({
    required this.title,
    required this.value,
    required this.color,
    required this.valueColor,
  });

  final String title;
  final String value;
  final Color color;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF233144),
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
