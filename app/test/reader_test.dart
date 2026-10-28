import 'package:diary_core/diary_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tagebuch_app/data/settings_notifier.dart';
import 'package:tagebuch_app/features/daten/backup_screen.dart';
import 'package:tagebuch_app/features/lesebuch/book_detail_screen.dart';
import 'package:tagebuch_app/features/lesebuch/books_screen.dart';
import 'package:tagebuch_app/features/lesebuch/passage_editor_sheet.dart';
import 'package:tagebuch_app/features/mehr/more_screen.dart';
import 'package:tagebuch_app/features/reader/epub_import.dart';
import 'package:tagebuch_app/features/reader/reader_screen.dart';
import 'package:tagebuch_app/features/reader/reader_sheets.dart';
import 'package:tagebuch_app/features/reader/reader_theme.dart';

import 'epub_fixture.dart';
import 'test_app.dart';

/// Lädt das Test-EPUB über das Lesebuch und landet in den Buchdetails.
Future<Book> _loadEpub(
  WidgetTester tester,
  TestServices services,
  FakePlatformFeatures features,
) async {
  await openMoreTab(tester);
  await tester.tap(find.byKey(moreBooksRowKey));
  await tester.pumpAndSettle();
  features.epubToPick = buildTestEpub();
  await tester.tap(find.byKey(booksLoadEpubKey));
  await tester.pumpAndSettle();
  final book = services.books.books.single;
  return book;
}

/// Ob irgendein Textabschnitt im Reader hinterlegt ist.
bool _hasHighlight(WidgetTester tester) {
  var found = false;
  for (final text in tester.widgetList<Text>(
    find.descendant(of: find.byType(ReaderScreen), matching: find.byType(Text)),
  )) {
    text.textSpan?.visitChildren((span) {
      if (span.style?.backgroundColor != null) found = true;
      return !found;
    });
  }
  return found;
}

void main() {
  group('E-Reader (D25)', () {
    testWidgets(
      'EPUB laden: Buch mit Titel und Autor, Datei verschlüsselt im Store',
      (tester) async {
        final features = FakePlatformFeatures();
        final services = TestServices(features: features);
        await tester.pumpWidget(buildTestApp(services: services));
        await tester.pumpAndSettle();

        final book = await _loadEpub(tester, services, features);
        expect(book.title, 'Der Sommer der Bücher');
        expect(book.author, 'Anna Beispiel');
        expect(book.status, BookStatus.reading);
        expect(book.hasFile, isTrue);
        expect(book.format, BookFormat.epub);
        expect(book.fileName, 'book-${book.id}.epub.tgbc');
        expect(book.fileSizeBytes, greaterThan(0));
        expect(book.fileKeyWrapped, isNotEmpty);
        // Die Datei liegt im Dateispeicher (im Browser als Chunk-AEAD-Datei),
        // nicht als Klartext irgendwo sonst.
        expect(services.bookFiles.files.keys, [book.fileName]);
        expect(
          await services.bookFiles.read(book.fileName!, book.fileKeyWrapped!),
          features.epubToPick,
        );
        // Nach dem Laden stehen die Buchdetails mit "Lesen".
        expect(find.byType(BookDetailScreen), findsOneWidget);
        expect(find.text('Lesen'), findsOneWidget);
        expect(find.textContaining('EPUB ·'), findsOneWidget);
      },
    );

    testWidgets(
      'Reader: Kapitel 1, Inhaltsverzeichnis springt, Darstellung ändert '
      'Einstellungen, Wischen speichert die Leseposition',
      (tester) async {
        final features = FakePlatformFeatures();
        final services = TestServices(features: features);
        await tester.pumpWidget(buildTestApp(services: services));
        await tester.pumpAndSettle();
        final book = await _loadEpub(tester, services, features);

        await tester.tap(find.byKey(bookReadKey));
        await tester.pumpAndSettle();
        expect(find.byType(ReaderScreen), findsOneWidget);
        expect(find.text('Der Anfang'), findsOneWidget);
        expect(
          find.text('Ein leiser Anfang und ein lauter Schluss.'),
          findsOneWidget,
        );
        expect(find.text('Kapitel 1 von 2'), findsOneWidget);
        expect(find.byKey(readerBarKey), findsOneWidget);

        // Inhaltsverzeichnis: Kapitel 2 wählen.
        await tester.tap(find.byKey(readerContentsKey));
        await tester.pumpAndSettle();
        expect(find.text('Das Ende'), findsOneWidget);
        await tester.tap(find.byKey(readerTocItemKey(1)));
        await tester.pumpAndSettle();
        expect(find.text('Kapitel 2 von 2'), findsOneWidget);
        expect(find.text('Der letzte Satz des Buches.'), findsOneWidget);

        // Darstellung: Schrift größer, Zeilen weiter, Sepia.
        await tester.tap(find.byKey(readerDisplayKey));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(readerFontLargerKey));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(readerLineLooserKey));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(readerThemeKey(ReaderTheme.sepia)));
        await tester.pumpAndSettle();
        expect(
          await services.settings.get(AppSettings.keyReaderFontScale),
          '1.1',
        );
        expect(
          await services.settings.get(AppSettings.keyReaderLineHeight),
          '1.6',
        );
        expect(
          await services.settings.get(AppSettings.keyReaderTheme),
          'sepia',
        );
        Navigator.of(tester.element(find.byKey(readerFontLargerKey))).pop();
        await tester.pumpAndSettle();
        expect(
          tester.widget<Scaffold>(find.byType(Scaffold).last).backgroundColor,
          ReaderPalette.sepiaPalette.background,
        );

        // Zurück zu Kapitel 1 durch Wischen, Position wird entprellt gemerkt.
        await tester.fling(find.byType(PageView), const Offset(400, 0), 1000);
        await tester.pumpAndSettle();
        expect(find.text('Kapitel 1 von 2'), findsOneWidget);
        await tester.pump(
          ReaderScreen.saveDelay + const Duration(milliseconds: 50),
        );
        var saved = (await services.books.bookById(book.id))!.readingPosition;
        expect(saved?.chapterIndex, 0);

        await tester.fling(find.byType(PageView), const Offset(-400, 0), 1000);
        await tester.pumpAndSettle();
        await tester.pump(
          ReaderScreen.saveDelay + const Duration(milliseconds: 50),
        );
        saved = (await services.books.bookById(book.id))!.readingPosition;
        expect(saved?.chapterIndex, 1);
        expect(saved!.progress, greaterThan(0));

        // "Weiterlesen" im Buchdetail und auf "Mehr".
        await tester.tap(find.byKey(readerBackKey));
        await tester.pumpAndSettle();
        expect(find.byType(BookDetailScreen), findsOneWidget);
        expect(find.text('Weiterlesen'), findsOneWidget);
        expect(find.textContaining('Kap. 2'), findsOneWidget);
        Navigator.of(tester.element(find.byType(BookDetailScreen))).pop();
        await tester.pumpAndSettle();
        Navigator.of(tester.element(find.byType(BooksScreen))).pop();
        await tester.pumpAndSettle();
        expect(
          find.text('Weiterlesen: Der Sommer der Bücher, Kap. 2'),
          findsOneWidget,
        );
      },
    );

    testWidgets('Markierung wird Passage mit Anker und erscheint hinterlegt; '
        'Als Zitat merken; Tipp auf die Markierung zeigt die Passage', (
      tester,
    ) async {
      final features = FakePlatformFeatures();
      final services = TestServices(features: features);
      await tester.pumpWidget(buildTestApp(services: services));
      await tester.pumpAndSettle();
      final book = await _loadEpub(tester, services, features);
      await tester.tap(find.byKey(bookReadKey));
      await tester.pumpAndSettle();
      expect(_hasHighlight(tester), isFalse);

      // Langes Drücken auf das erste Wort des Absatzes wählt es aus und
      // zeigt die eigene Werkzeugleiste.
      final paragraph = find.text('Ein leiser Anfang und ein lauter Schluss.');
      await tester.longPressAt(
        tester.getTopLeft(paragraph) + const Offset(6, 8),
      );
      await tester.pumpAndSettle();
      expect(find.text('Passage festhalten'), findsOneWidget);
      expect(find.text('Als Zitat merken'), findsOneWidget);

      await tester.tap(find.text('Passage festhalten'));
      await tester.pumpAndSettle();
      final textField = tester.widget<TextField>(
        find.byKey(passageTextFieldKey),
      );
      expect(textField.controller!.text, startsWith('Ein'));
      expect(
        tester
            .widget<TextField>(find.byKey(passagePageFieldKey))
            .controller!
            .text,
        'Kap. 1',
      );
      await tester.enterText(find.byKey(passageThoughtFieldKey), 'Gedanke.');
      await tester.tap(find.byKey(passageSaveKey));
      await tester.pumpAndSettle();

      final passage = services.books.passages.single;
      expect(passage.bookId, book.id);
      expect(passage.text, startsWith('Ein'));
      expect(passage.page, 'Kap. 1');
      expect(passage.thought, 'Gedanke.');
      final anchor = passage.anchor!;
      expect(anchor.chapterIndex, 0);
      expect(anchor.blockIndex, 1);
      expect(anchor.start, 0);
      expect(anchor.end, greaterThanOrEqualTo(3));
      expect(anchor.excerpt, startsWith('Ein'));
      // Die Stelle ist jetzt hinterlegt.
      expect(_hasHighlight(tester), isTrue);

      // Tipp auf die Markierung zeigt die Passage; löschen entfernt sie.
      await tester.tapAt(tester.getTopLeft(paragraph) + const Offset(6, 8));
      await tester.pumpAndSettle();
      expect(find.text('Markierte Passage'), findsOneWidget);
      expect(find.text('Gedanke.'), findsOneWidget);
      await tester.tap(find.byKey(readerPassageDeleteKey));
      await tester.pumpAndSettle();
      expect(services.books.passages, isEmpty);
      expect(_hasHighlight(tester), isFalse);

      // "Als Zitat merken" aus der Markierung.
      await tester.longPressAt(
        tester.getTopLeft(paragraph) + const Offset(6, 8),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Als Zitat merken'));
      await tester.pumpAndSettle();
      final settings = await AppSettings.load(services.settings);
      expect(settings.ownQuotes, hasLength(1));
      expect(settings.ownQuotes.single.de, startsWith('Ein'));
      expect(settings.ownQuotes.single.author, 'Anna Beispiel');
      expect(find.textContaining('Als Zitat gemerkt'), findsOneWidget);
    });

    testWidgets('Buch löschen löscht die Datei; DRM wird abgelehnt', (
      tester,
    ) async {
      final features = FakePlatformFeatures();
      final services = TestServices(features: features);
      await tester.pumpWidget(buildTestApp(services: services));
      await tester.pumpAndSettle();
      final book = await _loadEpub(tester, services, features);
      expect(services.bookFiles.files, hasLength(1));

      await tester.tap(find.byKey(bookMenuKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(bookDeleteKey));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Löschen'));
      await tester.pumpAndSettle();
      expect(services.books.books, isEmpty);
      expect(services.bookFiles.files, isEmpty);
      expect(await services.books.bookById(book.id), isNull);
      expect(find.byType(BooksScreen), findsOneWidget);

      // Kopiergeschützt: freundliche Meldung, nichts gespeichert.
      features.epubToPick = buildTestEpub(drm: true);
      await tester.tap(find.byKey(booksLoadEpubKey));
      await tester.pumpAndSettle();
      expect(find.textContaining('kopiergeschützt'), findsOneWidget);
      expect(services.books.books, isEmpty);
      expect(services.bookFiles.files, isEmpty);

      // Kein EPUB: ebenso.
      features.epubToPick = Uint8ListOf(300, 5);
      await tester.tap(find.byKey(booksLoadEpubKey));
      await tester.pumpAndSettle();
      expect(find.textContaining('kein lesbares EPUB'), findsOneWidget);
      expect(services.books.books, isEmpty);
    });

    testWidgets(
      'Ähnlicher Titel: Datei an vorhandenes Buch anhängen; Backup nennt '
      'die Größe der Buchdateien',
      (tester) async {
        final features = FakePlatformFeatures();
        final services = TestServices(features: features);
        await services.books.insertBook(
          Book(
            id: 'b-alt',
            journalId: testJournalId,
            title: 'Sommer der Bücher',
            author: 'A. Beispiel',
            status: BookStatus.planned,
            createdAt: DateTime(2026, 10, 20),
            updatedAt: DateTime(2026, 10, 20),
          ),
        );
        await tester.pumpWidget(buildTestApp(services: services));
        await tester.pumpAndSettle();
        await openMoreTab(tester);
        await tester.tap(find.byKey(moreBooksRowKey));
        await tester.pumpAndSettle();
        features.epubToPick = buildTestEpub();
        await tester.tap(find.byKey(booksLoadEpubKey));
        await tester.pumpAndSettle();
        expect(find.text('Zu einem Buch, das es schon gibt?'), findsOneWidget);
        await tester.tap(find.byKey(epubAttachExistingKey));
        await tester.pumpAndSettle();

        final book = services.books.books.single;
        expect(book.id, 'b-alt');
        expect(book.title, 'Sommer der Bücher');
        expect(book.hasFile, isTrue);
        expect(services.bookFiles.files.keys, ['book-b-alt.epub.tgbc']);
        expect(find.text('Datei angehängt.'), findsOneWidget);
        expect(find.byType(BookDetailScreen), findsOneWidget);

        // Backup-Bildschirm nennt die Buchdatei.
        Navigator.of(tester.element(find.byType(BookDetailScreen))).pop();
        await tester.pumpAndSettle();
        Navigator.of(tester.element(find.byType(BooksScreen))).pop();
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byKey(moreBackupRowKey));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(moreBackupRowKey));
        await tester.pumpAndSettle();
        expect(find.byType(BackupScreen), findsOneWidget);
        expect(find.byKey(backupBookFilesKey), findsOneWidget);
        expect(find.textContaining('Enthält eine Buchdatei'), findsOneWidget);
      },
    );
  });
}
