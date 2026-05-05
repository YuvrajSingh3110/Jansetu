import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:jansetu/features/asha/data/asha_models.dart';
import 'package:jansetu/features/asha/data/asha_repository.dart';
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
  final AshaRepository _repository = AshaRepository();
  DashboardData? _dashboardData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    try {
      final dashboard = await _repository.loadDashboardData();
      if (!mounted) return;
      setState(() {
        _dashboardData = dashboard;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null || _dashboardData == null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_errorMessage ?? 'ashaDashboardLoadError'.tr()),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _loadDashboard,
                  child: Text('ashaRetry'.tr()),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final data = _dashboardData!;
    final latestAlert = data.alerts.isEmpty ? null : data.alerts.first;

    return AshaScaffold(
      title: 'ashaDashboardTitle'.tr(),
      subtitle: '${data.profile.name} - ${data.profile.block.name}',
      activeTab: AshaTab.home,
      body: RefreshIndicator(
        onRefresh: _loadDashboard,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      value: '${data.profile.reportsCount}',
                      label: 'ashaDashboardReports'.tr(),
                      tint: const Color(0xFFE2F2EE),
                      valueColor: const Color(0xFF0E7B60),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatCard(
                      value: '${data.pendingSyncCount}',
                      label: 'ashaDashboardPendingSync'.tr(),
                      tint: const Color(0xFFF8EEDB),
                      valueColor: const Color(0xFF946200),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatCard(
                      value: '${data.alerts.length}',
                      label: 'ashaDashboardAlerts'.tr(),
                      tint: const Color(0xFFF8E6E6),
                      valueColor: const Color(0xFFC24747),
                    ),
                  ),
                ],
              ),
              if (data.clockDriftWarning != null) ...[
                const SizedBox(height: 12),
                _InfoBanner(
                  message: data.clockDriftWarning!,
                  background: const Color(0xFFF8EEDB),
                  foreground: const Color(0xFF946200),
                ),
              ],
              if (latestAlert != null) ...[
                const SizedBox(height: 12),
                _InfoBanner(
                  message: latestAlert.title,
                  subtitle: '${latestAlert.caseCount} cases across ${latestAlert.affectedVillages.join(', ')}',
                  background: const Color(0xFFFBE7E7),
                  foreground: const Color(0xFFB14040),
                ),
              ],
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
                      label: 'ashaDashboardPhotoAssess'.tr(),
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
                      label: 'ashaDashboardSyncQueue'.tr(),
                      onTap: () => openAshaTab(context, AshaTab.sync),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({
    required this.message,
    required this.background,
    required this.foreground,
    this.subtitle,
  });

  final String message;
  final String? subtitle;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: foreground,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 14,
                color: foreground,
              ),
            ),
          ],
        ],
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
            Text(
              'ashaDashboardNewPatientReport'.tr(),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Color(0xFF18314F),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'ashaDashboardSpeakAnyLanguage'.tr(),
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
