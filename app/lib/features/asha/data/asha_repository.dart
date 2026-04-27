import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:jansetu/features/asha/data/asha_cache_db.dart';
import 'package:jansetu/features/asha/data/asha_models.dart';
import 'package:jansetu/features/asha/data/asha_worker_profile_repository.dart';
import 'package:jansetu/features/sync_queue/sync_queue_db.dart';

class AshaRepository {
  AshaRepository({http.Client? client}) : _client = client ?? http.Client();

  static const _baseUrl = String.fromEnvironment(
    'JANSETU_API_BASE_URL',
    defaultValue: 'https://jansetu-web-delta.vercel.app',
  );
  static const _authToken = String.fromEnvironment(
    'JANSETU_API_TOKEN',
    defaultValue: 'jansetu-internal-2026',
  );
  static const _districtId = String.fromEnvironment(
    'JANSETU_DISTRICT_ID',
    defaultValue: 'dist001varanasi',
  );
  static const _defaultEmployeeId = String.fromEnvironment(
    'JANSETU_CHW_EMPLOYEE_ID',
    defaultValue: 'VR-2841',
  );

  final http.Client _client;
  final AshaCacheDatabase _cache = AshaCacheDatabase.instance;
  final SyncQueueDatabase _queueDb = SyncQueueDatabase.instance;
  final AshaWorkerProfileRepository _workerProfileRepository =
      AshaWorkerProfileRepository();

  Map<String, String> get _authHeaders => {
        'Authorization': 'Bearer $_authToken',
        'Content-Type': 'application/json',
      };

  Future<HealthStatus> healthCheck() async {
    final response = await _client.get(Uri.parse('$_baseUrl/api/android/health'));
    if (response.statusCode != 200) {
      throw Exception('Health check failed with ${response.statusCode}');
    }
    return HealthStatus.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<BootstrapData> fetchBootstrap() async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/api/android/bootstrap?districtId=$_districtId'),
      headers: _authHeaders,
    );
    if (response.statusCode != 200) {
      throw Exception('Bootstrap failed with ${response.statusCode}');
    }
    final bootstrap = BootstrapData.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
    await _cache.saveBootstrap(bootstrap);
    return bootstrap;
  }

  Future<ChwProfile> fetchProfile({String? employeeId}) async {
    final workerProfile = await _workerProfileRepository.loadProfile();
    final workerEmployeeId = workerProfile?.employeeId.trim();
    final resolvedEmployeeId = employeeId ??
        ((workerEmployeeId != null && workerEmployeeId.isNotEmpty)
            ? workerEmployeeId
            : _defaultEmployeeId);
    final response = await _client.get(
      Uri.parse('$_baseUrl/api/android/chw/profile?employeeId=$resolvedEmployeeId'),
      headers: _authHeaders,
    );
    if (response.statusCode == 404) {
      // Return a skeleton profile if not found on server, using local setup if available
      return ChwProfile(
        id: '-1',
        employeeId: resolvedEmployeeId,
        name: workerProfile?.fullName ?? 'CHW User',
        phone: workerProfile?.phoneNumber ?? '',
        isActive: true,
        reportsCount: 0,
        lastSyncAt: null,
        block: const ChwBlock(
          id: 'clb001rampur',
          name: 'Rampur',
          villages: [],
        ),
      );
    }
    if (response.statusCode != 200) {
      throw Exception('CHW profile failed with ${response.statusCode}');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final profile = ChwProfile.fromJson(
      body['chw'] as Map<String, dynamic>? ?? const {},
    );
    await _cache.saveProfile(profile);
    return profile;
  }

  Future<List<AshaAlert>> fetchAlerts({String? since}) async {
    final sinceQuery = since == null || since.isEmpty
        ? ''
        : '&since=${Uri.encodeQueryComponent(since)}';
    final response = await _client.get(
      Uri.parse('$_baseUrl/api/android/alerts?districtId=$_districtId$sinceQuery'),
      headers: _authHeaders,
    );
    if (response.statusCode != 200) {
      throw Exception('Alerts fetch failed with ${response.statusCode}');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final alerts = ((body['alerts'] as List?) ?? const [])
        .map((item) => AshaAlert.fromJson(item as Map<String, dynamic>))
        .toList();
    await _cache.saveAlerts(
      alerts,
      fetchedAt: body['fetchedAt']?.toString(),
    );
    return alerts;
  }

  Future<BootstrapData?> loadCachedBootstrap() => _cache.readBootstrap();
  Future<ChwProfile?> loadCachedProfile() => _cache.readProfile();
  Future<List<AshaAlert>> loadCachedAlerts() => _cache.readAlerts();

  Future<BootstrapData> getBootstrapData() async {
    final cached = await _cache.readBootstrap();
    return cached ?? fetchBootstrap();
  }

  Future<ChwProfile> getActiveProfile() async {
    final cached = await _cache.readProfile();
    return cached ?? fetchProfile();
  }

  Future<DashboardData> loadDashboardData() async {
    final health = await healthCheck();
    final bootstrap = await getBootstrapData();
    final profile = await fetchProfile();

    List<AshaAlert> alerts;
    try {
      alerts = await fetchAlerts(
        since: profile.lastSyncAt?.toUtc().toIso8601String(),
      );
      if (alerts.isEmpty) {
        alerts = await _cache.readAlerts();
      }
    } catch (_) {
      alerts = await _cache.readAlerts();
    }

    final pendingSyncCount = await _queueDb.getPendingCount();
    final todayQueuedCount = await _getTodayQueuedCount();
    final driftMinutes = DateTime.now()
        .toUtc()
        .difference(health.serverTime.toUtc())
        .inMinutes
        .abs();

    return DashboardData(
      healthStatus: health,
      bootstrap: bootstrap,
      profile: profile,
      alerts: alerts,
      pendingSyncCount: pendingSyncCount,
      todayQueuedCount: todayQueuedCount,
      clockDriftWarning: driftMinutes > 5
          ? 'Device time differs from server by more than 5 minutes.'
          : null,
    );
  }

  Future<List<VillageCaseTrend>> loadVillageCaseTrends() async {
    final bootstrap = await getBootstrapData();
    final reports = await _queueDb.getReportsByStatuses(const ['PENDING', 'FAILED', 'SENT']);
    final villagesById = {
      for (final village in bootstrap.villages) village.id: village,
    };

    final trendAccumulator = <String, _VillageTrendAccumulator>{};

    for (final report in reports) {
      final payloadRaw = report['payload']?.toString();
      if (payloadRaw == null || payloadRaw.isEmpty) continue;

      Map<String, dynamic> payload;
      try {
        final decoded = jsonDecode(payloadRaw);
        if (decoded is! Map<String, dynamic>) continue;
        payload = decoded;
      } catch (_) {
        continue;
      }

      final villageId = payload['villageId']?.toString();
      if (villageId == null || !villagesById.containsKey(villageId)) continue;
      final village = villagesById[villageId]!;
      final status = report['status']?.toString() ?? 'PENDING';
      final symptoms = ((payload['symptoms'] as List?) ?? const [])
          .map((item) => item.toString())
          .toList();

      final accumulator = trendAccumulator.putIfAbsent(
        villageId,
        () => _VillageTrendAccumulator(village: village),
      );
      accumulator.totalCases += 1;
      if (status == 'SENT') {
        accumulator.sentCases += 1;
      } else {
        accumulator.pendingCases += 1;
      }

      for (final symptom in symptoms) {
        accumulator.symptomCounts[symptom] =
            (accumulator.symptomCounts[symptom] ?? 0) + 1;
      }
    }

    final trends = trendAccumulator.values.map((item) {
      final topEntry = item.symptomCounts.entries.isEmpty
          ? const MapEntry('no data', 0)
          : item.symptomCounts.entries.reduce(
              (left, right) => left.value >= right.value ? left : right,
            );

      return VillageCaseTrend(
        villageId: item.village.id,
        villageName: item.village.name,
        lat: item.village.lat,
        lng: item.village.lng,
        totalCases: item.totalCases,
        topSymptom: topEntry.key,
        topSymptomCount: topEntry.value,
        pendingCases: item.pendingCases,
        sentCases: item.sentCases,
      );
    }).toList();

    trends.sort((a, b) => b.totalCases.compareTo(a.totalCases));
    return trends;
  }

  Future<SyncApiResponse> syncReports({
    required List<Map<String, dynamic>> reports,
    required String deviceId,
  }) async {
    final profile = await getActiveProfile();
    final response = await _client.post(
      Uri.parse('$_baseUrl/api/android/sync'),
      headers: _authHeaders,
      body: jsonEncode({
        'chwId': profile.employeeId,
        'sourceType': 'chw',
        'deviceId': deviceId,
        'reports': reports,
      }),
    );

    if (response.statusCode == 200) {
      final data = SyncApiResponse.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
      final updatedProfile = ChwProfile(
        id: profile.id,
        employeeId: profile.employeeId,
        name: profile.name,
        phone: profile.phone,
        isActive: profile.isActive,
        reportsCount: data.chwReportsCount,
        lastSyncAt: data.syncedAt,
        block: profile.block,
      );
      await _cache.saveProfile(updatedProfile);
      if (data.newAlerts.isNotEmpty) {
        await _cache.saveAlerts(
          data.newAlerts,
          fetchedAt: data.syncedAt.toIso8601String(),
        );
      } else {
        await _cache.writeMeta(
          'alerts_fetched_at',
          data.syncedAt.toIso8601String(),
        );
      }
      return data;
    }

    if (response.statusCode == 400 || response.statusCode == 404) {
      throw AshaSyncException(
        retryable: false,
        message: 'Sync rejected with ${response.statusCode}: ${response.body}',
      );
    }

    if (response.statusCode == 401) {
      throw const AshaSyncException(
        retryable: false,
        message: 'Unauthorized. Check API token.',
      );
    }

    throw AshaSyncException(
      retryable: true,
      message: 'Sync failed with ${response.statusCode}',
    );
  }

  Future<Map<String, dynamic>> buildReportPayload({
    required String transcript,
    bool hasPhoto = false,
    bool forceReferral = false,
    List<String> extraSymptoms = const [],
  }) async {
    final bootstrap = await getBootstrapData();
    final profile = await getActiveProfile();
    final symptoms = _extractSymptoms(
      transcript,
      bootstrap.symptomCodes,
      extraSymptoms,
    );
    final villageId = profile.block.villages.isNotEmpty
        ? profile.block.villages.first.id
        : 'clv001rampur';
    final severity = _deriveSeverity(symptoms);
    final referral = forceReferral ||
        symptoms.contains('breathlessness') ||
        symptoms.contains('seizure');

    return {
      'villageId': villageId,
      'ageGroup': _detectAgeGroup(transcript),
      'gender': _detectGender(transcript),
      'symptoms': symptoms,
      'duration': _detectDurationDays(transcript),
      'severity': severity,
      'hasPhoto': hasPhoto,
      'referral': referral,
      'reportedAt': DateTime.now().toUtc().toIso8601String(),
      'transcript': transcript,
    };
  }

  List<String> _extractSymptoms(
    String transcript,
    List<String> validSymptoms,
    List<String> extraSymptoms,
  ) {
    final lower = transcript.toLowerCase();
    final matches = <String>{};
    const symptomKeywords = {
      'fever': ['fever', 'bukhar'],
      'cough': ['cough', 'khansi'],
      'breathlessness': ['breath', 'breathing', 'saans'],
      'diarrhoea': ['diarrhoea', 'diarrhea', 'loose motion', 'dast'],
      'vomiting': ['vomit', 'ultee'],
      'rash': ['rash', 'daane'],
      'headache': ['headache', 'sir dard'],
      'bodyache': ['body ache', 'bodyache'],
      'sore_throat': ['sore throat', 'throat pain', 'gala'],
      'runny_nose': ['runny nose', 'naak'],
      'malnutrition': ['malnutrition', 'kuposhan'],
      'jaundice': ['jaundice', 'peela'],
      'conjunctivitis': ['conjunctivitis', 'red eye'],
      'seizure': ['seizure', 'fit', 'daura'],
      'unconscious': ['unconscious', 'behosh'],
      'bleeding': ['bleeding', 'khoon'],
    };

    for (final entry in symptomKeywords.entries) {
      if (!validSymptoms.contains(entry.key)) continue;
      if (entry.value.any(lower.contains)) {
        matches.add(entry.key);
      }
    }

    for (final symptom in extraSymptoms) {
      if (validSymptoms.contains(symptom)) {
        matches.add(symptom);
      }
    }

    if (matches.isEmpty) {
      matches.add('fever');
    }
    return matches.toList();
  }

  String _detectAgeGroup(String transcript) {
    final lower = transcript.toLowerCase();
    final match = RegExp(r'(\d{1,2})').firstMatch(lower);
    final age = match == null ? null : int.tryParse(match.group(1)!);
    if (lower.contains('child') ||
        lower.contains('boy') ||
        lower.contains('girl') ||
        (age != null && age < 15)) {
      return 'child';
    }
    if (lower.contains('elderly') ||
        lower.contains('old') ||
        (age != null && age >= 60)) {
      return 'elderly';
    }
    return 'adult';
  }

  String _detectGender(String transcript) {
    final lower = transcript.toLowerCase();
    if (lower.contains('female') ||
        lower.contains('woman') ||
        lower.contains('mahila')) {
      return 'F';
    }
    if (lower.contains('male') ||
        lower.contains('man') ||
        lower.contains('ladka')) {
      return 'M';
    }
    return 'unknown';
  }

  int? _detectDurationDays(String transcript) {
    final lower = transcript.toLowerCase();
    final match = RegExp(r'(\d{1,2})\s*(day|days|din)').firstMatch(lower);
    if (match == null) return null;
    return int.tryParse(match.group(1)!);
  }

  String _deriveSeverity(List<String> symptoms) {
    if (symptoms.contains('breathlessness') ||
        symptoms.contains('seizure') ||
        symptoms.contains('unconscious')) {
      return 'severe';
    }
    if (symptoms.length >= 3 || symptoms.contains('rash')) {
      return 'moderate';
    }
    return 'mild';
  }

  Future<int> _getTodayQueuedCount() async {
    final reports = await _queueDb.getAllReports();
    final now = DateTime.now().toUtc();
    return reports.where((report) {
      final raw = report['timestamp']?.toString();
      if (raw == null) return false;
      final parsed = DateTime.tryParse(raw)?.toUtc();
      if (parsed == null) return false;
      return parsed.year == now.year &&
          parsed.month == now.month &&
          parsed.day == now.day;
    }).length;
  }
}

class AshaSyncException implements Exception {
  const AshaSyncException({
    required this.retryable,
    required this.message,
  });

  final bool retryable;
  final String message;

  @override
  String toString() => message;
}

class _VillageTrendAccumulator {
  _VillageTrendAccumulator({required this.village});

  final VillageInfo village;
  int totalCases = 0;
  int pendingCases = 0;
  int sentCases = 0;
  final Map<String, int> symptomCounts = <String, int>{};
}
