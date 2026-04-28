import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:jansetu/core/theme/app_theme.dart';
import 'package:jansetu/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:jansetu/features/chat/presentation/bloc/chat_event.dart';
import 'package:jansetu/features/chat/presentation/bloc/chat_state.dart';
import 'package:jansetu/features/chat/presentation/widgets/chat_bubble.dart';
import 'package:jansetu/features/chat/presentation/widgets/chat_input_bar.dart';

class ChatScreen extends StatelessWidget {
  final String? initialPrompt;
  final Uint8List? initialImageBytes;
  final String? initialImageName;

  const ChatScreen({
    super.key,
    this.initialPrompt,
    this.initialImageBytes,
    this.initialImageName,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final bloc = ChatBloc();
        if (initialImageBytes != null && initialImageName != null) {
          bloc.add(ImageAttachmentSelected(
            imageBytes: initialImageBytes!,
            imageName: initialImageName!,
          ));
        }
        if (initialPrompt != null && initialPrompt!.isNotEmpty) {
          bloc.add(SendMessage(initialPrompt!));
        }
        return bloc;
      },
      child: const _ChatScreenView(),
    );
  }
}

class _ChatScreenView extends StatelessWidget {
  const _ChatScreenView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: AppColors.textOnPrimary,
        title: Text('navAskAI'.tr()),
        actions: [
          BlocBuilder<ChatBloc, ChatState>(
            buildWhen: (previous, current) => previous.isSpeechMuted != current.isSpeechMuted,
            builder: (context, state) {
              return IconButton(
                icon: Icon(
                  state.isSpeechMuted ? Icons.volume_off : Icons.volume_up,
                  color: AppColors.textOnPrimary,
                ),
                onPressed: () {
                  context.read<ChatBloc>().add(const ToggleSpeechMute());
                },
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: BlocBuilder<ChatBloc, ChatState>(
              builder: (context, state) {
                if (state.messages.isEmpty) {
                  return Center(
                    child: Text(
                      'micTitle'.tr(),
                      style: AppTextStyles.subtitle,
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                
                return ListView.builder(
                  reverse: false,
                  itemCount: state.messages.length,
                  itemBuilder: (context, index) {
                    return ChatBubble(message: state.messages[index]);
                  },
                );
              },
            ),
          ),
          const ChatInputBar(),
        ],
      ),
    );
  }
}
