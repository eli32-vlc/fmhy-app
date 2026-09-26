import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fmhy_app/main.dart';

void main() {
  testWidgets('app builds in dark mode', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(
      tester.platformDispatcher.clearPlatformBrightnessTestValue,
    );

    await tester.pumpWidget(const FMApp());

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.system);
    expect(app.darkTheme, isNotNull);
    expect(
      app.darkTheme!.colorScheme.brightness,
      Brightness.dark,
      reason: 'darkTheme must resolve to a dark color scheme',
    );
  });

  testWidgets('app builds in light mode', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    addTearDown(
      tester.platformDispatcher.clearPlatformBrightnessTestValue,
    );

    await tester.pumpWidget(const FMApp());

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.theme!.colorScheme.brightness, Brightness.light);
  });

  testWidgets('both themes render a Scaffold with a navigation bar', (
    tester,
  ) async {
    for (final brightness in Brightness.values) {
      tester.platformDispatcher.platformBrightnessTestValue = brightness;
      await tester.pumpWidget(const FMApp());
      await tester.pump();
      expect(find.byType(Scaffold), findsWidgets);
      expect(find.byType(NavigationBar), findsOneWidget);
    }
    tester.platformDispatcher.clearPlatformBrightnessTestValue();
  });
}
