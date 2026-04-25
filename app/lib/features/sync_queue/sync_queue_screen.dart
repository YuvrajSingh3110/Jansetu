import 'package:flutter/material.dart';
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
  final _db = SyncQueueDatabase.instance;

  List<Map<String, dynamic>> _reports = [];
  int _pendingCount = 0;
  int _pendingSize = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final reports = await _db.getAllReports();
    final count = await _db.getPendingCount();
    final size = await _db.getPendingSize();
    setState(() {
      _reports = reports;
      _pendingCount = count;
      _pendingSize = size;
      _isLoading = false;
    });
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
          : Column(
              children: [
                _buildSummaryCard(),
                Expanded(
                  child: ListView.separated(
                    itemCount: _reports.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final report = _reports[index];
                      return _buildReportItem(report);
                    },
                  ),
                ),
              ],
            ),
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
            Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: () async {
                      await SyncQueue.queueReport(
                        type: 'test_signal',
                        payload: {'test': 'data', 'val': 123},
                      );
                      _loadData();
                    },
                    child: const Text('Add Test'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Starting sync...')),
                      );
                      await SyncWorker.performSync();
                      _loadData();
                    },
                    child: const Text('Try sync'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportItem(Map<String, dynamic> report) {
    final status = report['status'];
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
      subtitle: Text('TS: ${report['timestamp']}\nSize: ${report['payload_size']} bytes'),
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
