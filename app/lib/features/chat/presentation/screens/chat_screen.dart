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

import 'dart:isolate';
import 'dart:ui';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:jansetu/core/services/model_download_service.dart';

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

class _ChatScreenView extends StatefulWidget {
  const _ChatScreenView();

  @override
  State<_ChatScreenView> createState() => _ChatScreenViewState();
}

class _ChatScreenViewState extends State<_ChatScreenView> {
  bool _isCheckingModel = true;
  bool _isModelMissing = false;
  String? _downloadTaskId;
  int _downloadProgress = 0;
  int _downloadStatus = 0;
  final ReceivePort _port = ReceivePort();

  @override
  void initState() {
    super.initState();
    _checkModelStatus();
    _bindBackgroundIsolate();
  }

  @override
  void dispose() {
    _unbindBackgroundIsolate();
    super.dispose();
  }

  void _bindBackgroundIsolate() {
    final isSuccess = IsolateNameServer.registerPortWithName(_port.sendPort, 'downloader_send_port');
    if (!isSuccess) {
      IsolateNameServer.removePortNameMapping('downloader_send_port');
      IsolateNameServer.registerPortWithName(_port.sendPort, 'downloader_send_port');
    }
    _port.listen((dynamic data) {
      if (!mounted) return;
      final String id = data[0];
      final int status = data[1];
      final int progress = data[2];

      if (_downloadTaskId != null && id == _downloadTaskId) {
        setState(() {
          _downloadStatus = status;
          _downloadProgress = progress;
          // Status 3 is complete in flutter_downloader
          if (status == 3) {
            _isModelMissing = false;
            // Force re-init of LLM service
            context.read<ChatBloc>().add(const GenerateSessionHeader()); // dummy event or just rely on state
          }
        });
      }
    });
  }

  void _unbindBackgroundIsolate() {
    IsolateNameServer.removePortNameMapping('downloader_send_port');
    _port.close();
  }

  Future<void> _checkModelStatus() async {
    final downloadService = ModelDownloadService();
    final isDownloaded = await downloadService.isModelDownloaded();
    if (mounted) {
      setState(() {
        _isCheckingModel = false;
        _isModelMissing = !isDownloaded;
      });
    }
  }

  Future<void> _startDownload() async {
    final connectivityResultList = await Connectivity().checkConnectivity();
    if (connectivityResultList.contains(ConnectivityResult.mobile) &&
        !connectivityResultList.contains(ConnectivityResult.wifi)) {
      if (!mounted) return;
      final shouldContinue = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Mobile Data Warning'),
          content: const Text('You are on mobile data. The file is ~1.5GB. Downloading may incur charges. Continue?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Download'),
            ),
          ],
        ),
      );
      if (shouldContinue != true) return;
    }

    final taskId = await ModelDownloadService().startDownload();
    if (mounted && taskId != null) {
      setState(() {
        _downloadTaskId = taskId;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingModel) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_isModelMissing) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.primaryDark,
          foregroundColor: AppColors.textOnPrimary,
          title: Text('navAskAI'.tr()),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.download_rounded, size: 64, color: AppColors.primary),
                const SizedBox(height: 16),
                Text(
                  'AI Model Required',
                  style: AppTextStyles.headerTitle.copyWith(color: AppColors.primaryDark),
                ),
                const SizedBox(height: 8),
                Text(
                  'To chat offline, you need to download the Jansetu AI model (~1.5GB). This happens only once.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.roleSubtitle,
                ),
                const SizedBox(height: 32),
                if (_downloadTaskId != null) ...[
                  LinearProgressIndicator(value: _downloadProgress > 0 ? _downloadProgress / 100 : null),
                  const SizedBox(height: 8),
                  Text('Downloading... $_downloadProgress%'),
                ] else
                  ElevatedButton.icon(
                    onPressed: _startDownload,
                    icon: const Icon(Icons.download),
                    label: const Text('Download Model'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: AppColors.textOnPrimary,
        title: Text('navAskAI'.tr()),
        actions: [
          BlocBuilder<ChatBloc, ChatState>(
            buildWhen: (previous, current) => previous.messages.isEmpty != current.messages.isEmpty,
            builder: (context, state) {
              if (state.messages.isEmpty) return const SizedBox.shrink();
              return TextButton.icon(
                onPressed: () {
                  context.read<ChatBloc>().add(const SubmitReportRequested());
                },
                icon: const Icon(Icons.check_circle_outline, color: AppColors.textOnPrimary),
                label: Text(
                  'submitReport'.tr(),
                  style: AppTextStyles.buttonText.copyWith(fontSize: 14, color: AppColors.textOnPrimary),
                ),
              );
            },
          ),
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
      body: BlocListener<ChatBloc, ChatState>(
        listenWhen: (previous, current) =>
            previous.isSubmittingReport != current.isSubmittingReport ||
            previous.isReportSubmitted != current.isReportSubmitted,
        listener: (context, state) {
          if (state.isSubmittingReport) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => const Center(child: CircularProgressIndicator()),
            );
          } else if (state.isReportSubmitted) {
            Navigator.of(context).pop(); // dismiss dialog
            Navigator.of(context).pop(); // pop ChatScreen
          } else if (!state.isSubmittingReport && !state.isReportSubmitted) {
            // Dismiss dialog on error/failure
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to submit report. Please try again.')),
            );
          }
        },
        child: Column(
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
      ),
    );
  }
}
