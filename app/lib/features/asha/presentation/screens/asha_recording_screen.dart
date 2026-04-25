import 'package:flutter/material.dart';
import 'package:jansetu/features/asha/presentation/asha_navigation.dart';
import 'package:jansetu/features/asha/presentation/widgets/asha_scaffold.dart';
import 'package:jansetu/sync_queue.dart';

class AshaRecordingScreen extends StatelessWidget {
  const AshaRecordingScreen({super.key});

  Future<void> _saveReport(BuildContext context) async {
    await SyncQueue.queueReport(
      type: 'voice_triage',
      payload: const {
        'age_bucket': '35y',
        'fever_days': 3,
        'symptoms': ['cough', 'breathlessness'],
        'location': 'Rampur',
      },
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Report saved to sync queue.')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AshaScaffold(
      title: 'Recording...',
      subtitle: 'Gemma 4 E4B - offline',
      activeTab: AshaTab.home,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _LanguageChip(label: 'Hindi', active: true),
                _LanguageChip(label: 'Bhojpuri'),
                _LanguageChip(label: 'Odia'),
                _LanguageChip(label: 'English'),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: const Color(0xFFD7EEE7),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _WaveBar(height: 22),
                  _WaveBar(height: 34),
                  _WaveBar(height: 18),
                  _WaveBar(height: 42),
                  _WaveBar(height: 30),
                  _WaveBar(height: 46),
                  _WaveBar(height: 26),
                  _WaveBar(height: 40),
                ],
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Live transcript',
              style: TextStyle(fontSize: 13, color: Color(0xFF6C7889)),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                '"Female, around 35 years, fever for three days, cough and breathing difficulty..."',
                style: TextStyle(
                  fontSize: 18,
                  height: 1.4,
                  color: Color(0xFF243142),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Extracted (function call)',
              style: TextStyle(fontSize: 13, color: Color(0xFF6C7889)),
            ),
            const SizedBox(height: 8),
            const Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _TagChip(label: 'F - ~35 yrs', bg: Color(0xFFE3F2E9), fg: Color(0xFF276F46)),
                _TagChip(label: 'Fever - 3 days', bg: Color(0xFFF8E9C6), fg: Color(0xFF8A5B00)),
                _TagChip(label: 'Cough', bg: Color(0xFFF8E9C6), fg: Color(0xFF8A5B00)),
                _TagChip(label: 'Breathlessness', bg: Color(0xFFFBE0E0), fg: Color(0xFFAF3F3F)),
                _TagChip(label: 'Rampur', bg: Color(0xFFE3F2E9), fg: Color(0xFF276F46)),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFBE7E7),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'Breathlessness flag - recommend PHC referral today',
                style: TextStyle(
                  fontSize: 18,
                  height: 1.4,
                  color: Color(0xFFA63D3D),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 50),
                      foregroundColor: const Color(0xFF374355),
                      side: const BorderSide(color: Color(0xFFD7DDE7)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Retake'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _saveReport(context),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 50),
                      backgroundColor: const Color(0xFF0E7B60),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Confirm & save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageChip extends StatelessWidget {
  const _LanguageChip({required this.label, this.active = false});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: active ? const Color(0xFF0E7B60) : Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: active ? const Color(0xFF0E7B60) : const Color(0xFFCDD4DE),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: active ? Colors.white : const Color(0xFF435064),
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _WaveBar extends StatelessWidget {
  const _WaveBar({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 4,
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF0E7B60),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({
    required this.label,
    required this.bg,
    required this.fg,
  });

  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
