import 'package:flutter/material.dart';
import 'package:jansetu/features/asha/data/asha_repository.dart';
import 'package:jansetu/features/sync_queue/sync_queue_db.dart';
import 'package:jansetu/features/sync_queue/sync_queue_repository.dart';
import 'package:jansetu/features/sync_queue/sync_worker.dart';
import 'package:jansetu/sync_queue.dart';

class SyncQueueScreen extends StatefulWidget {
  const SyncQueueScreen({super.key});

  @override
  State<SyncQueueScreen> createState() => _SyncQueueScreenState();
}

class _SyncQueueScreenState extends State<SyncQueueScreen> {
  final _repo = SyncQueueRepository();
  final _ashaRepository = AshaRepository();
  final _db = SyncQueueDatabase.instance;

  List<Map<String, dynamic>> _reports = [];
  int _pendingCount = 0;
  int _pendingSize = 0;
  bool _isLoading = true;
  bool _isSyncing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);
      final reports = await _db.getAllReports();
      final count = await _db.getPendingCount();
      final size = await _db.getPendingSize();
      if (mounted) {
        setState(() {
          _reports = reports;
          _pendingCount = count;
          _pendingSize = size;
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sync Queue'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await _repo.clearSent();
              _loadData();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.sync_problem, size: 48, color: Colors.orange),
              const SizedBox(height: 16),
              const Text(
                'Unable to load sync queue',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.black54),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        _buildSummaryCard(),
        Expanded(
          child: _reports.isEmpty
              ? const Center(
                  child: Text(
                    'No queued reports yet.',
                    style: TextStyle(color: Colors.black54),
                  ),
                )
              : ListView.separated(
                  itemCount: _reports.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final report = _reports[index];
                    return _buildReportItem(report);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Queue Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Pending Reports: $_pendingCount'),
            Text('Total Payload: ${(_pendingSize / 1024).toStringAsFixed(2)} KB'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () async {
                      final payload = await _ashaRepository.buildReportPayload(
                        transcript: 'Female adult with fever and cough for two days in Rampur',
                      );
                      await SyncQueue.queueReport(
                        type: 'chw_report',
                        payload: payload,
                      );
                      _loadData();
                    },
                    child: const Text('Add Test'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                    ),
                    onPressed: _isSyncing
                        ? null
                        : () async {
                            final messenger = ScaffoldMessenger.of(context);
                            messenger.showSnackBar(
                              const SnackBar(content: Text('Starting sync...')),
                            );
                            setState(() => _isSyncing = true);
                            final result = await SyncWorker.performSyncWithResult();
                            if (!mounted) return;
                            await _loadData();
                            setState(() => _isSyncing = false);
                            messenger.showSnackBar(
                              SnackBar(content: Text(result.message)),
                            );
                          },
                    child: Text(_isSyncing ? 'Syncing...' : 'Try sync'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportItem(Map<String, dynamic> report) {
    final status = report['status'];
    final payload = report['payload']?.toString() ?? '';
    final payloadPreview = payload.length > 140 ? '${payload.substring(0, 140)}...' : payload;
    Color statusColor;
    switch (status) {
      case 'SENT':
        statusColor = Colors.green;
        break;
      case 'FAILED':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    return ListTile(
      title: Text('${report['signal_type']} - $status'),
      subtitle: Text(
        'TS: ${report['timestamp']}\n'
        'Size: ${report['payload_size'] ?? 0} bytes\n'
        'Payload: $payloadPreview',
      ),
      isThreeLine: true,
      trailing: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: statusColor,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
