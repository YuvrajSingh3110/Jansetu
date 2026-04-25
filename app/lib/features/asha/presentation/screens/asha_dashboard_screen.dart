import 'package:flutter/material.dart';
import 'package:jansetu/core/services/location_service.dart';
import 'package:jansetu/features/asha/presentation/asha_navigation.dart';
import 'package:jansetu/features/asha/presentation/screens/asha_photo_assessment_screen.dart';
import 'package:jansetu/features/asha/presentation/screens/asha_recording_screen.dart';
import 'package:jansetu/features/asha/presentation/widgets/asha_scaffold.dart';

class AshaDashboardScreen extends StatefulWidget {
  const AshaDashboardScreen({super.key});

  @override
  State<AshaDashboardScreen> createState() => _AshaDashboardScreenState();
}

class _AshaDashboardScreenState extends State<AshaDashboardScreen> {
  String _villageName = 'Rampur block';

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    final location = await LocationService().getCurrentLocality(
      fallback: 'Rampur block',
    );
    if (!mounted) return;
    setState(() {
      _villageName = location;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AshaScaffold(
      title: 'ASHA Dashboard',
      subtitle: 'Seema Devi - $_villageName',
      activeTab: AshaTab.home,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
        child: Column(
          children: [
            const Row(
              children: [
                Expanded(
                  child: _StatCard(
                    value: '12',
                    label: 'Today',
                    tint: Color(0xFFE2F2EE),
                    valueColor: Color(0xFF0E7B60),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: _StatCard(
                    value: '3',
                    label: 'Pending\nsync',
                    tint: Color(0xFFF8EEDB),
                    valueColor: Color(0xFF946200),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: _StatCard(
                    value: '1',
                    label: 'Alert',
                    tint: Color(0xFFF8E6E6),
                    valueColor: Color(0xFFC24747),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _PrimaryReportCard(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AshaRecordingScreen()),
                );
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ActionCard(
                    icon: Icons.photo_camera_outlined,
                    label: 'Photo assess',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AshaPhotoAssessmentScreen(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionCard(
                    icon: Icons.sync_rounded,
                    label: 'Sync queue',
                    onTap: () => openAshaTab(context, AshaTab.sync),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.label,
    required this.tint,
    required this.valueColor,
  });

  final String value;
  final String label;
  final Color tint;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 40,
              height: 1,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF3E4B5B),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryReportCard extends StatelessWidget {
  const _PrimaryReportCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(26),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 18),
        decoration: BoxDecoration(
          color: const Color(0xFFEAF3FF),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: const Color(0xFF5B9BF1), width: 1.4),
        ),
        child: Column(
          children: [
            Container(
              width: 92,
              height: 92,
              decoration: const BoxDecoration(
                color: Color(0xFF2368AF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.mic_rounded,
                size: 46,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'New patient report',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Color(0xFF18314F),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Speak in any language',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w500,
                color: Color(0xFF3B6FA8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 22),
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
        child: Column(
          children: [
            Icon(icon, size: 32, color: const Color(0xFF586785)),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF283345),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
