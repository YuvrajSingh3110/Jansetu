import 'dart:convert';
import 'package:archive/archive_io.dart';
import 'package:http/http.dart' as http;
import 'package:jansetu/features/sync_queue/sync_queue_db.dart';
import 'package:jansetu/features/sync_queue/sync_queue_repository.dart';

enum _BatchDisposition { sent, failed, retry }

class SyncResult {
  final bool success;
  final int pendingBefore;
  final int sentCount;
  final int failedCount;
  final int retriedCount;
  final String message;

  const SyncResult({
    required this.success,
    required this.pendingBefore,
    required this.sentCount,
    required this.failedCount,
    required this.retriedCount,
    required this.message,
  });

  bool get shouldRetry => retriedCount > 0 && sentCount == 0 && failedCount == 0;
}

class _BatchSyncResult {
  final _BatchDisposition disposition;
  final int affectedCount;
  final String message;

  const _BatchSyncResult({
    required this.disposition,
    required this.affectedCount,
    required this.message,
  });
}

class SyncWorker {
  static const _reportsPath = '/api/ingest/reports';
  static const _syncBaseUrl = String.fromEnvironment('SYNC_BASE_URL', defaultValue: '');

  static Future<bool> performSync() async {
    final result = await performSyncWithResult();
    return result.success;
  }

  static Future<SyncResult> performSyncWithResult() async {
    final db = SyncQueueDatabase.instance;
    final repo = SyncQueueRepository();
    final deviceId = await repo.getDeviceId();

    final pending = await db.getPendingReports(100);
    if (pending.isEmpty) {
      return const SyncResult(
        success: true,
        pendingBefore: 0,
        sentCount: 0,
        failedCount: 0,
        retriedCount: 0,
        message: 'No pending reports to sync.',
      );
    }

    final endpoint = _resolveEndpoint();
    if (endpoint == null) {
      return SyncResult(
        success: false,
        pendingBefore: pending.length,
        sentCount: 0,
        failedCount: 0,
        retriedCount: pending.length,
        message: 'Sync endpoint is not configured. Run with --dart-define=SYNC_BASE_URL=https://your-server',
      );
    }

    List<Map<String, dynamic>> currentBatch = [];
    int currentBatchSize = 0;
    int sentCount = 0;
    int failedCount = 0;
    int retriedCount = 0;

    for (final report in pending) {
      final reportSize = report['payload_size'] as int? ?? 0;
      if (currentBatchSize + reportSize > 2048 && currentBatch.isNotEmpty) {
        final batchResult = await _uploadBatch(currentBatch, deviceId, endpoint);
        switch (batchResult.disposition) {
          case _BatchDisposition.sent:
            sentCount += batchResult.affectedCount;
          case _BatchDisposition.failed:
            failedCount += batchResult.affectedCount;
          case _BatchDisposition.retry:
            retriedCount += batchResult.affectedCount;
        }
        currentBatch = [];
        currentBatchSize = 0;
      }
      currentBatch.add(report);
      currentBatchSize += reportSize;
    }

    if (currentBatch.isNotEmpty) {
      final batchResult = await _uploadBatch(currentBatch, deviceId, endpoint);
      switch (batchResult.disposition) {
        case _BatchDisposition.sent:
          sentCount += batchResult.affectedCount;
        case _BatchDisposition.failed:
          failedCount += batchResult.affectedCount;
        case _BatchDisposition.retry:
          retriedCount += batchResult.affectedCount;
      }
    }

    final success = retriedCount == 0;
    final summaryParts = <String>[];
    if (sentCount > 0) summaryParts.add('sent $sentCount');
    if (failedCount > 0) summaryParts.add('failed $failedCount');
    if (retriedCount > 0) summaryParts.add('pending retry $retriedCount');

    return SyncResult(
      success: success,
      pendingBefore: pending.length,
      sentCount: sentCount,
      failedCount: failedCount,
      retriedCount: retriedCount,
      message: summaryParts.isEmpty ? 'Sync finished with no changes.' : 'Sync finished: ${summaryParts.join(', ')}.',
    );
  }

  static Uri? _resolveEndpoint() {
    final raw = _syncBaseUrl.trim();
    if (raw.isEmpty) return null;
    final base = Uri.tryParse(raw);
    if (base == null || !(base.hasScheme && base.host.isNotEmpty)) {
      return null;
    }
    return base.resolve(_reportsPath);
  }

  static Future<_BatchSyncResult> _uploadBatch(
    List<Map<String, dynamic>> reports,
    String deviceId,
    Uri endpoint,
  ) async {
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
        endpoint,
        headers: headers,
        body: finalBody,
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        await db.updateStatus(ids, 'SENT');
        return _BatchSyncResult(
          disposition: _BatchDisposition.sent,
          affectedCount: ids.length,
          message: 'Batch sent successfully.',
        );
      } else if (response.statusCode == 400) {
        await db.updateStatus(ids, 'FAILED');
        return _BatchSyncResult(
          disposition: _BatchDisposition.failed,
          affectedCount: ids.length,
          message: 'Batch rejected with 400 Bad Request.',
        );
      } else {
        return _BatchSyncResult(
          disposition: _BatchDisposition.retry,
          affectedCount: ids.length,
          message: 'Server responded with ${response.statusCode}.',
        );
      }
    } catch (e) {
      return _BatchSyncResult(
        disposition: _BatchDisposition.retry,
        affectedCount: ids.length,
        message: 'Network error: $e',
      );
    }
  }
}
