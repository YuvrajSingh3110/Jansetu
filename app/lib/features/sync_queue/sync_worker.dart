import 'dart:convert';
import 'package:archive/archive_io.dart';
import 'package:http/http.dart' as http;
import 'package:jansetu/features/sync_queue/sync_queue_db.dart';
import 'package:jansetu/features/sync_queue/sync_queue_repository.dart';

class SyncWorker {
  static Future<bool> performSync() async {
    final db = SyncQueueDatabase.instance;
    final repo = SyncQueueRepository();
    final deviceId = await repo.getDeviceId();

    final pending = await db.getPendingReports(100);
    if (pending.isEmpty) return true;

    List<Map<String, dynamic>> currentBatch = [];
    int currentBatchSize = 0;

    for (var report in pending) {
      int reportSize = report['payload_size'] as int;
      if (currentBatchSize + reportSize > 2048 && currentBatch.isNotEmpty) {
        bool success = await _uploadBatch(currentBatch, deviceId);
        if (!success) return false; // Workmanager will retry if we return false
        currentBatch = [];
        currentBatchSize = 0;
      }
      currentBatch.add(report);
      currentBatchSize += reportSize;
    }

    if (currentBatch.isNotEmpty) {
      return await _uploadBatch(currentBatch, deviceId);
    }

    return true;
  }

  static Future<bool> _uploadBatch(List<Map<String, dynamic>> reports, String deviceId) async {
    final db = SyncQueueDatabase.instance;
    final ids = reports.map((e) => e['id'] as int).toList();

    final bodyMap = {
      'reports': reports.map((r) {
        dynamic payload;
        try {
          payload = jsonDecode(r['payload']);
        } catch (e) {
          payload = r['payload'];
        }
        return {
          'timestamp': r['timestamp'],
          'signal_type': r['signal_type'],
          'payload': payload,
        };
      }).toList(),
    };

    final bodyBytes = utf8.encode(jsonEncode(bodyMap));
    final useGzip = bodyBytes.length > 1024;

    try {
      final headers = {
        'Content-Type': 'application/json',
        'X-Device-ID': deviceId,
      };

      List<int> finalBody;
      if (useGzip) {
        headers['Content-Encoding'] = 'gzip';
        finalBody = GZipEncoder().encode(bodyBytes)!;
      } else {
        finalBody = bodyBytes;
      }

      final response = await http.post(
        Uri.parse('https://your-api-endpoint.com/api/ingest/reports'),
        headers: headers,
        body: finalBody,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        await db.updateStatus(ids, 'SENT');
        return true;
      } else if (response.statusCode == 400) {
        await db.updateStatus(ids, 'FAILED');
        return true; // Don't retry automatically for 400
      } else {
        return false; // Retry for 5xx etc
      }
    } catch (e) {
      return false;
    }
  }
}
