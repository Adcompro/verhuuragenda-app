import 'dart:io';
// onScreenshot is only exposed via the *extended* driver entry-point.
import 'package:image/image.dart' as img;
import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() => integrationDriver(
      onScreenshot: (String name, List<int> bytes, [Map<String, Object?>? args]) async {
        final dir = Directory('screenshots');
        if (!dir.existsSync()) dir.createSync(recursive: true);

        // App Store Connect rejects PNGs with an alpha channel.
        // Decode, composite onto white, re-encode without alpha.
        final decoded = img.decodePng(bytes);
        List<int> outBytes = bytes;
        if (decoded != null) {
          final flat = img.Image(
            width: decoded.width,
            height: decoded.height,
            numChannels: 3,
          );
          img.fill(flat, color: img.ColorRgb8(255, 255, 255));
          img.compositeImage(flat, decoded);
          outBytes = img.encodePng(flat);
        }

        final file = File('screenshots/$name.png');
        await file.writeAsBytes(outBytes);
        return true;
      },
    );
