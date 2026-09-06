import 'package:flutter/material.dart';

import '../features/aufnahme/recording_screen.dart';
import '../features/eintrag/entry_screen.dart';
import '../features/onboarding/onboarding_screen.dart';

/// Benannte Routen. Die drei Reiter (Heute, Kalender, Einstellungen) leben in
/// der Start-Route; Aufnahme und Eintrag liegen darüber.
abstract final class AppRoutes {
  /// Vollbild-Aufnahme (M3: ein Tipp, und es läuft).
  static const String record = '/record';

  /// Eintrag; Argument ist die Eintrags-ID als [String].
  static const String entry = '/entry';

  /// Onboarding zum erneuten Ansehen aus den Einstellungen.
  static const String onboarding = '/onboarding';

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case record:
        return MaterialPageRoute<void>(
          settings: settings,
          fullscreenDialog: true,
          builder: (_) => const RecordingScreen(),
        );
      case entry:
        final id = settings.arguments;
        if (id is! String) return null;
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => EntryScreen(entryId: id),
        );
      case onboarding:
        return MaterialPageRoute<void>(
          settings: settings,
          fullscreenDialog: true,
          builder: (context) =>
              OnboardingScreen(onFinished: () => Navigator.of(context).pop()),
        );
    }
    return null;
  }

  /// Öffnet den Eintrag mit der gegebenen ID.
  static Future<void> openEntry(BuildContext context, String entryId) {
    return Navigator.of(context).pushNamed(entry, arguments: entryId);
  }

  /// Öffnet die Aufnahme als Vollbild-Route.
  static Future<void> openRecording(BuildContext context) {
    return Navigator.of(context).pushNamed(record);
  }
}
