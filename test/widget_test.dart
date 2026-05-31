// Smoke test: the onboarding screen renders its first slide.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:authenticator/screens/onboarding_screen.dart';
import 'package:authenticator/state/app_controller.dart';
import 'package:authenticator/theme/app_theme.dart';
import 'package:authenticator/widgets/app_scope.dart';

void main() {
  testWidgets('Onboarding renders its first slide', (WidgetTester tester) async {
    await tester.pumpWidget(
      AppScope(
        theme: const AppTheme(),
        themeController: ThemeController(),
        appController: AppController(),
        child: MaterialApp(
          home: OnboardingScreen(onDone: () {}),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Your keys, encrypted'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });
}
