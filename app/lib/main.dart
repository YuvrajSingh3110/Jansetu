import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:jansetu/app/app.dart';
import 'package:jansetu/features/sync_queue/sync_auto_service.dart';
import 'package:workmanager/workmanager.dart';
import 'package:jansetu/features/sync_queue/sync_worker.dart';
import 'package:jansetu/core/services/model_download_service.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    return await SyncWorker.performSync();
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  await Workmanager().initialize(
    callbackDispatcher,
  );
  await SyncAutoService.instance.initialize();
  await ModelDownloadService().initialize();

  // Lock to portrait — this app targets low-spec Android phones in the field.
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Use edge-to-edge with a translucent status bar.
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('en'),
        Locale('hi'),
        Locale('or'),
        Locale('bn'),
        Locale('pa'),
        Locale('bho'),
      ],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: const JansetuApp(),
    ),
  );
}
