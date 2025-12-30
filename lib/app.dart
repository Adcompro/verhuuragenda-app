import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'l10n/generated/app_localizations.dart';
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
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      // Use preferred locale if set, otherwise use system default
      locale: preferredLocale,
    );
  }
}
