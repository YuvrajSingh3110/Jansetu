import 'package:flutter/material.dart';
import 'package:jansetu/features/sync_queue/sync_queue_repository.dart';
import 'package:jansetu/features/sync_queue/sync_queue_screen.dart';

class SyncQueue {
  static final _repo = SyncQueueRepository();

  /// Queues a report to be sent to the backend.
  static Future<void> queueReport({
    required String type,
    required Map<String, dynamic> payload,
    String? localImagePath,
  }) async {
    await _repo.queueReportWithImage(
      HealthSignal(type: type, payload: payload),
      localImagePath: localImagePath,
    );
  }

  /// Opens the Sync Queue management screen.
  static void showSyncQueue(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const SyncQueueScreen()),
    );
  }
}
