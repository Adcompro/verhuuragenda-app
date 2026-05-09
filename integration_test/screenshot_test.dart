import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:verhuuragenda_app/main.dart' as app;

/// Minimal smoke screenshot test. Goal: prove the framework writes
/// PNGs at all on this Codemagic mac runner. Once this works we can
/// expand back to a full login + tour flow.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('login screen + dashboard tour', (tester) async {
    // ignore: avoid_print
    print('SCREENSHOT TEST: launching app');
    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 5));

    // ignore: avoid_print
    print('SCREENSHOT TEST: app launched, taking 00_login screenshot');
    try {
      await binding.convertFlutterSurfaceToImage();
    } catch (e) {
      // ignore: avoid_print
      print('convertFlutterSurfaceToImage threw: $e');
    }
    await binding.takeScreenshot('00_login');
    // ignore: avoid_print
    print('SCREENSHOT TEST: 00_login captured');

    // Login attempt — best effort, ignore errors
    const email = String.fromEnvironment(
      'SCREENSHOT_LOGIN_EMAIL',
      defaultValue: 'review@apple.com',
    );
    const password = String.fromEnvironment(
      'SCREENSHOT_LOGIN_PASSWORD',
      defaultValue: 'Review123!',
    );

    try {
      final fields = find.byType(TextField);
      if (fields.evaluate().length >= 2) {
        // ignore: avoid_print
        print('SCREENSHOT TEST: typing credentials for $email');
        await tester.enterText(fields.at(0), email);
        await tester.pumpAndSettle();
        await tester.enterText(fields.at(1), password);
        await tester.pumpAndSettle();

        final btn = find.byType(ElevatedButton);
        if (btn.evaluate().isNotEmpty) {
          await tester.tap(btn.first);
          await tester.pumpAndSettle(const Duration(seconds: 8));
        }

        // Auto-accept terms screen if it appears
        final cb = find.byType(Checkbox);
        if (cb.evaluate().isNotEmpty) {
          await tester.tap(cb.first);
          await tester.pumpAndSettle();
          final cta = find.widgetWithText(FilledButton, 'Akkoord & doorgaan');
          if (cta.evaluate().isNotEmpty) {
            await tester.tap(cta.first);
            await tester.pumpAndSettle(const Duration(seconds: 6));
          }
        }
      }
    } catch (e) {
      // ignore: avoid_print
      print('Login attempt failed (non-fatal): $e');
    }

    // ignore: avoid_print
    print('SCREENSHOT TEST: post-login, taking 01_dashboard');
    try {
      await binding.convertFlutterSurfaceToImage();
    } catch (_) {}
    await binding.takeScreenshot('01_dashboard');
    // ignore: avoid_print
    print('SCREENSHOT TEST: done');
  });
}
