import 'package:flutter/material.dart';
import 'package:jansetu/features/sync_queue/sync_queue_repository.dart';
import 'package:jansetu/features/sync_queue/sync_queue_screen.dart';

class SyncQueue {
  static final _repo = SyncQueueRepository();

  /// Queues a report to be sent to the backend.
  static Future<void> queueReport({
    required String type,
    required Map<String, dynamic> payload,
  }) async {
    await _repo.queueReport(HealthSignal(type: type, payload: payload));
  }

  /// Opens the Sync Queue management screen.
  static void showSyncQueue(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const SyncQueueScreen()),
    );
  }
}
