import 'package:diary_core/diary_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tagebuch_app/data/settings_notifier.dart';
import 'package:tagebuch_app/features/eintrag/entry_screen.dart';
import 'package:tagebuch_app/features/kalender/calendar_screen.dart';
import 'package:tagebuch_app/features/lesebuch/book_detail_screen.dart';
import 'package:tagebuch_app/features/lesebuch/book_editor_sheet.dart';
import 'package:tagebuch_app/features/lesebuch/book_search_tile.dart';
import 'package:tagebuch_app/features/lesebuch/books_screen.dart';
import 'package:tagebuch_app/features/lesebuch/day_passages_section.dart';
import 'package:tagebuch_app/features/lesebuch/passage_editor_sheet.dart';
import 'package:tagebuch_app/features/mehr/more_screen.dart';

import 'test_app.dart';

DateTime _today() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

Book _book(
  String id,
  String title, {
  String? author,
  BookStatus status = BookStatus.reading,
  DateTime? at,
}) {
  final t = at ?? DateTime(2026, 10, 20, 21);
  return Book(
    id: id,
    journalId: testJournalId,
    title: title,
    author: author,
    status: status,
    createdAt: t,
    updatedAt: t,
    finishedAt: status == BookStatus.finished ? t : null,
  );
}

Passage _passage(
  String id,
  String bookId,
  String text, {
  String? page,
  String? thought,
  DateTime? at,
}) {
  final t = at ?? DateTime(2026, 10, 20, 21);
  return Passage(
    id: id,
    bookId: bookId,
    createdAt: t,
    updatedAt: t,
    text: text,
    page: page,
    thought: thought,
    day: LocalDay.forMoment(t),
  );
}

/// Verlässt die oberste Route (die AppBar der App hat keinen Standard-Zurück-
/// Knopf, den `pageBack` finden könnte).
Future<void> _back(WidgetTester tester) async {
  Navigator.of(tester.element(find.byType(Scaffold).last)).pop();
  await tester.pumpAndSettle();
}

void main() {
  group('Lesebuch (D21)', () {
    testWidgets('Buch anlegen, Passage festhalten, Status wechseln', (
      tester,
    ) async {
      final services = TestServices();
      await tester.pumpWidget(buildTestApp(services: services));
      await tester.pumpAndSettle();

      // "Mehr": ohne Bücher nur die leise Frage in der Zeile "Lesebuch".
      await openMoreTab(tester);
      expect(find.textContaining('Was liest du gerade?'), findsOneWidget);
      expect(find.textContaining('Lese ich:'), findsNothing);
      await tester.tap(find.byKey(moreBooksRowKey));
      await tester.pumpAndSettle();
      expect(find.byType(BooksScreen), findsOneWidget);
      expect(find.textContaining('Noch kein Buch'), findsOneWidget);

      await tester.tap(find.byKey(booksEmptyNewKey));
      await tester.pumpAndSettle();
      // Ohne Titel geht nichts.
      await tester.tap(find.byKey(bookSaveKey));
      await tester.pumpAndSettle();
      expect(find.text('Gib dem Buch einen Titel.'), findsOneWidget);
      expect(services.books.books, isEmpty);

      await tester.enterText(
        find.byKey(bookTitleFieldKey),
        'Der Sommer der Bücher',
      );
      await tester.enterText(find.byKey(bookAuthorFieldKey), 'Anna Beispiel');
      await tester.tap(find.byKey(bookSaveKey));
      await tester.pumpAndSettle();

      final book = services.books.books.single;
      expect(book.title, 'Der Sommer der Bücher');
      expect(book.author, 'Anna Beispiel');
      expect(book.status, BookStatus.reading);
      expect(find.byKey(booksSectionKey(BookStatus.reading)), findsOneWidget);
      expect(find.byKey(booksSectionKey(BookStatus.planned)), findsNothing);
      expect(find.byKey(bookCardKey(book.id)), findsOneWidget);
      expect(find.text('Noch keine Passage'), findsOneWidget);

      // Details: Passage festhalten.
      await tester.tap(find.byKey(bookCardKey(book.id)));
      await tester.pumpAndSettle();
      expect(find.byType(BookDetailScreen), findsOneWidget);
      expect(find.text('Anna Beispiel'), findsOneWidget);
      await tester.tap(find.byKey(bookAddPassageKey));
      await tester.pumpAndSettle();
      // Der Hinweis nennt die Mikrofontaste der Tastatur.
      expect(find.textContaining('Mikrofontaste'), findsOneWidget);
      await tester.tap(find.byKey(passageSaveKey));
      await tester.pumpAndSettle();
      expect(find.text('Ohne Text keine Passage.'), findsOneWidget);
      await tester.enterText(
        find.byKey(passageTextFieldKey),
        'Ein Satz, der bleibt.',
      );
      await tester.enterText(find.byKey(passagePageFieldKey), 'S. 42');
      await tester.enterText(
        find.byKey(passageThoughtFieldKey),
        'Erinnert mich an den Sommer.',
      );
      await tester.tap(find.byKey(passageSaveKey));
      await tester.pumpAndSettle();

      final passage = services.books.passages.single;
      expect(passage.bookId, book.id);
      expect(passage.text, 'Ein Satz, der bleibt.');
      expect(passage.page, 'S. 42');
      expect(passage.thought, 'Erinnert mich an den Sommer.');
      expect(passage.day, LocalDay.forMoment(DateTime.now()));
      expect(find.byKey(passageCardKey(passage.id)), findsOneWidget);
      expect(find.text('Ein Satz, der bleibt.'), findsOneWidget);
      expect(find.textContaining('Seite: S. 42'), findsOneWidget);
      expect(find.text('Erinnert mich an den Sommer.'), findsOneWidget);
      expect(find.text('1 Passage'), findsOneWidget);

      // Passage bearbeiten.
      await tester.tap(find.byKey(passageEditKey(passage.id)));
      await tester.pumpAndSettle();
      expect(find.text('Passage bearbeiten'), findsOneWidget);
      await tester.enterText(
        find.byKey(passageTextFieldKey),
        'Ein Satz, der bleibt und trägt.',
      );
      await tester.tap(find.byKey(passageSaveKey));
      await tester.pumpAndSettle();
      expect(
        (await services.books.passageById(passage.id))!.text,
        'Ein Satz, der bleibt und trägt.',
      );

      // Status "Gelesen" setzt das Datum; zurück entfernt es.
      await tester.tap(find.byKey(bookDetailStatusKey(BookStatus.finished)));
      await tester.pumpAndSettle();
      final finished = (await services.books.bookById(book.id))!;
      expect(finished.status, BookStatus.finished);
      expect(finished.finishedAt, isNotNull);
      expect(find.textContaining('Gelesen am'), findsOneWidget);
      await tester.tap(find.byKey(bookDetailStatusKey(BookStatus.planned)));
      await tester.pumpAndSettle();
      final planned = (await services.books.bookById(book.id))!;
      expect(planned.status, BookStatus.planned);
      expect(planned.finishedAt, isNull);
      expect(find.textContaining('Gelesen am'), findsNothing);

      // Passage löschen ohne Rückfrage.
      await tester.tap(find.byKey(passageDeleteKey(passage.id)));
      await tester.pumpAndSettle();
      expect(services.books.passages, isEmpty);
      expect(find.textContaining('Noch keine Passage festgehalten'), findsOne);

      // Zurück zur Liste: das Buch steht jetzt unter "Vorgemerkt".
      await _back(tester);
      expect(find.byKey(booksSectionKey(BookStatus.planned)), findsOneWidget);
      expect(find.byKey(booksSectionKey(BookStatus.reading)), findsNothing);
    });

    testWidgets('Buch bearbeiten und löschen mit Rückfrage', (tester) async {
      final services = TestServices();
      await services.books.insertBook(_book('b', 'Alt', author: 'A.'));
      await services.books.insertPassage(_passage('p', 'b', 'Stelle.'));
      await tester.pumpWidget(
        buildTestScreen(
          const BookDetailScreen(bookId: 'b'),
          services: services,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(bookMenuKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(bookEditKey));
      await tester.pumpAndSettle();
      expect(find.text('Buch bearbeiten'), findsOneWidget);
      // Beim Bearbeiten gibt es keinen Status-Wähler im Blatt.
      expect(
        find.byKey(bookStatusSegmentKey(BookStatus.reading)),
        findsNothing,
      );
      await tester.enterText(find.byKey(bookTitleFieldKey), 'Neu');
      await tester.enterText(find.byKey(bookAuthorFieldKey), '');
      await tester.tap(find.byKey(bookSaveKey));
      await tester.pumpAndSettle();
      final edited = (await services.books.bookById('b'))!;
      expect(edited.title, 'Neu');
      expect(edited.author, isNull);
      expect(find.text('Neu'), findsOneWidget);

      // Löschen: "Behalten" lässt alles stehen, "Löschen" entfernt Buch und
      // Passagen.
      await tester.tap(find.byKey(bookMenuKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(bookDeleteKey));
      await tester.pumpAndSettle();
      expect(find.text('Buch löschen?'), findsOneWidget);
      await tester.tap(find.text('Behalten'));
      await tester.pumpAndSettle();
      expect(services.books.books, hasLength(1));
      await tester.tap(find.byKey(bookMenuKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(bookDeleteKey));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Löschen'));
      await tester.pumpAndSettle();
      expect(services.books.books, isEmpty);
      expect(services.books.passages, isEmpty);
    });

    testWidgets('"Als Zitat merken" legt ein eigenes Zitat an, nur einmal', (
      tester,
    ) async {
      final services = TestServices();
      await services.books.insertBook(
        _book('b', 'Der Sommer der Bücher', author: 'Anna Beispiel'),
      );
      await services.books.insertBook(_book('o', 'Ohne Autor'));
      await services.books.insertPassage(
        _passage('p', 'b', 'Ein Satz, der bleibt.'),
      );
      await services.books.insertPassage(_passage('q', 'o', 'Zweiter Satz.'));
      await tester.pumpWidget(
        buildTestScreen(
          const BookDetailScreen(bookId: 'b'),
          services: services,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(passageQuoteKey('p')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Als Zitat gemerkt.'), findsOneWidget);
      final stored = await services.settings.get(AppSettings.keyOwnQuotes);
      expect(stored, contains('"passage-p"'));
      expect(stored, contains('Anna Beispiel'));
      expect(stored, contains('Ein Satz, der bleibt.'));

      // Noch einmal: kein zweites Zitat.
      await tester.tap(find.byKey(passageQuoteKey('p')));
      await tester.pump();
      await tester.pumpAndSettle();
      expect(find.textContaining('schon als Zitat gemerkt'), findsOneWidget);
      final decoded = await services.settings.get(AppSettings.keyOwnQuotes);
      expect('passage-p'.allMatches(decoded!), hasLength(1));

      // Ohne Autor steht der Titel als Urheber.
      await tester.pumpWidget(
        buildTestScreen(
          const BookDetailScreen(bookId: 'o'),
          services: services,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(passageQuoteKey('q')));
      await tester.pumpAndSettle();
      final again = await services.settings.get(AppSettings.keyOwnQuotes);
      expect(again, contains('"passage-q"'));
      expect(again, contains('"author":"Ohne Autor"'));
    });

    testWidgets('Eintrag zeigt "Heute gelesen", Tipp öffnet das Buch', (
      tester,
    ) async {
      final day = DateTime(2026, 10, 20);
      final services = TestServices(
        seed: [testEntry(id: 'e', day: day, transcript: 'Gesprochen.')],
      );
      await services.books.insertBook(_book('b', 'Der Sommer der Bücher'));
      await services.books.insertPassage(
        _passage(
          'p',
          'b',
          'Ein Satz, der bleibt.',
          page: 'S. 42',
          at: day.add(const Duration(hours: 22)),
        ),
      );
      // Eine Passage eines anderen Tags erscheint nicht.
      await services.books.insertPassage(
        _passage(
          'x',
          'b',
          'Anderer Tag.',
          at: day.add(const Duration(days: 1, hours: 22)),
        ),
      );
      await tester.pumpWidget(
        buildTestScreen(const EntryScreen(entryId: 'e'), services: services),
      );
      await tester.pumpAndSettle();
      // Der Abschnitt steht unter Aufnahme und Transkript; die Liste baut nur
      // den sichtbaren Teil.
      await tester.scrollUntilVisible(
        find.byKey(entryPassagesSectionKey),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('Heute gelesen'), findsOneWidget);
      expect(find.byKey(entryPassageKey('p')), findsOneWidget);
      expect(find.byKey(entryPassageKey('x')), findsNothing);
      expect(find.textContaining('Der Sommer der Bücher'), findsOneWidget);
      expect(find.textContaining('Seite: S. 42'), findsOneWidget);
      expect(find.text('Ein Satz, der bleibt.'), findsOneWidget);
      await tester.tap(find.byKey(entryPassageKey('p')));
      await tester.pumpAndSettle();
      expect(find.byType(BookDetailScreen), findsOneWidget);
    });

    testWidgets('Eintrag ohne Passagen zeigt keinen Abschnitt', (tester) async {
      final services = TestServices(
        seed: [testEntry(id: 'e', day: DateTime(2026, 10, 20))],
      );
      await tester.pumpWidget(
        buildTestScreen(const EntryScreen(entryId: 'e'), services: services),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(entryPassagesSectionKey), findsNothing);
      expect(find.text('Heute gelesen'), findsNothing);
    });

    testWidgets('Suche findet Passage und Gedanke, Treffer öffnet das Buch', (
      tester,
    ) async {
      final services = TestServices(
        seed: [
          testEntry(
            id: 'e',
            day: DateTime(2026, 9, 6),
            transcript: 'Kaffee im Park',
          ),
        ],
      );
      await services.books.insertBook(
        _book('b', 'Der Sommer der Bücher', author: 'Anna Beispiel'),
      );
      await services.books.insertPassage(
        _passage(
          'p',
          'b',
          'Die Straße lag still.',
          thought: 'Großmutters Garten.',
          at: DateTime(2026, 9, 10, 21),
        ),
      );
      await tester.pumpWidget(
        buildTestScreen(
          CalendarScreen(initialMonth: DateTime(2026, 9)),
          services: services,
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(searchFieldKey), 'strasse');
      await tester.pumpAndSettle();
      expect(find.byKey(bookSearchTileKey('b')), findsOneWidget);
      expect(find.text('Passage in „Der Sommer der Bücher“'), findsOneWidget);
      expect(find.byKey(const ValueKey('entry-tile-e')), findsNothing);

      // Der Gedanke zählt mit; Einträge und Bücher stehen zusammen.
      await tester.enterText(find.byKey(searchFieldKey), 'garten kaffee');
      await tester.pumpAndSettle();
      expect(find.text('Nichts gefunden.'), findsOneWidget);
      await tester.enterText(find.byKey(searchFieldKey), 'a');
      await tester.pumpAndSettle();
      expect(find.byKey(bookSearchTileKey('b')), findsOneWidget);
      expect(find.byKey(const ValueKey('entry-tile-e')), findsOneWidget);

      await tester.enterText(find.byKey(searchFieldKey), 'grossmutter');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(bookSearchTileKey('b')));
      await tester.pumpAndSettle();
      expect(find.byType(BookDetailScreen), findsOneWidget);
      expect(find.text('Die Straße lag still.'), findsOneWidget);
    });

    testWidgets('"Heute" zeigt die Zeile "Lese ich" mit Passagenzahl', (
      tester,
    ) async {
      final services = TestServices();
      final today = _today();
      // Das zuletzt geänderte Buch mit Status "Lese ich" gewinnt; vorgemerkte
      // und gelesene zählen nicht.
      await services.books.insertBook(
        _book(
          'alt',
          'Älteres Buch',
          at: today.subtract(const Duration(days: 3)),
        ),
      );
      await services.books.insertBook(
        _book('neu', 'Der Sommer der Bücher', at: today),
      );
      await services.books.insertBook(
        _book(
          'plan',
          'Vorgemerktes',
          status: BookStatus.planned,
          at: today.add(const Duration(hours: 1)),
        ),
      );
      await services.books.insertPassage(_passage('p1', 'neu', 'Eins.'));
      await services.books.insertPassage(_passage('p2', 'neu', 'Zwei.'));
      await tester.pumpWidget(buildTestApp(services: services));
      await tester.pumpAndSettle();

      await openMoreTab(tester);
      expect(
        find.text('Lese ich: Der Sommer der Bücher · 2 Passagen'),
        findsOneWidget,
      );
      expect(find.textContaining('Was liest du gerade?'), findsNothing);
      await tester.tap(find.byKey(moreBooksRowKey));
      await tester.pumpAndSettle();
      expect(find.byType(BooksScreen), findsOneWidget);
      await tester.tap(find.byKey(bookCardKey('neu')));
      await tester.pumpAndSettle();
      expect(find.byType(BookDetailScreen), findsOneWidget);
      expect(find.text('Der Sommer der Bücher'), findsOneWidget);
    });

    testWidgets('Lesebuch auf Englisch', (tester) async {
      final services = TestServices();
      await services.books.insertBook(
        _book('b', 'A Summer of Books', status: BookStatus.finished),
      );
      await tester.pumpWidget(
        buildTestScreen(
          const BooksScreen(),
          services: services,
          locale: const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Reading book'), findsOneWidget);
      expect(find.byKey(booksSectionKey(BookStatus.finished)), findsOneWidget);
      expect(find.text('Finished'), findsOneWidget);
      expect(find.textContaining('No passages yet'), findsOneWidget);
    });
  });
}
