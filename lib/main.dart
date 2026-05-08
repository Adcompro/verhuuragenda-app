import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app.dart';
import 'core/storage/secure_storage.dart';
import 'services/push_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for local caching
  await Hive.initFlutter();

  // Initialize secure storage
  await SecureStorage.init();

  // Initialize Firebase Messaging — fails gracefully if the project
  // config files aren't bundled yet.
  await PushService.instance.initialize();

  runApp(
    const ProviderScope(
      child: CasaMioApp(),
    ),
  );
}
