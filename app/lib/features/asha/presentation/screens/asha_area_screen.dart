import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:jansetu/features/asha/data/asha_models.dart';
import 'package:jansetu/features/asha/data/asha_repository.dart';
import 'package:jansetu/features/asha/presentation/asha_navigation.dart';
import 'package:jansetu/features/asha/presentation/widgets/asha_scaffold.dart';
import 'package:latlong2/latlong.dart';

class AshaAreaScreen extends StatefulWidget {
  const AshaAreaScreen({super.key});

  @override
  State<AshaAreaScreen> createState() => _AshaAreaScreenState();
}

class _AshaAreaScreenState extends State<AshaAreaScreen> {
  final AshaRepository _repository = AshaRepository();

  ChwProfile? _profile;
  List<AshaAlert> _alerts = const [];
  List<VillageCaseTrend> _trends = const [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMapData();
  }

  Future<void> _loadMapData() async {
    try {
      final profile = await _repository.getActiveProfile();
      final alerts = await _repository.loadCachedAlerts();
      final trends = await _repository.loadVillageCaseTrends();
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _alerts = alerts;
        _trends = trends;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AshaScaffold(
      title: 'ashaAreaTitle'.tr(),
      subtitle: 'ashaAreaSubtitle'.tr(),
      activeTab: AshaTab.area,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                  children: [
                    _AreaIntroCard(alerts: _alerts, trends: _trends),
                    const SizedBox(height: 14),
                    _ClusterMapCard(
                      villages: _profile?.block.villages ?? const [],
                      alerts: _alerts,
                      trends: _trends,
                    ),
                    const SizedBox(height: 14),
                    _AreaMetric(
                      title: 'ashaAreaHouseholdsVisited'.tr(),
                      value: '${_trends.fold<int>(0, (sum, trend) => sum + trend.totalCases)}',
                      color: const Color(0xFFE3F2E9),
                      valueColor: const Color(0xFF1E8A65),
                    ),
                    const SizedBox(height: 12),
                    _AreaMetric(
                      title: 'ashaAreaFollowUpsDue'.tr(),
                      value: '${_trends.fold<int>(0, (sum, trend) => sum + trend.pendingCases)}',
                      color: const Color(0xFFF9EACA),
                      valueColor: const Color(0xFF9C6A00),
                    ),
                    const SizedBox(height: 12),
                    _AreaMetric(
                      title: 'ashaAreaEscalations'.tr(),
                      value: '${_trends.where((trend) => trend.topSymptomCount >= 2).length}',
                      color: const Color(0xFFFCE7E7),
                      valueColor: const Color(0xFFB14040),
                    ),
                  ],
                ),
    );
  }
}

class _AreaIntroCard extends StatelessWidget {
  const _AreaIntroCard({
    required this.alerts,
    required this.trends,
  });

  final List<AshaAlert> alerts;
  final List<VillageCaseTrend> trends;

  @override
  Widget build(BuildContext context) {
    final hottestTrend = trends.isEmpty ? null : trends.first;
    final headline = hottestTrend != null
        ? '${_prettySymptom(hottestTrend.topSymptom)} is increasing in ${hottestTrend.villageName} (${hottestTrend.topSymptomCount} cases, ${hottestTrend.totalCases} total reports).'
        // ignore: lines_longer_than_80_chars
        : alerts.isEmpty
            ? 'ashaAreaNoClusters'.tr()
            : alerts.first.description;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ashaAreaClusterFocus'.tr(),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF233144),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            headline,
            style: const TextStyle(
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

class _ClusterMapCard extends StatelessWidget {
  const _ClusterMapCard({
    required this.villages,
    required this.alerts,
    required this.trends,
  });

  final List<ChwVillage> villages;
  final List<AshaAlert> alerts;
  final List<VillageCaseTrend> trends;

  @override
  Widget build(BuildContext context) {
    final center = villages.isEmpty
        ? const LatLng(25.4358, 82.9109)
        : LatLng(
            villages.map((village) => village.lat).reduce((a, b) => a + b) / villages.length,
            villages.map((village) => village.lng).reduce((a, b) => a + b) / villages.length,
          );
    final highlightedNames = alerts.expand((alert) => alert.affectedVillages).toSet();
    final highlightedPoints = villages
        .where((village) => highlightedNames.contains(village.name))
        .map((village) => LatLng(village.lat, village.lng))
        .toList();
    final maxCases = trends.isEmpty
        ? 1
        : trends.map((trend) => trend.totalCases).reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(12),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 280,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: center,
                  initialZoom: 12.2,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.jansetu',
                  ),
                  if (highlightedPoints.length >= 2)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: highlightedPoints,
                          strokeWidth: 4,
                          color: const Color(0xFFC24747),
                        ),
                      ],
                    ),
                  if (trends.isNotEmpty)
                    CircleLayer(
                      circles: trends
                          .map(
                            (trend) => CircleMarker(
                              point: LatLng(trend.lat, trend.lng),
                              radius: 12 + ((trend.totalCases / maxCases) * 24),
                              color: const Color(0xFFC24747).withValues(alpha: 0.18),
                              borderStrokeWidth: 2,
                              borderColor: const Color(0xFFC24747),
                            ),
                          )
                          .toList(),
                    ),
                  MarkerLayer(
                    markers: villages
                        .map(
                          (village) => Marker(
                            point: LatLng(village.lat, village.lng),
                            width: 90,
                            height: 54,
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: highlightedNames.contains(village.name)
                                        ? const Color(0xFFC24747)
                                        : const Color(0xFF2368AF),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    village.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Icon(
                                  Icons.location_on,
                                  color: highlightedNames.contains(village.name)
                                      ? const Color(0xFFC24747)
                                      : const Color(0xFF2368AF),
                                  size: 24,
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'ashaAreaMapCaption'.tr(),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6C7889),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            alerts.isEmpty
                ? 'ashaAreaNoAlertLine'.tr()
                : 'ashaAreaHighlightedVillages'.tr(),
            style: const TextStyle(
              fontSize: 14,
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

String _prettySymptom(String raw) {
  return raw
      .split('_')
      .map((part) => part.isEmpty ? part : '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}
