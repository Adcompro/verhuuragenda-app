import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:verhuuragenda_app/main.dart' as app;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Screenshot Tests', () {
    testWidgets('Take screenshots of all main screens', (tester) async {
      // Start the app
      app.main();

      // Wait for app to initialize
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Check if we're on login screen
      final emailField = find.byType(TextField).first;
      final isLoginScreen = emailField.evaluate().isNotEmpty;

      if (isLoginScreen) {
        print('Login screen detected, logging in...');

        // Find email and password fields
        final textFields = find.byType(TextField);
        expect(textFields, findsWidgets);

        // Enter email
        await tester.enterText(textFields.at(0), 'review@apple.com');
        await tester.pumpAndSettle();

        // Enter password
        await tester.enterText(textFields.at(1), 'Review123!');
        await tester.pumpAndSettle();

        // Find and tap login button
        final loginButton = find.widgetWithText(ElevatedButton, 'Inloggen');
        if (loginButton.evaluate().isNotEmpty) {
          await tester.tap(loginButton);
        } else {
          // Try finding any elevated button
          final anyButton = find.byType(ElevatedButton).first;
          await tester.tap(anyButton);
        }

        // Wait for login to complete
        await tester.pumpAndSettle(const Duration(seconds: 5));
      }

      // Wait for dashboard to fully load
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Create screenshots directory
      final screenshotDir = Directory('screenshots');
      if (!screenshotDir.existsSync()) {
        screenshotDir.createSync(recursive: true);
      }

      // Define screens with their navigation icons
      final screens = [
        ('01_dashboard', Icons.dashboard_outlined, Icons.dashboard, 'Dashboard'),
        ('02_calendar', Icons.calendar_month_outlined, Icons.calendar_month, 'Kalender'),
        ('03_bookings', Icons.book_outlined, Icons.book, 'Boekingen'),
        ('04_accommodations', Icons.home_work_outlined, Icons.home_work, 'Accommodaties'),
        ('05_guests', Icons.people_outline, Icons.people, 'Gasten'),
        ('06_cleaning', Icons.cleaning_services_outlined, Icons.cleaning_services, 'Schoonmaak'),
        ('07_maintenance', Icons.build_outlined, Icons.build, 'Onderhoud'),
        ('08_pool', Icons.pool_outlined, Icons.pool, 'Zwembad'),
        ('09_garden', Icons.yard_outlined, Icons.yard, 'Tuin'),
        ('10_campaigns', Icons.campaign_outlined, Icons.campaign, 'Campagnes'),
        ('11_statistics', Icons.bar_chart_outlined, Icons.bar_chart, 'Statistieken'),
        ('12_settings', Icons.settings_outlined, Icons.settings, 'Instellingen'),
      ];

      for (final screen in screens) {
        final (filename, outlinedIcon, filledIcon, label) = screen;
        print('Navigating to $label...');

        // Try to find and tap the navigation icon
        var iconFinder = find.byIcon(outlinedIcon);
        if (iconFinder.evaluate().isEmpty) {
          iconFinder = find.byIcon(filledIcon);
        }

        if (iconFinder.evaluate().isNotEmpty) {
          // Scroll to make icon visible if needed
          try {
            await tester.ensureVisible(iconFinder.first);
            await tester.pumpAndSettle();
          } catch (e) {
            // Try scrolling horizontally
            try {
              await tester.dragUntilVisible(
                iconFinder.first,
                find.byType(ListView).first,
                const Offset(-200, 0),
              );
              await tester.pumpAndSettle();
            } catch (e2) {
              print('Could not scroll to $label: $e2');
            }
          }

          await tester.tap(iconFinder.first);
          await tester.pumpAndSettle(const Duration(seconds: 2));
        } else {
          print('Icon not found for $label, skipping...');
          continue;
        }

        // Take screenshot
        print('Taking screenshot: $filename');
        try {
          await binding.takeScreenshot(filename);
          print('Screenshot saved: $filename');
        } catch (e) {
          print('Failed to take screenshot $filename: $e');
        }
      }

      print('All screenshots completed!');
    });
  });
}
