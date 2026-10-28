import 'dart:convert';
import 'dart:typed_data';

import 'package:diary_core/diary_core.dart';
import 'package:test/test.dart';

import 'transfer_support.dart';

void main() {
  final t0 = DateTime(2026, 10, 27, 21);

  test('Book und Passage: JSON-Round-Trip, ältere Datensätze tolerant', () {
    final b = Book(
      id: 'b1',
      journalId: 'j',
      title: 'Der Sommer der Bücher',
      author: 'Anna Beispiel',
      status: BookStatus.reading,
      createdAt: t0,
      updatedAt: t0,
    );
    final back = ModelJson.decodeBook(
      jsonDecode(jsonEncode(ModelJson.encodeBook(b))) as Map<String, Object?>,
    );
    expect(back.id, 'b1');
    expect(back.title, b.title);
    expect(back.author, 'Anna Beispiel');
    expect(back.status, BookStatus.reading);
    expect(back.finishedAt, isNull);
    expect(back.attribution, 'Anna Beispiel');
    expect(b.copyWith(clearAuthor: true).attribution, 'Der Sommer der Bücher');

    final finished = b.copyWith(
      status: BookStatus.finished,
      finishedAt: t0.add(const Duration(days: 3)),
    );
    final finishedBack = ModelJson.decodeBook(ModelJson.encodeBook(finished));
    expect(finishedBack.status, BookStatus.finished);
    expect(finishedBack.finishedAt, finished.finishedAt);
    expect(finished.copyWith(clearFinished: true).finishedAt, isNull);

    final p = Passage(
      id: 'p1',
      bookId: 'b1',
      createdAt: t0,
      updatedAt: t0,
      text: 'Ein Satz, der bleibt.',
      page: 'S. 42',
      thought: 'Erinnert mich an den Sommer.',
      day: const LocalDay(2026, 10, 27),
    );
    final pBack = ModelJson.decodePassage(
      jsonDecode(jsonEncode(ModelJson.encodePassage(p)))
          as Map<String, Object?>,
    );
    expect(pBack.text, p.text);
    expect(pBack.page, 'S. 42');
    expect(pBack.thought, p.thought);
    expect(pBack.day, const LocalDay(2026, 10, 27));
    expect(p.copyWith(clearPage: true, clearThought: true).page, isNull);
    expect(p.copyWith(clearPage: true, clearThought: true).thought, isNull);

    // Minimale Datensätze ohne optionale Felder: Status wird "reading", der
    // Tag kommt aus dem Zeitpunkt.
    final minimal = ModelJson.decodeBook({
      'id': 'b2',
      'journalId': 'j',
      'title': 'x',
      'createdAt': '2026-10-27T19:00:00.000Z',
      'updatedAt': '2026-10-27T19:00:00.000Z',
    });
    expect(minimal.status, BookStatus.reading);
    expect(minimal.author, isNull);
    final minimalPassage = ModelJson.decodePassage({
      'id': 'p2',
      'bookId': 'b2',
      'text': 'x',
      'createdAt': t0.toUtc().toIso8601String(),
      'updatedAt': t0.toUtc().toIso8601String(),
    });
    expect(minimalPassage.day, LocalDay.forMoment(t0));
    expect(minimalPassage.page, isNull);
  });

  test('E-Book-Felder (D25): Codec tolerant, Leseposition, Anker', () {
    final b = Book(
      id: 'b1',
      journalId: 'j',
      title: 'E-Book',
      status: BookStatus.reading,
      createdAt: t0,
      updatedAt: t0,
      format: BookFormat.epub,
      fileName: 'book-b1.epub.tgbc',
      fileKeyWrapped: Uint8List.fromList(List.filled(60, 7)),
      fileSizeBytes: 12345,
      readingPosition: const ReadingPosition(
        chapterIndex: 3,
        blockIndex: 12,
        progress: 0.25,
      ),
    );
    expect(b.hasFile, isTrue);
    final back = ModelJson.decodeBook(
      jsonDecode(jsonEncode(ModelJson.encodeBook(b))) as Map<String, Object?>,
    );
    expect(back.format, BookFormat.epub);
    expect(back.fileName, 'book-b1.epub.tgbc');
    expect(back.fileKeyWrapped, b.fileKeyWrapped);
    expect(back.fileSizeBytes, 12345);
    expect(back.readingPosition, b.readingPosition);
    expect(back.hasFile, isTrue);

    // Ohne Datei: alle Felder null, kein E-Book.
    final plain = b.copyWith(clearFile: true);
    expect(plain.hasFile, isFalse);
    expect(plain.readingPosition, isNull);
    final plainBack = ModelJson.decodeBook(ModelJson.encodeBook(plain));
    expect(plainBack.format, isNull);
    expect(plainBack.fileName, isNull);
    // Unbekanntes Format aus einer neueren Fassung: kein E-Book, kein Fehler.
    final unknown = ModelJson.decodeBook({
      ...ModelJson.encodeBook(b),
      'format': 'pdf',
      'readingPosition': 'kein json',
    });
    expect(unknown.format, isNull);
    expect(unknown.hasFile, isFalse);
    expect(unknown.readingPosition, isNull);

    expect(ReadingPosition.decode(null), isNull);
    expect(
      ReadingPosition.decode('{"chapter":1,"progress":2}'),
      const ReadingPosition(chapterIndex: 1, progress: 1),
    );

    const anchor = PassageAnchor(
      chapterIndex: 1,
      blockIndex: 4,
      start: 10,
      end: 30,
      endBlockIndex: 5,
      excerpt: 'Ein Satz',
    );
    final p = Passage(
      id: 'p1',
      bookId: 'b1',
      createdAt: t0,
      updatedAt: t0,
      text: 'Ein Satz, der bleibt.',
      day: const LocalDay(2026, 10, 27),
      anchor: anchor,
    );
    final pBack = ModelJson.decodePassage(
      jsonDecode(jsonEncode(ModelJson.encodePassage(p)))
          as Map<String, Object?>,
    );
    expect(pBack.anchor, anchor);
    expect(pBack.anchor!.lastBlockIndex, 5);
    expect(
      ModelJson.decodePassage(
        ModelJson.encodePassage(p.copyWith(text: 'x'))..remove('anchor'),
      ).anchor,
      isNull,
    );
    expect(PassageAnchor.decode('[]'), isNull);
    expect(PassageAnchor.decode(anchor.encode()), anchor);
  });

  test('BooksUseCase: anlegen, Status, Passagen, löschen', () async {
    final repo = MemoryBooks();
    final clock = FixedClock(t0);
    final useCase = BooksUseCase(
      journalId: 'j',
      books: repo,
      ids: MemoryIds('b-'),
      clock: clock,
    );
    expect(() => useCase.addBook(title: '   '), throwsArgumentError);
    final book = await useCase.addBook(
      title: '  Der Sommer der Bücher ',
      author: '  ',
    );
    expect(book.title, 'Der Sommer der Bücher');
    expect(book.author, isNull);
    expect(book.status, BookStatus.reading);
    expect(book.finishedAt, isNull);

    final planned = await useCase.addBook(
      title: 'Später',
      status: BookStatus.planned,
    );
    final finished = await useCase.addBook(
      title: 'Fertig',
      status: BookStatus.finished,
    );
    expect(finished.finishedAt, t0);
    expect((await useCase.listByStatus(BookStatus.reading)).single.id, book.id);
    expect(
      (await useCase.listByStatus(BookStatus.planned)).single.id,
      planned.id,
    );

    // Status wechseln: "Gelesen" setzt das Datum, zurück entfernt es.
    clock.setTo(t0.add(const Duration(days: 2)));
    await useCase.setStatus(book.id, BookStatus.finished);
    expect((await repo.bookById(book.id))!.finishedAt, clock.now());
    await useCase.setStatus(book.id, BookStatus.reading);
    expect((await repo.bookById(book.id))!.finishedAt, isNull);
    expect((await repo.bookById(book.id))!.status, BookStatus.reading);

    // Bearbeiten: leerer Autor entfernt ihn, Titel darf nicht leer sein.
    await useCase.editBook(book.id, title: 'Neuer Titel', author: 'A. B.');
    expect((await repo.bookById(book.id))!.author, 'A. B.');
    await useCase.editBook(book.id, title: 'Neuer Titel', author: '');
    expect((await repo.bookById(book.id))!.author, isNull);
    expect(
      () => useCase.editBook(book.id, title: ' ', author: null),
      throwsArgumentError,
    );

    // Passagen: Tag ist der heutige, Reihenfolge chronologisch.
    final p1 = (await useCase.addPassage(
      book.id,
      text: ' Erste Stelle. ',
      page: ' S. 1 ',
      thought: '',
    ))!;
    expect(p1.text, 'Erste Stelle.');
    expect(p1.page, 'S. 1');
    expect(p1.thought, isNull);
    expect(p1.day, LocalDay.forMoment(clock.now()));
    clock.advance(const Duration(minutes: 5));
    final p2 = (await useCase.addPassage(book.id, text: 'Zweite Stelle.'))!;
    expect((await repo.listPassages(book.id)).map((p) => p.id), [p1.id, p2.id]);
    expect(await useCase.addPassage('fehlt', text: 'x'), isNull);
    expect(() => useCase.addPassage(book.id, text: ''), throwsArgumentError);
    expect(await repo.passagesForDay(p1.day), hasLength(2));
    expect(await repo.passagesForDay(p1.day.previous), isEmpty);

    await useCase.editPassage(
      p1.id,
      text: 'Erste Stelle, geändert.',
      page: '',
      thought: 'Ein Gedanke.',
    );
    final edited = (await repo.passageById(p1.id))!;
    expect(edited.text, 'Erste Stelle, geändert.');
    expect(edited.page, isNull);
    expect(edited.thought, 'Ein Gedanke.');
    expect(edited.day, p1.day);

    await useCase.deletePassage(p2.id);
    expect((await repo.listPassages(book.id)).single.id, p1.id);
    // Buch löschen nimmt die Passagen mit.
    await useCase.deleteBook(book.id);
    expect(await repo.bookById(book.id), isNull);
    expect(await repo.listPassages(book.id), isEmpty);
    expect(await repo.listAllPassages(), isEmpty);
  });
}
