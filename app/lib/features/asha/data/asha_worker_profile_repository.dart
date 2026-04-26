import 'dart:convert';

import 'package:jansetu/core/storage/secure_storage_service.dart';

class AshaWorkerProfile {
  const AshaWorkerProfile({
    required this.fullName,
    required this.employeeId,
    required this.phoneNumber,
    required this.designation,
    required this.reportingOffice,
    required this.supervisorName,
    required this.primaryVillage,
    this.profileImagePath,
  });

  final String fullName;
  final String employeeId;
  final String phoneNumber;
  final String designation;
  final String reportingOffice;
  final String supervisorName;
  final String primaryVillage;
  final String? profileImagePath;

  Map<String, dynamic> toJson() => {
        'fullName': fullName,
        'employeeId': employeeId,
        'phoneNumber': phoneNumber,
        'designation': designation,
        'reportingOffice': reportingOffice,
        'supervisorName': supervisorName,
        'primaryVillage': primaryVillage,
        'profileImagePath': profileImagePath,
      };

  factory AshaWorkerProfile.fromJson(Map<String, dynamic> json) {
    return AshaWorkerProfile(
      fullName: json['fullName']?.toString() ?? '',
      employeeId: json['employeeId']?.toString() ?? '',
      phoneNumber: json['phoneNumber']?.toString() ?? '',
      designation: json['designation']?.toString() ?? '',
      reportingOffice: json['reportingOffice']?.toString() ?? '',
      supervisorName: json['supervisorName']?.toString() ?? '',
      primaryVillage: json['primaryVillage']?.toString() ?? '',
      profileImagePath: json['profileImagePath']?.toString(),
    );
  }

  AshaWorkerProfile copyWith({
    String? fullName,
    String? employeeId,
    String? phoneNumber,
    String? designation,
    String? reportingOffice,
    String? supervisorName,
    String? primaryVillage,
    String? profileImagePath,
  }) {
    return AshaWorkerProfile(
      fullName: fullName ?? this.fullName,
      employeeId: employeeId ?? this.employeeId,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      designation: designation ?? this.designation,
      reportingOffice: reportingOffice ?? this.reportingOffice,
      supervisorName: supervisorName ?? this.supervisorName,
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
        profile.reportingOffice.isNotEmpty;
  }

  Future<void> updateProfileImage(String? imagePath) async {
    final current = await loadProfile();
    if (current == null) return;
    await saveProfile(current.copyWith(profileImagePath: imagePath));
  }
}
