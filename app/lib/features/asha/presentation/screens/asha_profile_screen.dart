import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jansetu/features/asha/data/asha_repository.dart';
import 'package:jansetu/features/asha/data/asha_worker_profile_repository.dart';
import 'package:jansetu/features/asha/presentation/screens/asha_profile_questionnaire_screen.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

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

  AshaWorkerProfile? _profile;
  String? _apiBlock;
  int? _reportsCount;

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

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: const Text('Profile'),
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
                _ProfileRow(label: 'Phone', value: profile.phoneNumber),
                _ProfileRow(label: 'Reports to', value: profile.reportingOffice),
                _ProfileRow(label: 'Supervisor', value: profile.supervisorName),
                _ProfileRow(label: 'Primary village', value: profile.primaryVillage),
                _ProfileRow(label: 'Block from API', value: _apiBlock ?? '-'),
                _ProfileRow(
                  label: 'Synced reports count',
                  value: _reportsCount?.toString() ?? '-',
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
              style: const TextStyle(
                color: Color(0xFF617087),
                fontSize: 15,
              ),
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
