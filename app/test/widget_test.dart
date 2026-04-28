import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jansetu/app/app.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('App smoke test renders without crashing', (tester) async {
    await tester.pumpWidget(
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
    await tester.pumpAndSettle();

    // Just verify the app boots. Detailed widget tests will come later.
    expect(find.byType(JansetuApp), findsOneWidget);
  });
}
