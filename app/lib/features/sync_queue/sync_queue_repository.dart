import 'dart:convert';
import 'package:jansetu/features/sync_queue/sync_queue_db.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:workmanager/workmanager.dart';

class HealthSignal {
  final String type;
  final Map<String, dynamic> payload;

  HealthSignal({required this.type, required this.payload});
}

class SyncQueueRepository {
  final _db = SyncQueueDatabase.instance;

  Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? id = prefs.getString('device_uuid');
    if (id == null) {
      id = const Uuid().v4();
      await prefs.setString('device_uuid', id);
    }
    return id;
  }

  Future<void> queueReport(HealthSignal signal) async {
    final timestamp = DateTime.now().toUtc().toIso8601String();
    final payloadStr = jsonEncode(signal.payload);

    await _db.insertReport({
      'timestamp': timestamp,
      'signal_type': signal.type,
      'payload': payloadStr,
      'status': 'PENDING',
      'payload_size': utf8.encode(payloadStr).length,
    });

    // Schedule background task
    Workmanager().registerOneOffTask(
      "sync_reports_task",
      "sync_reports_action",
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
  }

  Future<List<Map<String, dynamic>>> getReports() => _db.getAllReports();
  Future<int> getPendingCount() => _db.getPendingCount();
  Future<int> getPendingSize() => _db.getPendingSize();
  Future<void> clearSent() => _db.clearSent();
}
