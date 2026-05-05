import 'dart:async';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:jansetu/core/theme/app_theme.dart';
import 'package:jansetu/features/chat/data/chat_history_repository.dart';
import 'package:jansetu/features/chat/domain/models/chat_session.dart';
import 'package:jansetu/features/chat/presentation/screens/read_only_chat_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final ChatHistoryRepository _repository = ChatHistoryRepository();
  List<ChatSession> _sessions = [];
  bool _isLoading = true;
  StreamSubscription<void>? _subscription;

  @override
  void initState() {
    super.initState();
    _loadSessions();
    _subscription = _repository.onHistoryChanged.listen((_) {
      _loadSessions();
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _loadSessions() async {
    final sessions = await _repository.getChatSessions();
    if (mounted) {
      setState(() {
        _sessions = sessions;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'navHistory'.tr(),
              style: AppTextStyles.roleTitle.copyWith(fontSize: 24),
            ),
            const SizedBox(height: 10),
            Text(
              'historySubtitle'.tr(),
              style: AppTextStyles.roleSubtitle.copyWith(fontSize: 15),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _sessions.isEmpty
                      ? Center(
                          child: Text(
                            'noPastChats'.tr(),
                            style: AppTextStyles.bodyText.copyWith(color: AppColors.textMuted),
                          ),
                        )
                      : ListView.separated(
                          itemCount: _sessions.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final session = _sessions[index];
                            return _buildSessionCard(context, session);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionCard(BuildContext context, ChatSession session) {
    final formattedDate = DateFormat('MMM d, yyyy • h:mm a').format(session.timestamp);

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ReadOnlyChatScreen(session: session),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardFill,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.chat_bubble_outline, color: AppColors.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.header,
                    style: AppTextStyles.roleTitle.copyWith(fontSize: 16),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formattedDate,
                    style: AppTextStyles.bodyText.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
