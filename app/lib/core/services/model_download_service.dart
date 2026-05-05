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
      String id = data[0];
      int status = data[1];
      int progress = data[2];
      // You can broadcast this via StreamController to UI
    });

    FlutterDownloader.registerCallback(downloadCallback);
    _isInitialized = true;
  }

  @pragma('vm:entry-point')
  static void downloadCallback(String id, int status, int progress) {
    final SendPort? sendPort = IsolateNameServer.lookupPortByName('downloader_send_port');
    sendPort?.send([id, status, progress]);
  }

  Future<String?> startDownload() async {
    final dir = await getApplicationDocumentsDirectory();
    final savePath = dir.path;

    // Check if file already exists
    final file = File('$savePath/$modelFileName');
    if (await file.exists()) {
      return null; // Already downloaded
    }

    final taskId = await FlutterDownloader.enqueue(
      url: modelUrl,
      savedDir: savePath,
      fileName: modelFileName,
      showNotification: true, // show download progress in status bar
      openFileFromNotification: false,
    );
    return taskId;
  }

  Future<String> getModelPath() async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/$modelFileName';
  }

  Future<bool> isModelDownloaded() async {
    final path = await getModelPath();
    return File(path).exists();
  }
}
