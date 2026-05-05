import 'dart:developer' as developer;
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path_provider/path_provider.dart';

class ModelDownloadService {
  ModelDownloadService._internal();
  static final ModelDownloadService _instance = ModelDownloadService._internal();
  factory ModelDownloadService() => _instance;

  static const String modelUrl = 'https://example.com/gemma-4-E2B-it.litertlm';
  static const String modelFileName = 'gemma-4-E2B-it.litertlm';

  /// The classic Downloads folder path on Android — where users typically
  /// place a pre-downloaded model manually.
  static const String _androidDownloadsPath =
      '/storage/emulated/0/Download/$modelFileName';

  final ReceivePort _port = ReceivePort();
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    await FlutterDownloader.initialize(
      debug: true,
      ignoreSsl: true,
    );

    IsolateNameServer.registerPortWithName(_port.sendPort, 'downloader_send_port');
    _port.listen((dynamic data) {
      // Forward to UI via downloadCallback — no processing needed here.
    });

    FlutterDownloader.registerCallback(downloadCallback);
    _isInitialized = true;
  }

  @pragma('vm:entry-point')
  static void downloadCallback(String id, int status, int progress) {
    final SendPort? sendPort = IsolateNameServer.lookupPortByName('downloader_send_port');
    sendPort?.send([id, status, progress]);
  }

  /// Returns the resolved path of the model if it is available, or null.
  ///
  /// Priority order:
  ///   1. Android Downloads folder (user pre-downloaded the model manually).
  ///   2. App documents directory (downloaded by this service previously).
  Future<String?> resolveModelPath() async {
    // 1. Check the user's Downloads folder first (original behaviour)
    final downloadsFile = File(_androidDownloadsPath);
    if (await downloadsFile.exists()) {
      developer.log(
        'Model found in Downloads folder: $_androidDownloadsPath',
        name: 'ModelDownloadService',
      );
      return _androidDownloadsPath;
    }

    // 2. Check the app-private documents directory
    final appDir = await getApplicationDocumentsDirectory();
    final appFile = File('${appDir.path}/$modelFileName');
    if (await appFile.exists()) {
      developer.log(
        'Model found in app directory: ${appFile.path}',
        name: 'ModelDownloadService',
      );
      return appFile.path;
    }

    developer.log('Model not found in any known location.', name: 'ModelDownloadService');
    return null;
  }

  /// Returns true if the model is available from any location.
  Future<bool> isModelAvailable() async {
    return (await resolveModelPath()) != null;
  }

  /// Enqueues a background download into the app's documents directory.
  /// Returns the flutter_downloader task ID.
  Future<String?> startDownload() async {
    final appDir = await getApplicationDocumentsDirectory();
    final savePath = appDir.path;

    // Guard: do not re-download if already present anywhere
    if (await isModelAvailable()) {
      developer.log('Model already available — skipping download.', name: 'ModelDownloadService');
      return null;
    }

    developer.log('Enqueueing model download to $savePath', name: 'ModelDownloadService');
    final taskId = await FlutterDownloader.enqueue(
      url: modelUrl,
      savedDir: savePath,
      fileName: modelFileName,
      showNotification: true,
      openFileFromNotification: false,
    );
    return taskId;
  }
}
