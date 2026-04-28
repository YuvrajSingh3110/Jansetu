import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:jansetu/core/theme/app_theme.dart';
import 'package:jansetu/features/chat/domain/models/chat_message.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: message.isUser ? AppColors.primary : AppColors.cardFill,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: message.isUser
                ? const Radius.circular(20)
                : const Radius.circular(4),
            bottomRight: message.isUser
                ? const Radius.circular(4)
                : const Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        child: _BubbleBody(message: message),
      ),
    );
  }
}

class _BubbleBody extends StatelessWidget {
  const _BubbleBody({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final bubbleText = message.text.isEmpty && !message.isComplete
        ? '...'
        : message.text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (message.imageBytes != null) ...[
          _BubbleImage(imageBytes: message.imageBytes!, isUser: message.isUser),
          if (bubbleText.isNotEmpty) const SizedBox(height: 12),
        ],
        if (bubbleText.isNotEmpty)
          Text(
            bubbleText,
            style: TextStyle(
              color: message.isUser
                  ? AppColors.textOnPrimary
                  : AppColors.textPrimary,
              fontSize: 16,
              height: 1.4,
            ),
          ),
      ],
    );
  }
}

class _BubbleImage extends StatelessWidget {
  const _BubbleImage({required this.imageBytes, required this.isUser});

  final Uint8List imageBytes;
  final bool isUser;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.memory(
        imageBytes,
        width: 200,
        height: 200,
        fit: BoxFit.cover,
      ),
    );
  }
}
