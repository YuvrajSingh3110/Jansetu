import 'dart:convert';

import 'package:jansetu/features/asha/data/asha_repository.dart';
import 'package:jansetu/features/sync_queue/sync_queue_db.dart';
import 'package:jansetu/features/sync_queue/sync_queue_repository.dart';

enum _BatchDisposition { sent, failed, retry }

class SyncResult {
  const SyncResult({
    required this.success,
    required this.pendingBefore,
    required this.sentCount,
    required this.failedCount,
    required this.retriedCount,
    required this.message,
  });

  final bool success;
  final int pendingBefore;
  final int sentCount;
  final int failedCount;
  final int retriedCount;
  final String message;
}

class _BatchSyncResult {
  const _BatchSyncResult({
    required this.disposition,
    required this.affectedCount,
    required this.message,
  });

  final _BatchDisposition disposition;
  final int affectedCount;
  final String message;
}

class SyncWorker {
  static Future<bool> performSync() async {
    final result = await performSyncWithResult();
    return result.success;
  }

  static Future<SyncResult> performSyncWithResult() async {
    final db = SyncQueueDatabase.instance;
    final repo = SyncQueueRepository();
    final ashaRepository = AshaRepository();
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

    var sentCount = 0;
    var failedCount = 0;
    var retriedCount = 0;
    var currentBatchSize = 0;
    var currentBatch = <Map<String, dynamic>>[];
    var currentPayloads = <Map<String, dynamic>>[];

    for (final report in pending) {
      final payload = _normalizePayload(report);
      if (payload == null) {
        await db.updateStatus([report['id'] as int], 'FAILED');
        failedCount += 1;
        continue;
      }

      final reportSize = report['payload_size'] as int? ?? 0;
      if (currentBatchSize + reportSize > 2048 && currentBatch.isNotEmpty) {
        final batchResult = await _uploadBatch(
          reports: currentBatch,
          payloads: currentPayloads,
          deviceId: deviceId,
          repository: ashaRepository,
        );
        switch (batchResult.disposition) {
          case _BatchDisposition.sent:
            sentCount += batchResult.affectedCount;
            break;
          case _BatchDisposition.failed:
            failedCount += batchResult.affectedCount;
            break;
          case _BatchDisposition.retry:
            retriedCount += batchResult.affectedCount;
            break;
        }
        currentBatch = <Map<String, dynamic>>[];
        currentPayloads = <Map<String, dynamic>>[];
        currentBatchSize = 0;
      }

      currentBatch.add(report);
      currentPayloads.add(payload);
      currentBatchSize += reportSize;
    }

    if (currentBatch.isNotEmpty) {
      final batchResult = await _uploadBatch(
        reports: currentBatch,
        payloads: currentPayloads,
        deviceId: deviceId,
        repository: ashaRepository,
      );
      switch (batchResult.disposition) {
        case _BatchDisposition.sent:
          sentCount += batchResult.affectedCount;
          break;
        case _BatchDisposition.failed:
          failedCount += batchResult.affectedCount;
          break;
        case _BatchDisposition.retry:
          retriedCount += batchResult.affectedCount;
          break;
      }
    }

    final summaryParts = <String>[];
    if (sentCount > 0) summaryParts.add('sent $sentCount');
    if (failedCount > 0) summaryParts.add('failed $failedCount');
    if (retriedCount > 0) summaryParts.add('pending retry $retriedCount');

    return SyncResult(
      success: retriedCount == 0,
      pendingBefore: pending.length,
      sentCount: sentCount,
      failedCount: failedCount,
      retriedCount: retriedCount,
      message: summaryParts.isEmpty
          ? 'Sync finished with no changes.'
          : 'Sync finished: ${summaryParts.join(', ')}.',
    );
  }

  static Future<_BatchSyncResult> _uploadBatch({
    required List<Map<String, dynamic>> reports,
    required List<Map<String, dynamic>> payloads,
    required String deviceId,
    required AshaRepository repository,
  }) async {
    final db = SyncQueueDatabase.instance;
    final ids = reports.map((item) => item['id'] as int).toList();

    try {
      final response = await repository.syncReports(
        reports: payloads,
        deviceId: deviceId,
      );
      await db.updateStatus(ids, 'SENT');
      return _BatchSyncResult(
        disposition: _BatchDisposition.sent,
        affectedCount: ids.length,
        message: 'Batch sent successfully (${response.received} stored).',
      );
    } on AshaSyncException catch (error) {
      if (!error.retryable) {
        await db.updateStatus(ids, 'FAILED');
        return _BatchSyncResult(
          disposition: _BatchDisposition.failed,
          affectedCount: ids.length,
          message: error.message,
        );
      }
      return _BatchSyncResult(
        disposition: _BatchDisposition.retry,
        affectedCount: ids.length,
        message: error.message,
      );
    } catch (error) {
      return _BatchSyncResult(
        disposition: _BatchDisposition.retry,
        affectedCount: ids.length,
        message: 'Network error: $error',
      );
    }
  }

  static Map<String, dynamic>? _normalizePayload(Map<String, dynamic> report) {
    try {
      final rawPayload = report['payload']?.toString();
      if (rawPayload == null || rawPayload.isEmpty) return null;
      final decoded = jsonDecode(rawPayload);
      if (decoded is! Map<String, dynamic>) return null;
      if (report['signal_type']?.toString() != 'chw_report') return null;

      final payload = Map<String, dynamic>.from(decoded);
      payload.remove('transcript');
      return payload;
    } catch (_) {
      return null;
    }
  }
}
