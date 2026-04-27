import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jansetu/app/app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App smoke test renders without crashing', (tester) async {
    await EasyLocalization.ensureInitialized();

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

    expect(find.byType(JansetuApp), findsOneWidget);
  });
}
