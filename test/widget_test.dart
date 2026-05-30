// Basic smoke test: the app boots into onboarding.

import 'package:flutter_test/flutter_test.dart';

import 'package:authenticator/main.dart';

void main() {
  testWidgets('App launches to onboarding', (WidgetTester tester) async {
    await tester.pumpWidget(const BitanonApp());
    await tester.pump();

    // The first onboarding slide and its primary CTA should be present.
    expect(find.text('Your keys, encrypted'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });
}
