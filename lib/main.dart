import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app.dart';
import 'core/storage/secure_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for local caching
  await Hive.initFlutter();

  // Initialize Firebase for push notifications
  await Firebase.initializeApp();

  // Initialize secure storage
  await SecureStorage.init();

  runApp(
    const ProviderScope(
      child: VerhuurAgendaApp(),
    ),
  );
}
