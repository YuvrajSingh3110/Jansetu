import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:jansetu/core/theme/app_theme.dart';
import 'package:jansetu/core/services/location_service.dart';
import 'package:jansetu/core/widgets/image_source_sheet.dart';
import 'package:jansetu/core/services/speech_service.dart';
import 'package:jansetu/features/alerts/screens/alert_detail_screen.dart';
import 'package:jansetu/features/chat/presentation/screens/chat_screen.dart';
import 'package:jansetu/features/history/screens/history_screen.dart';
import 'package:jansetu/features/nearby/screens/nearby_screen.dart';
import 'package:jansetu/features/onboarding/presentation/bloc/onboarding_bloc.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _villageName = '...';
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    final location = await LocationService().getCurrentLocality(
      fallback: 'Village',
    );
    if (mounted) {
      setState(() {
        _villageName = location;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: IndexedStack(
                index: _selectedIndex,
                children: [
                  _buildHomeView(),
                  const NearbyScreen(),
                  const HistoryScreen(),
                ],
              ),
            ),
            _buildBottomNav(),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeView() {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              children: [
                _buildAlertBox(),
                const SizedBox(height: 24),
                _buildMicCard(),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _buildActionCard(
                        icon: Icons.camera_alt,
                        iconColor: Colors.black87,
                        title: 'photoCheckTitle'.tr(),
                        subtitle: 'photoCheckSubtitle'.tr(),
                        onTap: _openPhotoCheck,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildActionCard(
                        icon: Icons.medication,
                        iconColor: Colors.amber.shade700,
                        title: 'medicinesTitle'.tr(),
                        subtitle: 'medicinesSubtitle'.tr(),
                        onTap: () {},
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      decoration: const BoxDecoration(gradient: AppColors.headerGradient),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'namaste'.tr(),
            style: AppTextStyles.headerTitle.copyWith(fontSize: 28),
          ),
          const SizedBox(height: 8),
          Text(
            'homeGreeting'.tr(args: [_villageName]),
            style: AppTextStyles.headerSubtitle.copyWith(fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertBox() {
    return InkWell(
      onTap: () {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const AlertDetailScreen()));
      },
      borderRadius: BorderRadius.circular(4),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFDECEA),
          border: const Border(
            left: BorderSide(color: Color(0xFFD32F2F), width: 4),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFD32F2F),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'alertTitle'.tr(),
                    style: const TextStyle(
                      color: Color(0xFFB71C1C),
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'alertSubtitle'.tr(),
              style: const TextStyle(
                color: Color(0xFF7F0000),
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startMicRecording() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (BuildContext bottomSheetContext) {
        return const _ListeningBottomSheet();
      },
    ).then((finalText) {
      if (!mounted) return;
      if (finalText != null && finalText is String && finalText.isNotEmpty) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ChatScreen(initialPrompt: finalText),
          ),
        );
      }
    });
  }

  Widget _buildMicCard() {
    return InkWell(
      onTap: _startMicRecording,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5EE),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.primary, width: 2),
        ),
        child: Column(
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.mic, color: Colors.white, size: 48),
            ),
            const SizedBox(height: 24),
            Text(
              'micTitle'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.primaryDark,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'micSubtitle'.tr(),
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.cardFill,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: iconColor),
            const SizedBox(height: 16),
            Text(
              title,
              style: AppTextStyles.roleTitle.copyWith(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: AppTextStyles.roleSubtitle.copyWith(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openPhotoCheck() async {
    final pickedImage = await showImageSourceSheet(context);
    if (!mounted || pickedImage == null) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          initialImageBytes: pickedImage.bytes,
          initialImageName: pickedImage.name,
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.borderLight)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            icon: Icons.home,
            label: 'navHome'.tr(),
            isActive: _selectedIndex == 0,
            onTap: () => setState(() => _selectedIndex = 0),
          ),
          _buildNavItem(
            icon: Icons.location_on_outlined,
            label: 'navNearby'.tr(),
            isActive: _selectedIndex == 1,
            onTap: () => setState(() => _selectedIndex = 1),
          ),
          _buildNavItem(
            icon: Icons.assignment_outlined,
            label: 'navHistory'.tr(),
            isActive: _selectedIndex == 2,
            onTap: () => setState(() => _selectedIndex = 2),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    bool isActive = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap ?? () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? AppColors.primary : AppColors.textSecondary,
              size: 26,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? AppColors.primary : AppColors.textSecondary,
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListeningBottomSheet extends StatefulWidget {
  const _ListeningBottomSheet();

  @override
  State<_ListeningBottomSheet> createState() => _ListeningBottomSheetState();
}

class _ListeningBottomSheetState extends State<_ListeningBottomSheet> {
  final SpeechService _speechService = SpeechService();
  String _currentText = '';

  @override
  void initState() {
    super.initState();
    _startListening();
  }

  Future<void> _startListening() async {
    final langCode =
        context.read<OnboardingBloc>().state.selectedLanguage?.localeCode ??
        'hi';
    await _speechService.startListening(
      localeId: langCode,
      onResult: (text, _) {
        if (mounted) {
          setState(() {
            _currentText = text;
          });
        }
      },
    );
  }

  Future<void> _stopListeningAndSubmit() async {
    await _speechService.stopListening();
    if (!mounted) return;
    Navigator.of(context).pop(_currentText);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Listening...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _currentText.isEmpty ? 'Speak now...' : _currentText,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          GestureDetector(
            onTap: _stopListeningAndSubmit,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.redAccent,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.redAccent.withValues(alpha: 0.4),
                    blurRadius: 10,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Icon(Icons.stop, color: Colors.white, size: 40),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Tap to stop',
            style: TextStyle(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
