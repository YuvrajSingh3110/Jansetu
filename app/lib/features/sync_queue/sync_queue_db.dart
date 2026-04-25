import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class SyncQueueDatabase {
  static final SyncQueueDatabase instance = SyncQueueDatabase._init();
  static Database? _database;

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
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
CREATE TABLE reports (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  timestamp TEXT NOT NULL,
  signal_type TEXT NOT NULL,
  payload TEXT NOT NULL,
  status TEXT NOT NULL,
  payload_size INTEGER NOT NULL
)
''');
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
