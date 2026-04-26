import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class SyncQueueDatabase {
  static final SyncQueueDatabase instance = SyncQueueDatabase._init();
  static Database? _database;
  static const _dbVersion = 3;

  SyncQueueDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('sync_queue.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
      onOpen: _onOpen,
    );
  }

  Future _createDB(Database db, int version) async {
    await _createReportsTable(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _ensureReportsSchema(db);
    }
    if (oldVersion < 3) {
      await _ensureReportsSchema(db);
    }
  }

  Future<void> _onOpen(Database db) async {
    await _ensureReportsSchema(db);
  }

  Future<void> _createReportsTable(Database db) async {
    await db.execute('''
CREATE TABLE IF NOT EXISTS reports (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  timestamp TEXT NOT NULL,
  signal_type TEXT NOT NULL,
  payload TEXT NOT NULL,
  status TEXT NOT NULL,
  payload_size INTEGER NOT NULL DEFAULT 0,
  local_image_path TEXT
)
''');
  }

  Future<void> _ensureReportsSchema(Database db) async {
    await _createReportsTable(db);

    final tableInfo = await db.rawQuery('PRAGMA table_info(reports)');
    final columnNames = tableInfo
        .map((column) => column['name'] as String?)
        .whereType<String>()
        .toSet();

    if (!columnNames.contains('payload_size')) {
      await db.execute(
        'ALTER TABLE reports ADD COLUMN payload_size INTEGER NOT NULL DEFAULT 0',
      );
      await db.execute('UPDATE reports SET payload_size = LENGTH(payload)');
    }

    if (!columnNames.contains('local_image_path')) {
      await db.execute('ALTER TABLE reports ADD COLUMN local_image_path TEXT');
    }
  }

  Future<int> insertReport(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('reports', row);
  }

  Future<List<Map<String, dynamic>>> getPendingReports(int limit) async {
    final db = await instance.database;
    return await db.query(
      'reports',
      where: 'status = ? OR status = ?',
      whereArgs: ['PENDING', 'FAILED'],
      orderBy: 'id ASC',
      limit: limit,
    );
  }

  Future<int> updateStatus(List<int> ids, String status) async {
    if (ids.isEmpty) return 0;
    final db = await instance.database;
    return await db.update(
      'reports',
      {'status': status},
      where: 'id IN (${ids.join(',')})',
    );
  }

  Future<List<Map<String, dynamic>>> getAllReports() async {
    final db = await instance.database;
    return await db.query('reports', orderBy: 'id DESC');
  }

  Future<List<Map<String, dynamic>>> getReportsByStatuses(List<String> statuses) async {
    final db = await instance.database;
    if (statuses.isEmpty) {
      return db.query('reports', orderBy: 'id DESC');
    }
    final placeholders = List.filled(statuses.length, '?').join(',');
    return db.query(
      'reports',
      where: 'status IN ($placeholders)',
      whereArgs: statuses,
      orderBy: 'id DESC',
    );
  }

  Future<int> getPendingCount() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM reports WHERE status = "PENDING"');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getPendingSize() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT SUM(payload_size) FROM reports WHERE status = "PENDING"');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> clearSent() async {
    final db = await instance.database;
    await db.delete('reports', where: 'status = ?', whereArgs: ['SENT']);
  }
}
