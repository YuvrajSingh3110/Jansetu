import 'package:flutter/material.dart';
import 'package:jansetu/features/asha/data/asha_worker_profile_repository.dart';
import 'package:jansetu/features/asha/presentation/screens/asha_dashboard_screen.dart';
import 'package:jansetu/features/asha/presentation/screens/asha_profile_questionnaire_screen.dart';

class AshaEntryRouterScreen extends StatefulWidget {
  const AshaEntryRouterScreen({super.key});

  @override
  State<AshaEntryRouterScreen> createState() => _AshaEntryRouterScreenState();
}

class _AshaEntryRouterScreenState extends State<AshaEntryRouterScreen> {
  final AshaWorkerProfileRepository _repository = AshaWorkerProfileRepository();
  late Future<bool> _setupFuture;

  @override
  void initState() {
    super.initState();
    _setupFuture = _repository.hasCompletedSetup();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _setupFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.data == true) {
          return const AshaDashboardScreen();
        }
        return const AshaProfileQuestionnaireScreen();
      },
    );
  }
}
