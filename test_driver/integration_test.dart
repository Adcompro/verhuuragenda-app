import 'dart:io';
// onScreenshot is only exposed via the *extended* driver entry-point.
import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() => integrationDriver(
      onScreenshot: (String name, List<int> bytes, [Map<String, Object?>? args]) async {
        final dir = Directory('screenshots');
        if (!dir.existsSync()) dir.createSync(recursive: true);
        final file = File('screenshots/$name.png');
        await file.writeAsBytes(bytes);
        return true;
      },
    );
