import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tagebuch_app/data/settings_notifier.dart';
import 'package:tagebuch_app/features/daten/backup_screen.dart';
import 'package:tagebuch_app/features/heute/today_screen.dart';
import 'package:tagebuch_app/features/lesebuch/books_screen.dart';
import 'package:tagebuch_app/features/mehr/more_screen.dart';
import 'package:tagebuch_app/features/rueckblick/week_review_screen.dart';
import 'package:tagebuch_app/features/wege/goals_screen.dart';
import 'package:tagebuch_app/features/zitate/quote_library.dart';
import 'package:tagebuch_app/features/zitate/quotes_screen.dart';
import 'package:tagebuch_app/widgets/backup_reminder_card.dart';

import 'test_app.dart';

/// Verlässt die oberste Route (die AppBar der App hat keinen Standard-Zurück-
/// Knopf, den `pageBack` finden könnte).
/// Rollt die Liste von "Mehr", bis [finder] sichtbar ist (seit der Zeile
/// "Projekte" liegt die Backup-Zeile im Testfenster unter dem Rand).
Future<void> _scrollMoreTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    200,
    scrollable: find
        .descendant(
          of: find.byType(MoreScreen),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await tester.pumpAndSettle();
}

Future<void> _back(WidgetTester tester) async {
  Navigator.of(tester.element(find.byType(Scaffold).last)).pop();
  await tester.pumpAndSettle();
}

/// Dienste mit einem Weg (eine offene Etappe), einem Buch in Arbeit (eine
/// Passage) und einem Eintrag von gestern.
Future<TestServices> _seeded({QuoteLibrary? quotes}) async {
  final yesterday = DateTime.now().subtract(const Duration(days: 1));
  final services = TestServices(
    seed: [testEntry(id: 'a', day: yesterday, transcript: 'Gestern.')],
    quoteLibrary: quotes,
  );
  await services.services.goalsUseCase().createGoal(
    title: 'Lesen',
    milestoneTitles: ['Kapitel 1'],
  );
  final book = await services.services.booksUseCase().addBook(
    title: 'Der Sommer der Bücher',
  );
  await services.services.booksUseCase().addPassage(book.id, text: 'Eins.');
  return services;
}

/// Reiter "Mehr": Wege, Lesebuch, Zitate, Woche, Backup als Zeilen mit
/// Zustand; "Heute" bleibt beim Sprechen.
void main() {
  late QuoteLibrary library;
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    library = await QuoteLibrary.load();
  });

  testWidgets('Vier Reiter; "Heute" ohne Wege, Lesebuch und Backup', (
    tester,
  ) async {
    final services = await _seeded();
    await tester.pumpWidget(buildTestApp(services: services));
    await tester.pumpAndSettle();

    final destinations = find.descendant(
      of: find.byType(NavigationBar),
      matching: find.byType(NavigationDestination),
    );
    expect(destinations, findsNWidgets(4));
    for (final label in ['Heute', 'Kalender', 'Mehr', 'Einstellungen']) {
      expect(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text(label),
        ),
        findsOneWidget,
      );
    }

    // "Heute" zeigt weder Wege noch Lesebuch noch die Backup-Zeile; der
    // eigene Abschnitt des Tages ist erreichbar.
    expect(find.byType(TodayScreen), findsOneWidget);
    expect(find.byKey(moreGoalsRowKey), findsNothing);
    expect(find.textContaining('Lesen'), findsNothing);
    expect(find.textContaining('Der Sommer der Bücher'), findsNothing);
    await scrollTodayTo(tester, find.text('Heute noch nichts aufgenommen.'));
    expect(find.byKey(moreBackupRowKey), findsNothing);
    expect(find.byKey(backupReminderCardKey), findsNothing);
  });

  testWidgets('Zeilen mit Zustand; Tipps öffnen die Bildschirme', (
    tester,
  ) async {
    final services = await _seeded(quotes: library);
    await tester.pumpWidget(buildTestApp(services: services));
    await tester.pumpAndSettle();
    await openMoreTab(tester);
    expect(find.byType(MoreScreen), findsOneWidget);
    expect(find.byType(TodayScreen), findsNothing);

    expect(find.text('Wege'), findsOneWidget);
    expect(
      find.text('1 aktiver Weg · Nächste Etappe: Kapitel 1'),
      findsOneWidget,
    );
    expect(find.text('Lesebuch'), findsOneWidget);
    expect(
      find.text('Lese ich: Der Sommer der Bücher · 1 Passage'),
      findsOneWidget,
    );
    final now = DateTime.now();
    final quote = library.forDay(
      DateTime(now.year, now.month, now.day),
      slot: now.hour < 16 ? QuoteLibrary.slotMorning : QuoteLibrary.slotEvening,
    )!;
    expect(find.text('Zitate'), findsOneWidget);
    expect(find.text('„${quote.de}“ · ${quote.author}'), findsOneWidget);
    expect(find.text('Woche'), findsOneWidget);
    expect(find.text('Die letzten sieben Tage im Rückblick'), findsOneWidget);

    await tester.tap(find.byKey(moreGoalsRowKey));
    await tester.pumpAndSettle();
    expect(find.byType(GoalsScreen), findsOneWidget);
    expect(find.text('0 von 1 Etappen'), findsOneWidget);
    await _back(tester);
    expect(find.byType(MoreScreen), findsOneWidget);

    await tester.tap(find.byKey(moreBooksRowKey));
    await tester.pumpAndSettle();
    expect(find.byType(BooksScreen), findsOneWidget);
    await _back(tester);

    await tester.tap(find.byKey(moreQuotesRowKey));
    await tester.pumpAndSettle();
    expect(find.byType(QuotesScreen), findsOneWidget);
    await _back(tester);

    await tester.tap(find.byKey(moreWeekRowKey));
    await tester.pumpAndSettle();
    expect(find.byType(WeekReviewScreen), findsOneWidget);
    await _back(tester);

    await _scrollMoreTo(tester, find.byKey(moreBackupRowKey));
    expect(find.text('Backup und Gerätewechsel'), findsOneWidget);
    expect(find.text('Letztes Backup: noch keins'), findsOneWidget);
    // Ein Eintrag: noch keine Erinnerungskarte.
    expect(find.byKey(backupReminderCardKey), findsNothing);
    await tester.tap(find.byKey(moreBackupRowKey));
    await tester.pumpAndSettle();
    expect(find.byType(BackupScreen), findsOneWidget);
    await _back(tester);
    expect(find.byType(MoreScreen), findsOneWidget);

    // Zurück auf "Heute" ohne Zustandsverlust der Reiter.
    await openTodayTab(tester);
    expect(find.byType(TodayScreen), findsOneWidget);
  });

  testWidgets('Ohne Wege, Bücher und Zitate: leise Hinweise, auf Englisch', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestApp(locale: const Locale('en')));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('More'),
      ),
      findsOneWidget,
    );
    await openMoreTab(tester);
    expect(find.text('Paths'), findsOneWidget);
    expect(find.textContaining('Set yourself a path'), findsOneWidget);
    expect(find.text('Reading book'), findsOneWidget);
    expect(find.textContaining('What are you reading?'), findsOneWidget);
    expect(find.text('Quotes'), findsOneWidget);
    expect(
      find.text('Quote collection, themes and your own quotes'),
      findsOneWidget,
    );
    expect(find.text('Week'), findsOneWidget);
    await _scrollMoreTo(tester, find.byKey(moreBackupRowKey));
    expect(find.text('Backup and device transfer'), findsOneWidget);
    expect(find.text('Last backup: none yet'), findsOneWidget);
    expect(find.byKey(backupReminderCardKey), findsNothing);
  });

  testWidgets('Backup-Zeile mit Datum und Hinweis ab einer Woche', (
    tester,
  ) async {
    final stale = await _seeded();
    await stale.settings.set(
      AppSettings.keyLastBackupAt,
      DateTime.now().subtract(const Duration(days: 9)).toIso8601String(),
    );
    await tester.pumpWidget(buildTestApp(services: stale));
    await tester.pumpAndSettle();
    await openMoreTab(tester);
    await _scrollMoreTo(tester, find.byKey(moreBackupRowKey));
    expect(find.textContaining('Letztes Backup: '), findsOneWidget);
    expect(find.textContaining('· älter als eine Woche'), findsOneWidget);
  });
}
