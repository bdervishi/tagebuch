import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/settings_notifier.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/schutz/lock_gate.dart';
import '../l10n/app_localizations.dart';
import 'routes.dart';
import 'shell.dart';
import 'theme.dart';

/// Wurzel der App: Material 3, Lokalisierung (de als Vorlage, en), ruhiges
/// warmes Farbschema mit dunklem Modus. Die Schriftskalierung des Systems
/// wird nicht überschrieben. Über dem Navigator liegt der [AppLockGate]
/// (D23): Sichtschutz im Hintergrund und Sperrbildschirm über allen Routen.
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
      builder: (context, child) =>
          AppLockGate(child: child ?? const SizedBox.shrink()),
    );
  }
}

/// Entscheidet innerhalb der Start-Route zwischen Onboarding und Hauptansicht,
/// sobald Dienste und Einstellungen geladen sind (im Browser: Datenbank
/// öffnen, Schlüssel entpacken). Bewusst kein Routenwechsel: So greift die
/// Umschaltung sofort, sobald das Onboarding abgeschlossen ist.
class RootScreen extends ConsumerWidget {
  const RootScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(settingsProvider);
    return switch (settings) {
      AsyncData(:final value) when !value.onboardingDone => OnboardingScreen(
        onFinished: () =>
            ref.read(settingsProvider.notifier).completeOnboarding(),
      ),
      AsyncData() => const AppShell(),
      AsyncError() => Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(l10n.startError, textAlign: TextAlign.center),
            ),
          ),
        ),
      ),
      _ => Scaffold(
        body: Center(
          child: Semantics(
            label: l10n.loadingLabel,
            child: const CircularProgressIndicator(),
          ),
        ),
      ),
    };
  }
}
