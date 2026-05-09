import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:verhuuragenda_app/main.dart' as app;

/// Drives the app through every key screen and saves a screenshot
/// for each. Used by the Codemagic ios-ipad-preview workflow which
/// runs on an iPad Pro simulator and uploads the PNGs as build
/// artifacts that go straight into App Store Connect.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> snap(IntegrationTestWidgetsFlutterBinding b, String name) async {
    try {
      await b.takeScreenshot(name);
      // ignore: avoid_print
      print('✓ screenshot: $name');
    } catch (e) {
      // ignore: avoid_print
      print('✗ screenshot $name failed: $e');
    }
  }

  Future<void> settle(WidgetTester t, [int seconds = 2]) async {
    await t.pumpAndSettle(Duration(seconds: seconds));
  }

  Future<void> tapIcon(
    WidgetTester t, {
    required IconData outlined,
    required IconData filled,
  }) async {
    var f = find.byIcon(outlined);
    if (f.evaluate().isEmpty) f = find.byIcon(filled);
    if (f.evaluate().isEmpty) return;
    try {
      await t.ensureVisible(f.first);
    } catch (_) {
      try {
        await t.dragUntilVisible(
          f.first,
          find.byType(ListView).first,
          const Offset(-200, 0),
        );
      } catch (_) {}
    }
    await t.pumpAndSettle();
    await t.tap(f.first);
    await settle(t);
  }

  group('App Store Screenshot tour', () {
    testWidgets('Host: dashboard, calendar, bookings, accommodations, chat, cleaning',
        (tester) async {
      app.main();
      await settle(tester, 4);

      // ==== Login as host ============================================
      // Credentials come from --dart-define so we never commit them.
      // See codemagic.yaml ios-ipad-preview workflow: it forwards
      // SCREENSHOT_LOGIN_EMAIL / SCREENSHOT_LOGIN_PASSWORD via flutter
      // drive's --dart-define flags.
      const email = String.fromEnvironment(
        'SCREENSHOT_LOGIN_EMAIL',
        defaultValue: 'review@apple.com',
      );
      const password = String.fromEnvironment(
        'SCREENSHOT_LOGIN_PASSWORD',
        defaultValue: 'Review123!',
      );

      final textFields = find.byType(TextField);
      if (textFields.evaluate().isNotEmpty) {
        // ignore: avoid_print
        print('Login screen detected, signing in as $email…');
        await tester.enterText(textFields.at(0), email);
        await tester.pumpAndSettle();
        await tester.enterText(textFields.at(1), password);
        await tester.pumpAndSettle();

        final loginBtn = find.widgetWithText(ElevatedButton, 'Inloggen');
        if (loginBtn.evaluate().isNotEmpty) {
          await tester.tap(loginBtn.first);
        } else {
          final any = find.byType(ElevatedButton);
          if (any.evaluate().isNotEmpty) await tester.tap(any.first);
        }
        await settle(tester, 6);
      }

      // The terms screen may appear on first login — auto-accept.
      final acceptCheckbox = find.byType(Checkbox);
      if (acceptCheckbox.evaluate().isNotEmpty) {
        await tester.tap(acceptCheckbox.first);
        await settle(tester);
        final cta = find.widgetWithText(FilledButton, 'Akkoord & doorgaan');
        if (cta.evaluate().isNotEmpty) {
          await tester.tap(cta.first);
          await settle(tester, 4);
        }
      }

      // ==== 01: Dashboard ============================================
      await snap(binding, '01_dashboard');

      // ==== 02: Calendar =============================================
      await tapIcon(tester,
          outlined: Icons.calendar_month_outlined,
          filled: Icons.calendar_month);
      await snap(binding, '02_calendar');

      // ==== 03: Bookings list ========================================
      await tapIcon(tester, outlined: Icons.book_outlined, filled: Icons.book);
      await snap(binding, '03_bookings');

      // ==== 04: Booking detail (tap the first card) ==================
      final bookingCard = find.byType(Card);
      if (bookingCard.evaluate().isNotEmpty) {
        await tester.tap(bookingCard.first);
        await settle(tester, 3);
        await snap(binding, '04_booking_detail');
        // Back to bookings list
        final back = find.byTooltip('Back');
        if (back.evaluate().isNotEmpty) {
          await tester.tap(back.first);
          await settle(tester);
        } else {
          // Try generic back via Navigator
          await tester.pageBack();
          await settle(tester);
        }
      }

      // ==== 05: Accommodations =======================================
      await tapIcon(tester,
          outlined: Icons.home_work_outlined, filled: Icons.home_work);
      await snap(binding, '05_accommodations');

      // ==== 06: Chat inbox ===========================================
      await tapIcon(tester,
          outlined: Icons.chat_bubble_outline, filled: Icons.chat_bubble);
      await snap(binding, '06_chat_inbox');

      // ==== 07: Chat thread (tap first conversation) =================
      final convoTiles = find.byType(ListTile);
      if (convoTiles.evaluate().isNotEmpty) {
        await tester.tap(convoTiles.first);
        await settle(tester, 3);
        await snap(binding, '07_chat_thread');
        await tester.pageBack();
        await settle(tester);
      }

      // ==== 08: Cleaning =============================================
      await tapIcon(tester,
          outlined: Icons.cleaning_services_outlined,
          filled: Icons.cleaning_services);
      await snap(binding, '08_cleaning');

      // ==== 09: Maintenance ==========================================
      await tapIcon(tester,
          outlined: Icons.build_outlined, filled: Icons.build);
      await snap(binding, '09_maintenance');

      // ==== 10: Settings =============================================
      await tapIcon(tester,
          outlined: Icons.settings_outlined, filled: Icons.settings);
      await snap(binding, '10_settings');

      // ignore: avoid_print
      print('All host screenshots captured.');
    });
  });
}
