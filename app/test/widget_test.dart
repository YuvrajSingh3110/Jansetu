import 'package:flutter_test/flutter_test.dart';
import 'package:jansetu/app/app.dart';

void main() {
  testWidgets('App smoke test — renders without crashing', (tester) async {
    await tester.pumpWidget(const JansetuApp());
    // Just verify the app boots. Detailed widget tests will come later.
    expect(find.byType(JansetuApp), findsOneWidget);
  });
}
