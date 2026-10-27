import 'package:diary_core/diary_core.dart';
import 'package:flutter/material.dart';

import '../features/aufnahme/recording_screen.dart';
import '../features/daten/backup_screen.dart';
import '../features/daten/restore_screen.dart';
import '../features/daten/transfer_screen.dart';
import '../features/eintrag/entry_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/rueckblick/week_review_screen.dart';
import '../features/schreiben/write_screen.dart';
import 'motion.dart';

/// Argumente der Eintrags-Route: Eintrags-ID und optional eine Position, zu
/// der die Wiedergabe springt (Suchtreffer).
class EntryRouteArgs {
  const EntryRouteArgs(this.entryId, {this.jumpTo});
  final String entryId;
  final Duration? jumpTo;
}

/// Argumente der Schreiben-Route (D17): der Kalendertag und optional eine
/// vorhandene Notiz, die bearbeitet wird.
class WriteRouteArgs {
  const WriteRouteArgs(this.day, {this.noteId});
  final LocalDay day;
  final String? noteId;
}

/// Benannte Routen. Die drei Reiter (Heute, Kalender, Einstellungen) leben in
/// der Start-Route; Aufnahme, Eintrag, Schreiben und Woche liegen darüber.
abstract final class AppRoutes {
  /// Vollbild-Aufnahme (M3: ein Tipp, und es läuft).
  static const String record = '/record';

  /// Eintrag; Argument ist eine Eintrags-ID als [String] oder [EntryRouteArgs].
  static const String entry = '/entry';

  /// Schreiben statt sprechen (D17); Argument [WriteRouteArgs].
  static const String write = '/write';

  /// Wochenrückblick aus dem Kalender (D17).
  static const String week = '/week';

  /// Onboarding zum erneuten Ansehen aus den Einstellungen.
  static const String onboarding = '/onboarding';

  /// Backup erstellen, wiederherstellen und Gerätewechsel (D6).
  static const String backup = '/backup';
  static const String restore = '/restore';
  static const String transfer = '/transfer';

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case record:
        return SheetPageRoute<void>(
          settings: settings,
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
      case write:
        final args = settings.arguments;
        if (args is! WriteRouteArgs) return null;
        return SheetPageRoute<void>(
          settings: settings,
          builder: (_) => WriteScreen(day: args.day, noteId: args.noteId),
        );
      case week:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const WeekReviewScreen(),
        );
      case onboarding:
        return SheetPageRoute<void>(
          settings: settings,
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

  /// Öffnet den Schreiben-Bildschirm für [day], optional für eine Notiz.
  static Future<void> openWrite(
    BuildContext context,
    LocalDay day, {
    String? noteId,
  }) {
    return Navigator.of(context)
        .pushNamed(write, arguments: WriteRouteArgs(day, noteId: noteId));
  }
}

/// Vollbild-Blatt von unten (Aufnahme, Schreiben, Onboarding): kommt in
/// 320 ms mit der Schubladen-Kurve herauf und geht denselben Weg wieder
/// hinunter (räumliche Konsistenz, docs/12 Abschnitt 8). Die Seite darunter
/// wird leicht abgedunkelt. Mit "Reduce Motion" nur ein Überblenden.
class SheetPageRoute<T> extends PageRouteBuilder<T> {
  SheetPageRoute({required WidgetBuilder builder, super.settings})
    : super(
        fullscreenDialog: true,
        transitionDuration: Motion.sheet,
        reverseTransitionDuration: Motion.sheet,
        pageBuilder: (context, animation, secondaryAnimation) =>
            builder(context),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Motion.drawer,
            reverseCurve: Motion.drawer.flipped,
          );
          if (Motion.reduced(context)) {
            return FadeTransition(opacity: curved, child: child);
          }
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          );
        },
      );

  @override
  Color? get barrierColor => const Color(0x33000000);
}
