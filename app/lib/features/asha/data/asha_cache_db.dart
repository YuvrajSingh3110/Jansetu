import 'dart:convert';

import 'package:jansetu/features/asha/data/asha_models.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AshaCacheDatabase {
  AshaCacheDatabase._internal();

  static final AshaCacheDatabase instance = AshaCacheDatabase._internal();
  static Database? _database;
  static const _dbVersion = 1;

  Future<Database> get database async {
    if (_database != null) return _database!;
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'asha_cache.db');
    _database = await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _createDb,
    );
    return _database!;
  }

  Future<void> _createDb(Database db, int version) async {
    await db.execute('CREATE TABLE meta (key TEXT PRIMARY KEY, value TEXT NOT NULL)');
    await db.execute('CREATE TABLE blocks (id TEXT PRIMARY KEY, name TEXT NOT NULL)');
    await db.execute('''
CREATE TABLE villages (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  lat REAL NOT NULL,
  lng REAL NOT NULL,
  block_id TEXT NOT NULL,
  block_name TEXT NOT NULL
)
''');
    await db.execute('''
CREATE TABLE alerts (
  id TEXT PRIMARY KEY,
  type TEXT NOT NULL,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  confidence TEXT NOT NULL,
  status TEXT NOT NULL,
  case_count INTEGER NOT NULL,
  time_window_hrs INTEGER NOT NULL,
  created_at TEXT NOT NULL,
  affected_villages TEXT NOT NULL,
  symptom_cluster TEXT NOT NULL
)
''');
  }

  Future<void> writeMeta(String key, String value) async {
    final db = await database;
    await db.insert(
      'meta',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> readMeta(String key) async {
    final db = await database;
    final rows = await db.query('meta', where: 'key = ?', whereArgs: [key], limit: 1);
    if (rows.isEmpty) return null;
    return rows.first['value']?.toString();
  }

  Future<void> saveBootstrap(BootstrapData bootstrap) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('blocks');
      await txn.delete('villages');
      for (final block in bootstrap.blocks) {
        await txn.insert(
          'blocks',
          {'id': block.id, 'name': block.name},
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      for (final village in bootstrap.villages) {
        await txn.insert(
          'villages',
          {
            'id': village.id,
            'name': village.name,
            'lat': village.lat,
            'lng': village.lng,
            'block_id': village.blockId,
            'block_name': village.block,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await txn.insert(
        'meta',
        {'key': 'district_json', 'value': jsonEncode(bootstrap.district.toJson())},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await txn.insert(
        'meta',
        {'key': 'symptom_codes_json', 'value': jsonEncode(bootstrap.symptomCodes)},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await txn.insert(
        'meta',
        {'key': 'bootstrap_synced_at', 'value': bootstrap.syncedAt.toIso8601String()},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  Future<BootstrapData?> readBootstrap() async {
    final db = await database;
    final districtRaw = await readMeta('district_json');
    final symptomRaw = await readMeta('symptom_codes_json');
    final syncedAtRaw = await readMeta('bootstrap_synced_at');
    if (districtRaw == null || symptomRaw == null || syncedAtRaw == null) {
      return null;
    }

    final blocksRows = await db.query('blocks', orderBy: 'name ASC');
    final villageRows = await db.query('villages', orderBy: 'name ASC');
    return BootstrapData(
      district: DistrictInfo.fromJson(jsonDecode(districtRaw) as Map<String, dynamic>),
      blocks: blocksRows
          .map(
            (row) => BlockInfo(
              id: row['id']?.toString() ?? '',
              name: row['name']?.toString() ?? '',
            ),
          )
          .toList(),
      villages: villageRows
          .map(
            (row) => VillageInfo(
              id: row['id']?.toString() ?? '',
              name: row['name']?.toString() ?? '',
              lat: (row['lat'] as num?)?.toDouble() ?? 0,
              lng: (row['lng'] as num?)?.toDouble() ?? 0,
              blockId: row['block_id']?.toString() ?? '',
              block: row['block_name']?.toString() ?? '',
            ),
          )
          .toList(),
      symptomCodes: (jsonDecode(symptomRaw) as List).map((item) => item.toString()).toList(),
      syncedAt: DateTime.parse(syncedAtRaw),
    );
  }

  Future<void> saveProfile(ChwProfile profile) async {
    await writeMeta('chw_profile_json', jsonEncode(profile.toJson()));
    await writeMeta('current_employee_id', profile.employeeId);
  }

  Future<ChwProfile?> readProfile() async {
    final raw = await readMeta('chw_profile_json');
    if (raw == null) return null;
    return ChwProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveAlerts(List<AshaAlert> alerts, {String? fetchedAt}) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('alerts');
      for (final alert in alerts) {
        await txn.insert(
          'alerts',
          {
            'id': alert.id,
            'type': alert.type,
            'title': alert.title,
            'description': alert.description,
            'confidence': alert.confidence,
            'status': alert.status,
            'case_count': alert.caseCount,
            'time_window_hrs': alert.timeWindowHrs,
            'created_at': alert.createdAt.toIso8601String(),
            'affected_villages': jsonEncode(alert.affectedVillages),
            'symptom_cluster': jsonEncode(alert.symptomCluster),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      if (fetchedAt != null) {
        await txn.insert(
          'meta',
          {'key': 'alerts_fetched_at', 'value': fetchedAt},
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<List<AshaAlert>> readAlerts() async {
    final db = await database;
    final rows = await db.query('alerts', orderBy: 'created_at DESC');
    return rows
        .map(
          (row) => AshaAlert(
            id: row['id']?.toString() ?? '',
            type: row['type']?.toString() ?? '',
            title: row['title']?.toString() ?? '',
            description: row['description']?.toString() ?? '',
            confidence: row['confidence']?.toString() ?? '',
            affectedVillages: (jsonDecode(row['affected_villages']?.toString() ?? '[]') as List)
                .map((item) => item.toString())
                .toList(),
            symptomCluster: (jsonDecode(row['symptom_cluster']?.toString() ?? '[]') as List)
                .map((item) => item.toString())
                .toList(),
            caseCount: (row['case_count'] as num?)?.toInt() ?? 0,
            timeWindowHrs: (row['time_window_hrs'] as num?)?.toInt() ?? 0,
            status: row['status']?.toString() ?? '',
            createdAt: DateTime.parse(row['created_at']?.toString() ?? DateTime.now().toUtc().toIso8601String()),
          ),
        )
        .toList();
  }

  Future<void> clearAll() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('meta');
      await txn.delete('blocks');
      await txn.delete('villages');
      await txn.delete('alerts');
    });
  }
}
