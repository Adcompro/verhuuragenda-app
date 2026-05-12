import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:verhuuragenda_app/main.dart' as app;
import 'package:verhuuragenda_app/screens/guest/guest_home_screen.dart'
    show ChatBubble;

/// App Store screenshot tour. Drives the host app through the
/// most-important screens and saves a screenshot per scene.
///
/// Important: spinners (CircularProgressIndicator) on the dashboard
/// and other API-driven screens cause pumpAndSettle to time out (it
/// waits for *all* animations to stop, which a spinner never does).
/// We use plain `pump(Duration)` for time advances and only call
/// pumpAndSettle right after a stable user action like enterText.
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

  /// Wait for the given duration without requiring all animations to
  /// stop. Survives spinners. Pumps repeatedly so widgets actually rebuild.
  Future<void> wait(WidgetTester t, [int seconds = 2]) async {
    final frames = seconds * 10; // 100ms per pump
    for (var i = 0; i < frames; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
  }

  Future<bool> tapIcon(
    WidgetTester t, {
    required IconData outlined,
    required IconData filled,
    IconData? altOutlined,
    IconData? altFilled,
    String? label,
  }) async {
    var f = find.byIcon(outlined);
    if (f.evaluate().isEmpty) f = find.byIcon(filled);
    if (f.evaluate().isEmpty && altOutlined != null) {
      f = find.byIcon(altOutlined);
    }
    if (f.evaluate().isEmpty && altFilled != null) {
      f = find.byIcon(altFilled);
    }
    if (f.evaluate().isEmpty) {
      // ignore: avoid_print
      print('SCREENSHOT TEST: × icon not found ${label ?? outlined.codePoint}');
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
    await wait(t, 1);
    try {
      await t.tap(f.first);
    } catch (e) {
      // ignore: avoid_print
      print('SCREENSHOT TEST: × tap failed for ${label ?? "icon"}: $e');
      return false;
    }
    await wait(t, 3);
    return true;
  }

  testWidgets('App Store tour', (tester) async {
    // Apply preferred language BEFORE app.main() so the app launches
    // already in the right locale. The language code comes from the
    // SCREENSHOT_LANG dart-define passed by the codemagic pipeline
    // (one run per language).
    const lang = String.fromEnvironment('SCREENSHOT_LANG', defaultValue: '');
    if (lang.isNotEmpty) {
      SharedPreferences.setMockInitialValues({'preferred_language': lang});
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('preferred_language', lang);
      // ignore: avoid_print
      print('SCREENSHOT TEST: preferred_language set to $lang');
    }

    final langPrefix = lang.isEmpty ? '' : '${lang}_';

    Future<void> snapL(String name) => snap('$langPrefix$name');

    // ignore: avoid_print
    print('SCREENSHOT TEST: launching app');
    app.main();
    await wait(tester, 6);

    // ==== Login screen screenshot ===================================
    await snapL('00_login');

    // ==== Sign in ====================================================
    const email = String.fromEnvironment(
      'SCREENSHOT_LOGIN_EMAIL',
      defaultValue: 'review@apple.com',
    );
    const password = String.fromEnvironment(
      'SCREENSHOT_LOGIN_PASSWORD',
      defaultValue: 'Review123!',
    );

    try {
      // Wait extra long for the login form to actually mount (iPad cold
      // boot + Riverpod auth provider hydration takes a while).
      await wait(tester, 6);

      // TextFormField is more reliable than TextField — the latter is
      // an internal child of the former and can race with form mount.
      var fields = find.byType(TextFormField);
      var attempt = 0;
      while (fields.evaluate().length < 2 && attempt < 6) {
        await wait(tester, 2);
        fields = find.byType(TextFormField);
        attempt++;
      }
      // ignore: avoid_print
      print('SCREENSHOT TEST: found ${fields.evaluate().length} TextFormFields after $attempt retries');

      if (fields.evaluate().length < 2) {
        // Fallback: maybe it's just plain TextField
        final fallback = find.byType(EditableText);
        // ignore: avoid_print
        print('SCREENSHOT TEST: fallback EditableText count = ${fallback.evaluate().length}');
        if (fallback.evaluate().length >= 2) fields = fallback;
      }

      if (fields.evaluate().length >= 2) {
        // ignore: avoid_print
        print('SCREENSHOT TEST: typing credentials for $email');
        await tester.tap(fields.at(0));
        await wait(tester, 1);
        await tester.enterText(fields.at(0), email);
        await wait(tester, 1);
        await tester.tap(fields.at(1));
        await wait(tester, 1);
        await tester.enterText(fields.at(1), password);
        await wait(tester, 1);

        // Find any tappable button with login text
        var btn = find.byType(ElevatedButton);
        if (btn.evaluate().isEmpty) btn = find.byType(FilledButton);
        if (btn.evaluate().isNotEmpty) {
          // ignore: avoid_print
          print('SCREENSHOT TEST: tapping login button');
          await tester.tap(btn.first);
          await wait(tester, 10); // wait for network call + navigation
        } else {
          // ignore: avoid_print
          print('SCREENSHOT TEST: × no login button found');
        }
      } else {
        // ignore: avoid_print
        print('SCREENSHOT TEST: × not enough text fields, skipping login');
        // Diagnostic: list visible widget types
        try {
          final scaffolds = find.byType(Scaffold).evaluate().length;
          final texts = find.byType(Text).evaluate().length;
          // ignore: avoid_print
          print('SCREENSHOT TEST: diag — Scaffold=$scaffolds Text=$texts');
        } catch (_) {}
      }
    } catch (e) {
      // ignore: avoid_print
      print('SCREENSHOT TEST: × login flow threw: $e');
    }

    // ==== Auto-accept terms screen if it appears =====================
    try {
      final cb = find.byType(Checkbox);
      if (cb.evaluate().isNotEmpty) {
        // Scroll the card to the "Gedragsregels in de chat" section so
        // the screenshot proves the EULA contains the UGC zero-tolerance
        // language Apple Guideline 1.2 requires.
        try {
          await tester.dragUntilVisible(
            find.textContaining('Gedragsregels'),
            find.byType(SingleChildScrollView).first,
            const Offset(0, -200),
          );
        } catch (_) {/* fall back to top of card */}
        await wait(tester, 2);
        await snapL('12_terms');
        // ignore: avoid_print
        print('SCREENSHOT TEST: accepting terms');
        await tester.tap(cb.first);
        await wait(tester, 1);
        final cta = find.widgetWithText(FilledButton, 'Akkoord & doorgaan');
        if (cta.evaluate().isNotEmpty) {
          await tester.tap(cta.first);
          await wait(tester, 6);
        }
      }
    } catch (e) {
      // ignore: avoid_print
      print('SCREENSHOT TEST: × terms flow threw: $e');
    }

    // ==== Enable all modules so cleaning/maintenance show ============
    try {
      if (await tapIcon(tester,
          outlined: Icons.settings_outlined,
          filled: Icons.settings,
          label: 'settings')) {
        await wait(tester, 2);
        final modulesTile = find.text('Modules');
        if (modulesTile.evaluate().isNotEmpty) {
          await tester.tap(modulesTile.first);
          await wait(tester, 2);
          final resetBtn = find.byType(OutlinedButton);
          if (resetBtn.evaluate().isNotEmpty) {
            await tester.tap(resetBtn.first);
            await wait(tester, 2);
          }
          await tester.pageBack();
          await wait(tester, 1);
        }
        await tester.pageBack();
        await wait(tester, 2);
      }
    } catch (e) {
      // ignore: avoid_print
      print('SCREENSHOT TEST: × module enable threw: $e');
    }

    // ==== Dashboard ===================================================
    // On iPad the NavigationRail uses dashboard_outlined; on phone the
    // bottom nav uses home_outlined. Try both.
    await tapIcon(tester,
        outlined: Icons.dashboard_outlined,
        filled: Icons.dashboard,
        altOutlined: Icons.home_outlined,
        altFilled: Icons.home,
        label: 'home/dashboard');
    await wait(tester, 4); // give dashboard time to load API data
    await snapL('01_dashboard');

    // ==== Calendar ====================================================
    if (await tapIcon(tester,
        outlined: Icons.calendar_month_outlined,
        filled: Icons.calendar_month,
        label: 'calendar')) {
      await snapL('02_calendar');
    }

    // ==== Bookings list ==============================================
    if (await tapIcon(tester,
        outlined: Icons.book_outlined,
        filled: Icons.book,
        label: 'bookings')) {
      await snapL('03_bookings');
    }

    // ==== Accommodations =============================================
    if (await tapIcon(tester,
        outlined: Icons.home_work_outlined,
        filled: Icons.home_work,
        label: 'accommodations')) {
      await snapL('04_accommodations');
    }

    // ==== Chat inbox =================================================
    if (await tapIcon(tester,
        outlined: Icons.chat_bubble_outline,
        filled: Icons.chat_bubble,
        label: 'chat')) {
      await snapL('05_chat_inbox');

      try {
        final tiles = find.byType(ListTile);
        if (tiles.evaluate().isNotEmpty) {
          await tester.tap(tiles.first);
          await wait(tester, 3);
          await snapL('06_chat_thread');

          // ==== Report bottom sheet (Apple Guideline 1.2 demo) =====
          try {
            // Long-press the first GestureDetector that wraps a peer's
            // ChatBubble. Find a bubble and trigger long-press on its
            // parent.
            final bubbles = find.byType(ChatBubble);
            if (bubbles.evaluate().isNotEmpty) {
              await tester.longPress(bubbles.first);
              await wait(tester, 2);
              await snapL('13_report');
              // Close the bottom sheet
              final cancel = find.text('Annuleren');
              if (cancel.evaluate().isNotEmpty) {
                await tester.tap(cancel.first);
                await wait(tester, 1);
              } else {
                // dismiss by tapping outside / pressing back
                await tester.tapAt(const Offset(20, 20));
                await wait(tester, 1);
              }
            } else {
              // ignore: avoid_print
              print('SCREENSHOT TEST: × no ChatBubble found for report');
            }
          } catch (e) {
            // ignore: avoid_print
            print('SCREENSHOT TEST: × report flow threw: $e');
          }

          // ==== Block menu popup (Apple Guideline 1.2 demo) ========
          try {
            final more = find.byIcon(Icons.more_vert);
            if (more.evaluate().isNotEmpty) {
              await tester.tap(more.first);
              await wait(tester, 2);
              await snapL('14_block');
              // Dismiss the popup menu without selecting
              await tester.tapAt(const Offset(20, 20));
              await wait(tester, 1);
            } else {
              // ignore: avoid_print
              print('SCREENSHOT TEST: × no more_vert icon for block');
            }
          } catch (e) {
            // ignore: avoid_print
            print('SCREENSHOT TEST: × block menu threw: $e');
          }

          await tester.pageBack();
          await wait(tester, 1);
        }
      } catch (e) {
        // ignore: avoid_print
        print('SCREENSHOT TEST: × chat thread threw: $e');
      }
    }

    // ==== Cleaning ===================================================
    if (await tapIcon(tester,
        outlined: Icons.cleaning_services_outlined,
        filled: Icons.cleaning_services,
        label: 'cleaning')) {
      await snapL('07_cleaning');
    }

    // ==== Maintenance ================================================
    if (await tapIcon(tester,
        outlined: Icons.build_outlined,
        filled: Icons.build,
        label: 'maintenance')) {
      await snapL('08_maintenance');
    }

    // ==== Settings ===================================================
    if (await tapIcon(tester,
        outlined: Icons.settings_outlined,
        filled: Icons.settings,
        label: 'settings')) {
      await snapL('09_settings');

      // ==== Subscription screen =====================================
      // Apple wants a screenshot of where the subscription is offered
      // for the IAP review. Tap the Abonnement tile, snap.
      try {
        final subTile = find.text('Abonnement');
        if (subTile.evaluate().isNotEmpty) {
          // ignore: avoid_print
          print('SCREENSHOT TEST: opening subscription screen');
          await tester.tap(subTile.first);
          await wait(tester, 5);
          await snapL('11_subscription');
          await tester.pageBack();
          await wait(tester, 2);
        } else {
          // ignore: avoid_print
          print('SCREENSHOT TEST: × Abonnement tile not found');
        }
      } catch (e) {
        // ignore: avoid_print
        print('SCREENSHOT TEST: × subscription flow threw: $e');
      }

      // ==== Team member form ========================================
      // Settings → Team → + → form. Showcases per-menu visibility.
      try {
        final teamTile = find.text('Team');
        if (teamTile.evaluate().isNotEmpty) {
          // ignore: avoid_print
          print('SCREENSHOT TEST: opening Team list');
          await tester.tap(teamTile.first);
          await wait(tester, 4);
          // tap the FAB / + button — TeamListScreen uses person_add,
          // other screens use plain add. Try both.
          var addBtn = find.byIcon(Icons.person_add);
          if (addBtn.evaluate().isEmpty) addBtn = find.byIcon(Icons.add);
          if (addBtn.evaluate().isNotEmpty) {
            // ignore: avoid_print
            print('SCREENSHOT TEST: opening team member form');
            await tester.tap(addBtn.first);
            await wait(tester, 4);
            // Type a sample name to make the form look populated
            try {
              final fields = find.byType(TextFormField);
              if (fields.evaluate().length >= 2) {
                await tester.enterText(fields.at(0), 'Anna van Dijk');
                await tester.pump(const Duration(milliseconds: 200));
                await tester.enterText(fields.at(1), 'anna@altena.digital');
                await wait(tester, 1);
              }
            } catch (_) {/* ignore */}
            // Scroll down a bit so menu rights section is visible
            try {
              await tester.drag(
                find.byType(ListView).first,
                const Offset(0, -300),
              );
              await wait(tester, 2);
            } catch (_) {/* ignore */}
            await snapL('10_team_member');
          } else {
            // ignore: avoid_print
            print('SCREENSHOT TEST: × no + icon to open team form');
          }
        } else {
          // ignore: avoid_print
          print('SCREENSHOT TEST: × Team tile not found');
        }
      } catch (e) {
        // ignore: avoid_print
        print('SCREENSHOT TEST: × team flow threw: $e');
      }
    }

    // ignore: avoid_print
    print('SCREENSHOT TEST: tour complete');
  });
}
