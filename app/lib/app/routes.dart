import 'package:diary_core/diary_core.dart';
import 'package:flutter/material.dart';

import '../features/aufnahme/recording_screen.dart';
import '../features/bewegung/movement_screen.dart';
import '../features/daten/backup_screen.dart';
import '../features/daten/restore_screen.dart';
import '../features/daten/transfer_screen.dart';
import '../features/eintrag/entry_screen.dart';
import '../features/lesebuch/book_detail_screen.dart';
import '../features/lesebuch/books_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/reader/reader_screen.dart';
import '../features/rueckblick/week_review_screen.dart';
import '../features/schreiben/write_screen.dart';
import '../features/schutz/pin_flow_screen.dart';
import '../features/zitate/quotes_screen.dart';
import '../features/wege/goal_detail_screen.dart';
import '../features/wege/goals_screen.dart';
import 'motion.dart';

/// Argumente der Eintrags-Route: Eintrags-ID und optional eine Position, zu
/// der die Wiedergabe springt (Suchtreffer).
class EntryRouteArgs {
  const EntryRouteArgs(this.entryId, {this.jumpTo});
  final String entryId;
  final Duration? jumpTo;
}

/// Argumente der Aufnahme-Route: [quick] öffnet die Aufnahme im Schnellmodus
/// "Sprachnotiz" (D22): ohne Impulse, sonst identisch.
class RecordRouteArgs {
  const RecordRouteArgs({this.quick = false});
  final bool quick;
}

/// Argumente der Schreiben-Route (D17): der Kalendertag und optional eine
/// vorhandene Notiz, die bearbeitet wird.
class WriteRouteArgs {
  const WriteRouteArgs(this.day, {this.noteId});
  final LocalDay day;
  final String? noteId;
}

/// Benannte Routen. Die vier Reiter (Heute, Kalender, Mehr, Einstellungen)
/// leben in der Start-Route; Aufnahme, Eintrag, Schreiben, Woche, Wege,
/// Lesebuch, Zitate und Daten liegen darüber.
abstract final class AppRoutes {
  /// Vollbild-Aufnahme (M3: ein Tipp, und es läuft); Argument optional
  /// [RecordRouteArgs].
  static const String record = '/record';

  /// Eintrag; Argument ist eine Eintrags-ID als [String] oder [EntryRouteArgs].
  static const String entry = '/entry';

  /// Schreiben statt sprechen (D17); Argument [WriteRouteArgs].
  static const String write = '/write';

  /// Wochenrückblick aus dem Kalender (D17).
  static const String week = '/week';

  /// Wege: Ziele mit Etappen (D19); Details mit Ziel-ID als [String].
  static const String goals = '/goals';
  static const String goal = '/goal';

  /// Zitatenschatz (D20).
  static const String quotes = '/quotes';

  /// Lesebuch: Bücher und Passagen (D21); Details mit Buch-ID als [String].
  static const String books = '/books';
  static const String book = '/book';

  /// E-Reader (D25) mit Buch-ID als [String].
  static const String read = '/read';

  /// Bewegungspausen und Übungen (D24).
  static const String movement = '/movement';

  /// Onboarding zum erneuten Ansehen aus den Einstellungen.
  static const String onboarding = '/onboarding';

  /// Backup erstellen, wiederherstellen und Gerätewechsel (D6).
  static const String backup = '/backup';
  static const String restore = '/restore';
  static const String transfer = '/transfer';

  /// PIN der App-Sperre vergeben, ändern oder zum Ausschalten prüfen (D23);
  /// Argument [PinFlowKind], Ergebnis `true` bei Abschluss.
  static const String pin = '/pin';

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case record:
        final args = settings.arguments;
        final quick = args is RecordRouteArgs && args.quick;
        return SheetPageRoute<void>(
          settings: settings,
          builder: (_) => RecordingScreen(quick: quick),
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
      case goals:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const GoalsScreen(),
        );
      case quotes:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const QuotesScreen(),
        );
      case goal:
        final id = settings.arguments;
        if (id is! String) return null;
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => GoalDetailScreen(goalId: id),
        );
      case books:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const BooksScreen(),
        );
      case movement:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const MovementScreen(),
        );
      case book:
        final id = settings.arguments;
        if (id is! String) return null;
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => BookDetailScreen(bookId: id),
        );
      case read:
        final id = settings.arguments;
        if (id is! String) return null;
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => ReaderScreen(bookId: id),
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
      case pin:
        final kind = settings.arguments;
        if (kind is! PinFlowKind) return null;
        return SheetPageRoute<bool>(
          settings: settings,
          builder: (_) => PinFlowScreen(kind: kind),
        );
    }
    return null;
  }

  /// Öffnet das PIN-Blatt; `true`, wenn der Ablauf abgeschlossen wurde.
  static Future<bool> openPinFlow(
    BuildContext context,
    PinFlowKind kind,
  ) async {
    final done = await Navigator.of(context)
        .pushNamed<bool>(pin, arguments: kind);
    return done ?? false;
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

  /// Öffnet die Aufnahme als Vollbild-Route; mit [quick] als Sprachnotiz
  /// ohne Impulse (D22).
  static Future<void> openRecording(
    BuildContext context, {
    bool quick = false,
  }) {
    return Navigator.of(context).pushNamed(
      record,
      arguments: quick ? const RecordRouteArgs(quick: true) : null,
    );
  }

  /// Öffnet den Bildschirm "Wege".
  static Future<void> openGoals(BuildContext context) =>
      Navigator.of(context).pushNamed(goals);

  /// Öffnet den Zitatenschatz.
  static Future<void> openQuotes(BuildContext context) =>
      Navigator.of(context).pushNamed(quotes);

  /// Öffnet die Details eines Wegs.
  static Future<void> openGoal(BuildContext context, String goalId) =>
      Navigator.of(context).pushNamed(goal, arguments: goalId);

  /// Öffnet das Lesebuch.
  static Future<void> openBooks(BuildContext context) =>
      Navigator.of(context).pushNamed(books);

  /// Öffnet den Bildschirm "Bewegung" (D24).
  static Future<void> openMovement(BuildContext context) =>
      Navigator.of(context).pushNamed(movement);

  /// Öffnet die Details eines Buchs.
  static Future<void> openBook(BuildContext context, String bookId) =>
      Navigator.of(context).pushNamed(book, arguments: bookId);

  /// Öffnet den E-Reader für ein Buch mit Datei (D25).
  static Future<void> openReader(BuildContext context, String bookId) =>
      Navigator.of(context).pushNamed(read, arguments: bookId);

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
