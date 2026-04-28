import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jansetu/core/widgets/image_source_sheet.dart';
import 'package:jansetu/core/theme/app_theme.dart';
import 'package:jansetu/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:jansetu/features/chat/presentation/bloc/chat_event.dart';
import 'package:jansetu/features/chat/presentation/bloc/chat_state.dart';
import 'package:jansetu/features/onboarding/presentation/bloc/onboarding_bloc.dart';

class ChatInputBar extends StatefulWidget {
  const ChatInputBar({super.key});

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final TextEditingController _controller = TextEditingController();

  void _sendMessage() {
    final state = context.read<ChatBloc>().state;
    if (_controller.text.trim().isEmpty && state.selectedImageBytes == null) return;
    context.read<ChatBloc>().add(
      SendMessage(
        _controller.text,
        imageBytes: state.selectedImageBytes,
        imageName: state.selectedImageName,
      ),
    );
    _controller.clear();
  }

  Future<void> _pickImage() async {
    final pickedImage = await showImageSourceSheet(context);
    if (!mounted || pickedImage == null) return;

    context.read<ChatBloc>().add(
      ImageAttachmentSelected(
        imageBytes: pickedImage.bytes,
        imageName: pickedImage.name,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChatBloc, ChatState>(
      builder: (context, state) {
        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom + 12,
            top: 12,
            left: 16,
            right: 16,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (state.selectedImageBytes != null)
                _SelectedImagePreview(
                  imageBytes: state.selectedImageBytes!,
                  imageName: state.selectedImageName ?? 'Selected image',
                  onRemove: () {
                    context.read<ChatBloc>().add(const ImageAttachmentCleared());
                  },
                ),
              if (state.isListening)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Text(
                    state.currentVoiceInput.isEmpty 
                        ? "Listening..." 
                        : state.currentVoiceInput,
                    style: const TextStyle(color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                  ),
                ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: AppColors.cardFill,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt_outlined,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Type your symptoms...',
                        hintStyle: TextStyle(color: AppColors.textMuted),
                        filled: true,
                        fillColor: AppColors.cardFill,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Send Button
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send, color: AppColors.textOnPrimary, size: 24),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Mic Button
                  GestureDetector(
                    onLongPressStart: (_) {
                      final langCode = context.read<OnboardingBloc>().state.selectedLanguage?.localeCode ?? 'hi';
                      context.read<ChatBloc>().add(VoiceInputStarted(localeCode: langCode));
                    },
                    onLongPressEnd: (_) {
                      context.read<ChatBloc>().add(const VoiceInputStopped());
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: EdgeInsets.all(state.isListening ? 16 : 12),
                      decoration: BoxDecoration(
                        color: state.isListening ? Colors.redAccent : AppColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: state.isListening ? [
                          BoxShadow(color: Colors.redAccent.withValues(alpha: 0.4), blurRadius: 10, spreadRadius: 4)
                        ] : [],
                      ),
                      child: const Icon(Icons.mic, color: AppColors.textOnPrimary, size: 24),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}


class _SelectedImagePreview extends StatelessWidget {
  const _SelectedImagePreview({
    required this.imageBytes,
    required this.imageName,
    required this.onRemove,
  });

  final Uint8List imageBytes;
  final String imageName;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardFill,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(
              imageBytes,
              width: 64,
              height: 64,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              imageName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.close, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}