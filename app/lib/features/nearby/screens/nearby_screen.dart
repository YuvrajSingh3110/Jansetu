import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:jansetu/core/theme/app_theme.dart';
import 'package:jansetu/features/nearby/data/nearby_health_service.dart';
import 'package:url_launcher/url_launcher.dart';

class NearbyScreen extends StatefulWidget {
  const NearbyScreen({super.key});

  @override
  State<NearbyScreen> createState() => _NearbyScreenState();
}

class _NearbyScreenState extends State<NearbyScreen> {
  final NearbyHealthService _nearbyHealthService = NearbyHealthService();
  Future<NearbyHealthResource?>? _resourceFuture;

  @override
  void initState() {
    super.initState();
    _resourceFuture = _nearbyHealthService.findNearbyPhc();
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _callNumber(String number) async {
    final uri = Uri.parse('tel:$number');
    await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: Column(
        children: [
          _NearbyHeader(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              children: [
                FutureBuilder<NearbyHealthResource?>(
                  future: _resourceFuture,
                  builder: (context, snapshot) {
                    final resource = snapshot.data;
                    final loading = snapshot.connectionState == ConnectionState.waiting;

                    return _ResourceCard(
                      icon: Icons.location_on,
                      iconBackground: const Color(0xFF22A879),
                      title: resource?.name ?? 'nearbyPhcFallback'.tr(),
                      subtitle: loading
                          ? 'nearbyLocating'.tr()
                          : _phcSubtitle(context, resource),
                      footer: _phcFooter(context, resource),
                      actionLabel: 'nearbyOpen'.tr(),
                      onAction: resource == null ? null : () => _openUrl(resource.mapsUrl),
                    );
                  },
                ),
                const SizedBox(height: 18),
                _ResourceCard(
                  icon: Icons.person,
                  iconBackground: const Color(0xFF3F8AE0),
                  title: 'nearbyAshaTitle'.tr(),
                  subtitle: 'nearbyAshaSubtitle'.tr(),
                  footer: 'nearbyAshaFooter'.tr(),
                  actionLabel: 'nearbyCall'.tr(),
                  onAction: () => _callNumber('104'),
                ),
                const SizedBox(height: 18),
                _ResourceCard(
                  icon: Icons.call,
                  iconBackground: const Color(0xFFC88212),
                  title: 'nearbyEmergencyTitle'.tr(),
                  subtitle: 'nearbyEmergencySubtitle'.tr(),
                  footer: 'nearbyEmergencyFooter'.tr(),
                  actionLabel: 'nearbyCall'.tr(),
                  actionBackground: const Color(0xFFF7E8C7),
                  actionForeground: const Color(0xFF8A5A09),
                  onAction: () => _callNumber('108'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _phcSubtitle(BuildContext context, NearbyHealthResource? resource) {
    if (resource == null) {
      return 'nearbyUnavailable'.tr();
    }

    if (resource.distanceKm <= 0) {
      return resource.isFallback
          ? 'nearbyTapForDirections'.tr()
          : 'nearbyVeryClose'.tr();
    }

    return 'nearbyDistanceKm'.tr(args: [resource.distanceKm.toStringAsFixed(1)]);
  }

  String _phcFooter(BuildContext context, NearbyHealthResource? resource) {
    if (resource == null) {
      return 'nearbyFallbackFooter'.tr();
    }

    if (resource.status != null && resource.details != null) {
      return '${resource.status} · ${resource.details}';
    }

    if (resource.status != null) {
      return resource.status!;
    }

    if (resource.details != null) {
      return resource.details!;
    }

    return resource.isFallback
        ? 'nearbyFallbackFooter'.tr()
        : 'nearbyTapForDirections'.tr();
  }
}

class _NearbyHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      decoration: const BoxDecoration(
        gradient: AppColors.headerGradient,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'nearbyTitle'.tr(),
            style: AppTextStyles.headerTitle,
          ),
          const SizedBox(height: 8),
          Text(
            'nearbySubtitle'.tr(),
            style: AppTextStyles.headerSubtitle.copyWith(fontSize: 15),
          ),
        ],
      ),
    );
  }
}

class _ResourceCard extends StatelessWidget {
  const _ResourceCard({
    required this.icon,
    required this.iconBackground,
    required this.title,
    required this.subtitle,
    required this.footer,
    required this.actionLabel,
    required this.onAction,
    this.actionBackground = const Color(0xFFDDF3E9),
    this.actionForeground = const Color(0xFF0E6A4F),
  });

  final IconData icon;
  final Color iconBackground;
  final String title;
  final String subtitle;
  final String footer;
  final String actionLabel;
  final VoidCallback? onAction;
  final Color actionBackground;
  final Color actionForeground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F2),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(icon, color: Colors.white, size: 40),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: AppTextStyles.roleTitle.copyWith(
                              fontSize: 18,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            subtitle,
                            style: AppTextStyles.roleSubtitle.copyWith(
                              fontSize: 15,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    TextButton(
                      onPressed: onAction,
                      style: TextButton.styleFrom(
                        backgroundColor: actionBackground,
                        foregroundColor: actionForeground,
                        disabledBackgroundColor: actionBackground.withValues(alpha: 0.55),
                        disabledForegroundColor: actionForeground.withValues(alpha: 0.65),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      child: Text(
                        actionLabel,
                        style: AppTextStyles.buttonText.copyWith(
                          color: actionForeground,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  footer,
                  style: AppTextStyles.roleSubtitle.copyWith(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
