import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:verhuuragenda_app/main.dart' as app;

/// App Store screenshot tour. Drives the host app through the
/// most-important screens and saves a screenshot per scene. Runs on
/// Codemagic's ios-ipad-preview workflow against an iPad Pro 12.9"
/// simulator.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> snap(String name) async {
    try {
      await binding.convertFlutterSurfaceToImage();
    } catch (_) {/* ignored */}
    await binding.takeScreenshot(name);
    // ignore: avoid_print
    print('SCREENSHOT TEST: ✓ $name captured');
  }

  Future<void> settle(WidgetTester t, [int seconds = 2]) async {
    await t.pumpAndSettle(Duration(seconds: seconds));
  }

  Future<bool> tapIcon(
    WidgetTester t, {
    required IconData outlined,
    required IconData filled,
    String? label,
  }) async {
    var f = find.byIcon(outlined);
    if (f.evaluate().isEmpty) f = find.byIcon(filled);
    if (f.evaluate().isEmpty) {
      // ignore: avoid_print
      print('SCREENSHOT TEST: × icon not found ${label ?? outlined}');
      return false;
    }
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
    return true;
  }

  testWidgets('App Store tour', (tester) async {
    // ignore: avoid_print
    print('SCREENSHOT TEST: launching app');
    app.main();
    await settle(tester, 5);

    // ==== Login screen screenshot ===================================
    await snap('00_login');

    // ==== Sign in ====================================================
    const email = String.fromEnvironment(
      'SCREENSHOT_LOGIN_EMAIL',
      defaultValue: 'review@apple.com',
    );
    const password = String.fromEnvironment(
      'SCREENSHOT_LOGIN_PASSWORD',
      defaultValue: 'Review123!',
    );

    final fields = find.byType(TextField);
    if (fields.evaluate().length >= 2) {
      // ignore: avoid_print
      print('SCREENSHOT TEST: typing credentials for $email');
      await tester.enterText(fields.at(0), email);
      await settle(tester);
      await tester.enterText(fields.at(1), password);
      await settle(tester);

      final btn = find.byType(ElevatedButton);
      if (btn.evaluate().isNotEmpty) {
        await tester.tap(btn.first);
        await settle(tester, 8);
      }
    }

    // ==== Auto-accept terms screen if it appears =====================
    final cb = find.byType(Checkbox);
    if (cb.evaluate().isNotEmpty) {
      // ignore: avoid_print
      print('SCREENSHOT TEST: accepting terms');
      await tester.tap(cb.first);
      await settle(tester);
      final cta = find.widgetWithText(FilledButton, 'Akkoord & doorgaan');
      if (cta.evaluate().isNotEmpty) {
        await tester.tap(cta.first);
        await settle(tester, 6);
      }
    }

    // ==== 01: Dashboard ===============================================
    await snap('01_dashboard');

    // ==== 02: Calendar ================================================
    if (await tapIcon(tester,
        outlined: Icons.calendar_month_outlined,
        filled: Icons.calendar_month,
        label: 'calendar')) {
      await snap('02_calendar');
    }

    // ==== 03: Bookings list ==========================================
    if (await tapIcon(tester,
        outlined: Icons.book_outlined,
        filled: Icons.book,
        label: 'bookings')) {
      await snap('03_bookings');
    }

    // ==== 04: Accommodations =========================================
    if (await tapIcon(tester,
        outlined: Icons.home_work_outlined,
        filled: Icons.home_work,
        label: 'accommodations')) {
      await snap('04_accommodations');
    }

    // ==== 05: Chat inbox =============================================
    if (await tapIcon(tester,
        outlined: Icons.chat_bubble_outline,
        filled: Icons.chat_bubble,
        label: 'chat')) {
      await snap('05_chat_inbox');

      // ==== 06: Open first conversation thread =======================
      final tiles = find.byType(ListTile);
      if (tiles.evaluate().isNotEmpty) {
        await tester.tap(tiles.first);
        await settle(tester, 3);
        await snap('06_chat_thread');
        await tester.pageBack();
        await settle(tester);
      }
    }

    // ==== 07: Cleaning ===============================================
    if (await tapIcon(tester,
        outlined: Icons.cleaning_services_outlined,
        filled: Icons.cleaning_services,
        label: 'cleaning')) {
      await snap('07_cleaning');
    }

    // ==== 08: Maintenance ============================================
    if (await tapIcon(tester,
        outlined: Icons.build_outlined,
        filled: Icons.build,
        label: 'maintenance')) {
      await snap('08_maintenance');
    }

    // ==== 09: Settings ===============================================
    if (await tapIcon(tester,
        outlined: Icons.settings_outlined,
        filled: Icons.settings,
        label: 'settings')) {
      await snap('09_settings');
    }

    // ignore: avoid_print
    print('SCREENSHOT TEST: tour complete');
  });
}
