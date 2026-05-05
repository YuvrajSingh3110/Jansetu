import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jansetu/core/storage/secure_storage_service.dart';
import 'package:jansetu/features/asha/data/asha_cache_db.dart';
import 'package:jansetu/features/asha/data/asha_repository.dart';
import 'package:jansetu/features/asha/data/asha_worker_profile_repository.dart';
import 'package:jansetu/features/asha/presentation/screens/asha_profile_questionnaire_screen.dart';
import 'package:jansetu/features/onboarding/presentation/bloc/onboarding_bloc.dart';
import 'package:jansetu/features/onboarding/presentation/bloc/onboarding_event.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jansetu/features/sync_queue/sync_queue_db.dart';

class AshaProfileScreen extends StatefulWidget {
  const AshaProfileScreen({super.key});

  @override
  State<AshaProfileScreen> createState() => _AshaProfileScreenState();
}

class _AshaProfileScreenState extends State<AshaProfileScreen> {
  final AshaWorkerProfileRepository _profileRepository =
      AshaWorkerProfileRepository();
  final AshaRepository _ashaRepository = AshaRepository();
  final ImagePicker _imagePicker = ImagePicker();
  final SecureStorageService _secureStorage = SecureStorageService();

  AshaWorkerProfile? _profile;
  String? _apiBlock;
  int? _reportsCount;
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await _profileRepository.loadProfile();
    final apiProfile = await _ashaRepository.loadCachedProfile();
    if (!mounted) return;
    setState(() {
      _profile = profile;
      _apiBlock = apiProfile?.block.name;
      _reportsCount = apiProfile?.reportsCount;
    });
  }

  Future<void> _changeProfilePhoto() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked == null) return;
    final appDir = await getApplicationDocumentsDirectory();
    final profileDir = Directory(p.join(appDir.path, 'profile_photos'));
    if (!await profileDir.exists()) {
      await profileDir.create(recursive: true);
    }
    final targetPath = p.join(
      profileDir.path,
      'profile_${DateTime.now().millisecondsSinceEpoch}${p.extension(picked.path).isEmpty ? '.jpg' : p.extension(picked.path)}',
    );
    final saved = await File(picked.path).copy(targetPath);
    await _profileRepository.updateProfileImage(saved.path);
    await _loadProfile();
  }

  Future<void> _logout() async {
    if (_isLoggingOut) return;
    setState(() => _isLoggingOut = true);
    try {
      await _secureStorage.clearAll();
      await _profileRepository.clearProfile();
      await AshaCacheDatabase.instance.clearAll();
      await SyncQueueDatabase.instance.clearAllReports();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('device_uuid');
      if (!mounted) return;
      context.read<OnboardingBloc>().add(const OnboardingResetRequested());
      Navigator.of(context).popUntil((route) => route.isFirst);
    } finally {
      if (mounted) {
        setState(() => _isLoggingOut = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: Text('ashaProfileTitle'.tr()),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: profile == null
                ? null
                : () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AshaProfileQuestionnaireScreen(
                          initialProfile: profile,
                        ),
                      ),
                    );
                    await _loadProfile();
                  },
          ),
        ],
      ),
      body: profile == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _changeProfilePhoto,
                        child: CircleAvatar(
                          radius: 46,
                          backgroundColor: const Color(0xFFE5F0FB),
                          backgroundImage: profile.profileImagePath != null
                              ? FileImage(File(profile.profileImagePath!))
                              : null,
                          child: profile.profileImagePath == null
                              ? Text(
                                  profile.fullName.isEmpty
                                      ? 'A'
                                      : profile.fullName[0].toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF2368AF),
                                  ),
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        profile.fullName,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF18314F),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${profile.designation} • ${profile.employeeId}',
                        style: const TextStyle(
                          color: Color(0xFF617087),
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _ProfileRow(
                  label: 'ashaProfilePhone'.tr(),
                  value: profile.phoneNumber,
                ),
                _ProfileRow(
                  label: 'ashaProfileDistrict'.tr(),
                  value:
                      '${profile.districtName}${profile.districtState.isEmpty ? '' : ', ${profile.districtState}'}',
                ),
                _ProfileRow(
                  label: 'ashaProfileBlock'.tr(),
                  value: profile.blockName.isEmpty
                      ? (_apiBlock ?? '-')
                      : profile.blockName,
                ),
                _ProfileRow(
                  label: 'ashaProfileVillage'.tr(),
                  value: profile.primaryVillage,
                ),
                _ProfileRow(
                  label: 'ashaProfileApiBlock'.tr(),
                  value: _apiBlock ?? '-',
                ),
                _ProfileRow(
                  label: 'ashaProfileSyncedReports'.tr(),
                  value: _reportsCount?.toString() ?? '-',
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isLoggingOut ? null : _logout,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      foregroundColor: const Color(0xFFB14040),
                      side: const BorderSide(color: Color(0xFFF1C4C4)),
                    ),
                    icon: _isLoggingOut
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.logout_rounded),
                    label: Text('ashaProfileLogout'.tr()),
                  ),
                ),
              ],
            ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF617087), fontSize: 15),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF18314F),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
