import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/settings_notifier.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../l10n/app_localizations.dart';
import 'routes.dart';
import 'shell.dart';
import 'theme.dart';

/// Wurzel der App: Material 3, Lokalisierung (de als Vorlage, en), ruhiges
/// warmes Farbschema mit dunklem Modus. Die Schriftskalierung des Systems
/// wird nicht überschrieben.
class TagebuchApp extends StatelessWidget {
  const TagebuchApp({super.key, this.locale});

  /// Erzwingt eine Sprache (für Tests); sonst entscheidet das System.
  final Locale? locale;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      theme: buildAppTheme(Brightness.light),
      darkTheme: buildAppTheme(Brightness.dark),
      themeMode: ThemeMode.system,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const RootScreen(),
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}

/// Entscheidet innerhalb der Start-Route zwischen Onboarding und Hauptansicht.
/// Bewusst kein Routenwechsel: So greift die Umschaltung sofort, sobald das
/// Onboarding abgeschlossen oder übersprungen wurde.
class RootScreen extends ConsumerWidget {
  const RootScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboardingDone = ref.watch(
      settingsProvider.select((s) => s.onboardingDone),
    );
    if (!onboardingDone) {
      return OnboardingScreen(
        onFinished: () =>
            ref.read(settingsProvider.notifier).completeOnboarding(),
      );
    }
    return const AppShell();
  }
}
