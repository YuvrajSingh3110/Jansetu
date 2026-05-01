import 'dart:convert';

import 'package:jansetu/core/storage/secure_storage_service.dart';

class AshaWorkerProfile {
  const AshaWorkerProfile({
    required this.fullName,
    required this.employeeId,
    required this.phoneNumber,
    required this.designation,
    required this.districtId,
    required this.districtName,
    required this.districtState,
    required this.blockId,
    required this.blockName,
    required this.primaryVillageId,
    required this.primaryVillage,
    this.profileImagePath,
  });

  final String fullName;
  final String employeeId;
  final String phoneNumber;
  final String designation;
  final String districtId;
  final String districtName;
  final String districtState;
  final String blockId;
  final String blockName;
  final String primaryVillageId;
  final String primaryVillage;
  final String? profileImagePath;

  Map<String, dynamic> toJson() => {
        'fullName': fullName,
        'employeeId': employeeId,
        'phoneNumber': phoneNumber,
        'designation': designation,
        'districtId': districtId,
        'districtName': districtName,
        'districtState': districtState,
        'blockId': blockId,
        'blockName': blockName,
        'primaryVillageId': primaryVillageId,
        'primaryVillage': primaryVillage,
        'profileImagePath': profileImagePath,
      };

  factory AshaWorkerProfile.fromJson(Map<String, dynamic> json) {
    return AshaWorkerProfile(
      fullName: json['fullName']?.toString() ?? '',
      employeeId: json['employeeId']?.toString() ?? '',
      phoneNumber: json['phoneNumber']?.toString() ?? '',
      designation: json['designation']?.toString() ?? '',
      districtId: json['districtId']?.toString() ?? '',
      districtName: json['districtName']?.toString() ?? '',
      districtState: json['districtState']?.toString() ?? '',
      blockId: json['blockId']?.toString() ?? '',
      blockName: json['blockName']?.toString() ?? '',
      primaryVillageId: json['primaryVillageId']?.toString() ?? '',
      primaryVillage: json['primaryVillage']?.toString() ?? '',
      profileImagePath: json['profileImagePath']?.toString(),
    );
  }

  AshaWorkerProfile copyWith({
    String? fullName,
    String? employeeId,
    String? phoneNumber,
    String? designation,
    String? districtId,
    String? districtName,
    String? districtState,
    String? blockId,
    String? blockName,
    String? primaryVillageId,
    String? primaryVillage,
    String? profileImagePath,
  }) {
    return AshaWorkerProfile(
      fullName: fullName ?? this.fullName,
      employeeId: employeeId ?? this.employeeId,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      designation: designation ?? this.designation,
      districtId: districtId ?? this.districtId,
      districtName: districtName ?? this.districtName,
      districtState: districtState ?? this.districtState,
      blockId: blockId ?? this.blockId,
      blockName: blockName ?? this.blockName,
      primaryVillageId: primaryVillageId ?? this.primaryVillageId,
      primaryVillage: primaryVillage ?? this.primaryVillage,
      profileImagePath: profileImagePath ?? this.profileImagePath,
    );
  }
}

class AshaWorkerProfileRepository {
  AshaWorkerProfileRepository({SecureStorageService? storage})
      : _storage = storage ?? SecureStorageService();

  final SecureStorageService _storage;

  Future<void> saveProfile(AshaWorkerProfile profile) async {
    await _storage.writeAshaWorkerProfile(jsonEncode(profile.toJson()));
  }

  Future<AshaWorkerProfile?> loadProfile() async {
    final raw = await _storage.readAshaWorkerProfile();
    if (raw == null || raw.isEmpty) return null;
    return AshaWorkerProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<bool> hasCompletedSetup() async {
    final profile = await loadProfile();
    return profile != null &&
        profile.fullName.isNotEmpty &&
        profile.employeeId.isNotEmpty &&
        profile.designation.isNotEmpty &&
        profile.districtId.isNotEmpty &&
        profile.primaryVillageId.isNotEmpty;
  }

  Future<void> updateProfileImage(String? imagePath) async {
    final current = await loadProfile();
    if (current == null) return;
    await saveProfile(current.copyWith(profileImagePath: imagePath));
  }
}
