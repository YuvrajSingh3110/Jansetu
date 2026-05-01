import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:jansetu/features/asha/presentation/asha_navigation.dart';
import 'package:jansetu/features/asha/presentation/screens/asha_profile_screen.dart';

class AshaScaffold extends StatelessWidget {
  const AshaScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.body,
    required this.activeTab,
  });

  final String title;
  final String subtitle;
  final Widget body;
  final AshaTab activeTab;

  static const Color _headerColor = Color(0xFF2368AF);
  static const Color _headerText = Colors.white;
  static const Color _navInactive = Color(0xFF8B97A8);
  static const Color _navActive = Color(0xFF2368AF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
              decoration: const BoxDecoration(
                color: _headerColor,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: _headerText,
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const AshaProfileScreen(),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.account_circle_outlined,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: _headerText.withValues(alpha: 0.88),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: body),
            _AshaBottomNav(activeTab: activeTab),
          ],
        ),
      ),
    );
  }
}

class _AshaBottomNav extends StatelessWidget {
  const _AshaBottomNav({required this.activeTab});

  final AshaTab activeTab;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE4E8EE))),
      ),
      padding: EdgeInsets.only(
        left: 10,
        right: 10,
        top: 6,
        bottom: MediaQuery.of(context).padding.bottom + 6,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: const [
          _NavItem(tab: AshaTab.home, icon: Icons.home_rounded, labelKey: 'navHome'),
          _NavItem(tab: AshaTab.reports, icon: Icons.description_outlined, labelKey: 'navReportsAsha'),
          _NavItem(tab: AshaTab.sync, icon: Icons.sync_rounded, labelKey: 'navSyncAsha'),
          _NavItem(tab: AshaTab.area, icon: Icons.map_outlined, labelKey: 'navAreaAsha'),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.tab,
    required this.icon,
    required this.labelKey,
  });

  final AshaTab tab;
  final IconData icon;
  final String labelKey;

  @override
  Widget build(BuildContext context) {
    final scaffold = context.findAncestorWidgetOfExactType<AshaScaffold>();
    final isActive = scaffold?.activeTab == tab;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: isActive ? null : () => openAshaTab(context, tab, replace: true),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: isActive ? AshaScaffold._navActive : AshaScaffold._navInactive,
            ),
            const SizedBox(height: 4),
            Text(
              labelKey.tr(),
              style: TextStyle(
                color: isActive ? AshaScaffold._navActive : AshaScaffold._navInactive,
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
