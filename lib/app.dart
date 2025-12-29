import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'config/theme.dart';
import 'config/router.dart';
import 'providers/language_provider.dart';

class VerhuurAgendaApp extends ConsumerWidget {
  const VerhuurAgendaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final preferredLocale = ref.watch(languageProvider);

    return MaterialApp.router(
      title: 'VerhuurAgenda',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      routerConfig: router,

      // Localization
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('nl'), // Dutch (default)
        Locale('en'), // English
      ],
      // Use preferred locale if set, otherwise use system default
      locale: preferredLocale,
    );
  }
}
