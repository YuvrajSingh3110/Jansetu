class HealthStatus {
  const HealthStatus({
    required this.status,
    required this.db,
    required this.serverTime,
    required this.version,
  });

  final String status;
  final String db;
  final DateTime serverTime;
  final String version;

  factory HealthStatus.fromJson(Map<String, dynamic> json) {
    return HealthStatus(
      status: json['status']?.toString() ?? 'unknown',
      db: json['db']?.toString() ?? 'unknown',
      serverTime: DateTime.parse(json['serverTime']?.toString() ?? DateTime.now().toUtc().toIso8601String()),
      version: json['version']?.toString() ?? '0.0.0',
    );
  }
}

class DistrictInfo {
  const DistrictInfo({
    required this.id,
    required this.name,
    required this.state,
  });

  final String id;
  final String name;
  final String state;

  factory DistrictInfo.fromJson(Map<String, dynamic> json) {
    return DistrictInfo(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'state': state,
      };
}

class BlockInfo {
  const BlockInfo({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;

  factory BlockInfo.fromJson(Map<String, dynamic> json) {
    return BlockInfo(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
      };
}

class VillageInfo {
  const VillageInfo({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
    required this.blockId,
    required this.block,
  });

  final String id;
  final String name;
  final double lat;
  final double lng;
  final String blockId;
  final String block;

  factory VillageInfo.fromJson(Map<String, dynamic> json) {
    return VillageInfo(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      lat: (json['lat'] as num?)?.toDouble() ?? 0,
      lng: (json['lng'] as num?)?.toDouble() ?? 0,
      blockId: json['blockId']?.toString() ?? '',
      block: json['block']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'lat': lat,
        'lng': lng,
        'blockId': blockId,
        'block': block,
      };
}

class BootstrapData {
  const BootstrapData({
    required this.district,
    required this.blocks,
    required this.villages,
    required this.symptomCodes,
    required this.syncedAt,
  });

  final DistrictInfo district;
  final List<BlockInfo> blocks;
  final List<VillageInfo> villages;
  final List<String> symptomCodes;
  final DateTime syncedAt;

  factory BootstrapData.fromJson(Map<String, dynamic> json) {
    return BootstrapData(
      district: DistrictInfo.fromJson(json['district'] as Map<String, dynamic>? ?? const {}),
      blocks: ((json['blocks'] as List?) ?? const [])
          .map((item) => BlockInfo.fromJson(item as Map<String, dynamic>))
          .toList(),
      villages: ((json['villages'] as List?) ?? const [])
          .map((item) => VillageInfo.fromJson(item as Map<String, dynamic>))
          .toList(),
      symptomCodes: ((json['symptomCodes'] as List?) ?? const []).map((item) => item.toString()).toList(),
      syncedAt: DateTime.parse(json['syncedAt']?.toString() ?? DateTime.now().toUtc().toIso8601String()),
    );
  }
}

class ChwVillage {
  const ChwVillage({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
  });

  final String id;
  final String name;
  final double lat;
  final double lng;

  factory ChwVillage.fromJson(Map<String, dynamic> json) {
    return ChwVillage(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      lat: (json['lat'] as num?)?.toDouble() ?? 0,
      lng: (json['lng'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'lat': lat,
        'lng': lng,
      };
}

class ChwBlock {
  const ChwBlock({
    required this.id,
    required this.name,
    required this.villages,
  });

  final String id;
  final String name;
  final List<ChwVillage> villages;

  factory ChwBlock.fromJson(Map<String, dynamic> json) {
    return ChwBlock(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      villages: ((json['villages'] as List?) ?? const [])
          .map((item) => ChwVillage.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'villages': villages.map((item) => item.toJson()).toList(),
      };
}

class ChwProfile {
  const ChwProfile({
    required this.id,
    required this.employeeId,
    required this.name,
    required this.phone,
    required this.isActive,
    required this.reportsCount,
    required this.lastSyncAt,
    required this.block,
  });

  final String id;
  final String employeeId;
  final String name;
  final String phone;
  final bool isActive;
  final int reportsCount;
  final DateTime? lastSyncAt;
  final ChwBlock block;

  factory ChwProfile.fromJson(Map<String, dynamic> json) {
    final rawLastSync = json['lastSyncAt']?.toString();
    return ChwProfile(
      id: json['id']?.toString() ?? '',
      employeeId: json['employeeId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      isActive: json['isActive'] == true,
      reportsCount: (json['reportsCount'] as num?)?.toInt() ?? 0,
      lastSyncAt: rawLastSync == null || rawLastSync.isEmpty ? null : DateTime.tryParse(rawLastSync),
      block: ChwBlock.fromJson(json['block'] as Map<String, dynamic>? ?? const {}),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'employeeId': employeeId,
        'name': name,
        'phone': phone,
        'isActive': isActive,
        'reportsCount': reportsCount,
        'lastSyncAt': lastSyncAt?.toIso8601String(),
        'block': block.toJson(),
      };
}

class AshaAlert {
  const AshaAlert({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.confidence,
    required this.affectedVillages,
    required this.symptomCluster,
    required this.caseCount,
    required this.timeWindowHrs,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String type;
  final String title;
  final String description;
  final String confidence;
  final List<String> affectedVillages;
  final List<String> symptomCluster;
  final int caseCount;
  final int timeWindowHrs;
  final String status;
  final DateTime createdAt;

  factory AshaAlert.fromJson(Map<String, dynamic> json) {
    return AshaAlert(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      confidence: json['confidence']?.toString() ?? '',
      affectedVillages: ((json['affectedVillages'] as List?) ?? const []).map((item) => item.toString()).toList(),
      symptomCluster: ((json['symptomCluster'] as List?) ?? const []).map((item) => item.toString()).toList(),
      caseCount: (json['caseCount'] as num?)?.toInt() ?? 0,
      timeWindowHrs: (json['timeWindowHrs'] as num?)?.toInt() ?? 0,
      status: json['status']?.toString() ?? 'active',
      createdAt: DateTime.parse(json['createdAt']?.toString() ?? DateTime.now().toUtc().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'title': title,
        'description': description,
        'confidence': confidence,
        'affectedVillages': affectedVillages,
        'symptomCluster': symptomCluster,
        'caseCount': caseCount,
        'timeWindowHrs': timeWindowHrs,
        'status': status,
        'createdAt': createdAt.toIso8601String(),
      };
}

class SyncApiResponse {
  const SyncApiResponse({
    required this.received,
    required this.queued,
    required this.chwReportsCount,
    required this.newAlerts,
    required this.syncedAt,
  });

  final int received;
  final bool queued;
  final int chwReportsCount;
  final List<AshaAlert> newAlerts;
  final DateTime syncedAt;

  factory SyncApiResponse.fromJson(Map<String, dynamic> json) {
    return SyncApiResponse(
      received: (json['received'] as num?)?.toInt() ?? 0,
      queued: json['queued'] == true,
      chwReportsCount: (json['chwReportsCount'] as num?)?.toInt() ?? 0,
      newAlerts: ((json['newAlerts'] as List?) ?? const [])
          .map((item) => AshaAlert.fromJson(item as Map<String, dynamic>))
          .toList(),
      syncedAt: DateTime.parse(json['syncedAt']?.toString() ?? DateTime.now().toUtc().toIso8601String()),
    );
  }
}

class DashboardData {
  const DashboardData({
    required this.healthStatus,
    required this.bootstrap,
    required this.profile,
    required this.alerts,
    required this.pendingSyncCount,
    required this.todayQueuedCount,
    required this.clockDriftWarning,
  });

  final HealthStatus healthStatus;
  final BootstrapData bootstrap;
  final ChwProfile profile;
  final List<AshaAlert> alerts;
  final int pendingSyncCount;
  final int todayQueuedCount;
  final String? clockDriftWarning;
}

class VillageCaseTrend {
  const VillageCaseTrend({
    required this.villageId,
    required this.villageName,
    required this.lat,
    required this.lng,
    required this.totalCases,
    required this.topSymptom,
    required this.topSymptomCount,
    required this.pendingCases,
    required this.sentCases,
  });

  final String villageId;
  final String villageName;
  final double lat;
  final double lng;
  final int totalCases;
  final String topSymptom;
  final int topSymptomCount;
  final int pendingCases;
  final int sentCases;
}
