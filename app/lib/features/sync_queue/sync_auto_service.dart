import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:jansetu/features/sync_queue/sync_queue_db.dart';
import 'package:jansetu/features/sync_queue/sync_worker.dart';

class SyncAutoService {
  SyncAutoService._internal();

  static final SyncAutoService instance = SyncAutoService._internal();

  final Connectivity _connectivity = Connectivity();
  final SyncQueueDatabase _db = SyncQueueDatabase.instance;

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _initialized = false;
  bool _isSyncing = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    await _attemptSyncIfNeeded();

    _subscription = _connectivity.onConnectivityChanged.listen((results) async {
      if (results.any((result) => result != ConnectivityResult.none)) {
        await _attemptSyncIfNeeded();
      }
    });
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
    _initialized = false;
  }

  Future<void> notifyQueueUpdated() async {
    await _attemptSyncIfNeeded();
  }

  Future<void> _attemptSyncIfNeeded() async {
    if (_isSyncing) return;

    final connectivity = await _connectivity.checkConnectivity();
    if (connectivity.every((result) => result == ConnectivityResult.none)) {
      return;
    }

    final pendingCount = await _db.getPendingCount();
    if (pendingCount == 0) {
      return;
    }

    _isSyncing = true;
    try {
      await SyncWorker.performSync();
    } finally {
      _isSyncing = false;
    }
  }
}
