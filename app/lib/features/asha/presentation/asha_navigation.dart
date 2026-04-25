import 'package:flutter/material.dart';
import 'package:jansetu/features/asha/presentation/screens/asha_area_screen.dart';
import 'package:jansetu/features/asha/presentation/screens/asha_dashboard_screen.dart';
import 'package:jansetu/features/asha/presentation/screens/asha_reports_history_screen.dart';
import 'package:jansetu/sync_queue.dart';

enum AshaTab { home, reports, sync, area }

void openAshaTab(BuildContext context, AshaTab tab, {bool replace = false}) {
  if (tab == AshaTab.sync) {
    SyncQueue.showSyncQueue(context);
    return;
  }

  final Widget destination;
  switch (tab) {
    case AshaTab.home:
      destination = const AshaDashboardScreen();
      break;
    case AshaTab.reports:
      destination = const AshaReportsHistoryScreen();
      break;
    case AshaTab.sync:
      return;
    case AshaTab.area:
      destination = const AshaAreaScreen();
      break;
  }

  final route = MaterialPageRoute(builder: (_) => destination);
  if (replace) {
    Navigator.of(context).pushReplacement(route);
  } else {
    Navigator.of(context).push(route);
  }
}
