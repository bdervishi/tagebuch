import 'package:flutter/material.dart';

import '../features/aufnahme/recording_screen.dart';
import '../features/daten/backup_screen.dart';
import '../features/daten/restore_screen.dart';
import '../features/daten/transfer_screen.dart';
import '../features/eintrag/entry_screen.dart';
import '../features/onboarding/onboarding_screen.dart';

/// Argumente der Eintrags-Route: Eintrags-ID und optional eine Position, zu
/// der die Wiedergabe springt (Suchtreffer).
class EntryRouteArgs {
  const EntryRouteArgs(this.entryId, {this.jumpTo});
  final String entryId;
  final Duration? jumpTo;
}

/// Benannte Routen. Die drei Reiter (Heute, Kalender, Einstellungen) leben in
/// der Start-Route; Aufnahme und Eintrag liegen darüber.
abstract final class AppRoutes {
  /// Vollbild-Aufnahme (M3: ein Tipp, und es läuft).
  static const String record = '/record';

  /// Eintrag; Argument ist eine Eintrags-ID als [String] oder [EntryRouteArgs].
  static const String entry = '/entry';

  /// Onboarding zum erneuten Ansehen aus den Einstellungen.
  static const String onboarding = '/onboarding';

  /// Backup erstellen, wiederherstellen und Gerätewechsel (D6).
  static const String backup = '/backup';
  static const String restore = '/restore';
  static const String transfer = '/transfer';

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case record:
        return MaterialPageRoute<void>(
          settings: settings,
          fullscreenDialog: true,
          builder: (_) => const RecordingScreen(),
        );
      case entry:
        final args = switch (settings.arguments) {
          final String id => EntryRouteArgs(id),
          final EntryRouteArgs a => a,
          _ => null,
        };
        if (args == null) return null;
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) =>
              EntryScreen(entryId: args.entryId, jumpTo: args.jumpTo),
        );
      case onboarding:
        return MaterialPageRoute<void>(
          settings: settings,
          fullscreenDialog: true,
          builder: (context) =>
              OnboardingScreen(onFinished: () => Navigator.of(context).pop()),
        );
      case backup:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const BackupScreen(),
        );
      case restore:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const RestoreScreen(),
        );
      case transfer:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const TransferScreen(),
        );
    }
    return null;
  }

  /// Öffnet den Eintrag mit der gegebenen ID, optional an einer Position.
  static Future<void> openEntry(
    BuildContext context,
    String entryId, {
    Duration? jumpTo,
  }) {
    return Navigator.of(context)
        .pushNamed(entry, arguments: EntryRouteArgs(entryId, jumpTo: jumpTo));
  }

  /// Öffnet die Aufnahme als Vollbild-Route.
  static Future<void> openRecording(BuildContext context) {
    return Navigator.of(context).pushNamed(record);
  }
}
