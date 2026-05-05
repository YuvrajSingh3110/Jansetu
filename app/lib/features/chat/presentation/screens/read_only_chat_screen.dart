import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:jansetu/core/theme/app_theme.dart';
import 'package:jansetu/features/chat/domain/models/chat_session.dart';
import 'package:jansetu/features/chat/presentation/widgets/chat_bubble.dart';

class ReadOnlyChatScreen extends StatelessWidget {
  final ChatSession session;

  const ReadOnlyChatScreen({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          session.header,
          style: AppTextStyles.headerSubtitle.copyWith(
            color: AppColors.textPrimary,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                itemCount: session.messages.length,
                itemBuilder: (context, index) {
                  return ChatBubble(message: session.messages[index]);
                },
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: AppColors.cardFill,
              child: Text(
                'readOnlyInfo'.tr(),
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyText.copyWith(
                  color: AppColors.textMuted,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
