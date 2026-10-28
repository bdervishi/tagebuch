import 'dart:typed_data';

import 'package:diary_core/diary_core.dart';
import 'package:diary_epub/diary_epub.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/app_services.dart';
import 'entry_view.dart';

/// Ein Buch mit seinen Passagen, wie es die Oberfläche zeigt (D21).
class BookView {
  const BookView({required this.book, required this.passages});

  final Book book;

  /// Chronologisch, älteste zuerst.
  final List<Passage> passages;

  String get id => book.id;

  static Future<BookView> load(AppServices s, Book book) async =>
      BookView(book: book, passages: await s.books.listPassages(book.id));
}

/// Alle Bücher des Tagebuchs mit Passagen, zuletzt geänderte zuerst.
final booksProvider = FutureProvider<List<BookView>>((ref) async {
  ref.watch(dataVersionProvider);
  final s = await ref.watch(appServicesProvider.future);
  return [
    for (final b in await s.books.listBooks(s.journalId))
      await BookView.load(s, b),
  ];
});

/// Ein Buch nach Kennung oder `null`.
final bookViewProvider = FutureProvider.family<BookView?, String>((
  ref,
  bookId,
) async {
  ref.watch(dataVersionProvider);
  final s = await ref.watch(appServicesProvider.future);
  final book = await s.books.bookById(bookId);
  return book == null ? null : BookView.load(s, book);
});

/// Das Buch für die Zeile "Lese ich" auf "Heute": das zuletzt geänderte mit
/// Status `reading`, oder `null`.
final readingBookProvider = FutureProvider<BookView?>((ref) async {
  final books = await ref.watch(booksProvider.future);
  return books.where((v) => v.book.status == BookStatus.reading).firstOrNull;
});

/// Summe der Buchdateien in Byte (Hinweis im Backup-Bildschirm, D25).
final bookFilesSizeProvider = FutureProvider<int>((ref) async {
  final books = await ref.watch(booksProvider.future);
  return books.fold<int>(0, (n, v) => n + (v.book.fileSizeBytes ?? 0));
});

/// Das geöffnete EPUB eines Buchs (D25): Datei entschlüsselt lesen und
/// einmal je Sitzung parsen; Kapitel werden erst beim Anzeigen zerlegt.
/// `null`, wenn das Buch keine lesbare Datei hat. Wirft [EpubException] bei
/// einer unlesbaren Datei. Nicht an `dataVersionProvider` gebunden: Lesen
/// und Markieren sollen das Buch nicht neu parsen; `BookActions.attachEpub`
/// macht den Eintrag gezielt ungültig.
final readerDocumentProvider = FutureProvider.family<EpubDocument?, String>((
  ref,
  bookId,
) async {
  final s = await ref.watch(appServicesProvider.future);
  final book = await s.books.bookById(bookId);
  if (book == null || !book.hasFile) return null;
  final bytes = await s.booksUseCase().readFile(book);
  if (bytes == null) return null;
  return EpubDocument.open(bytes);
});

/// Ergebnis der EPUB-Prüfung vor dem Laden (D25): Titel und Autor aus dem
/// Buch und Bücher ohne Datei, deren Titel ähnlich ist (die Nutzerin wählt
/// dann Anhängen oder Neuanlegen).
class EpubImportPlan {
  const EpubImportPlan({
    required this.bytes,
    required this.title,
    required this.author,
    required this.candidates,
  });

  final Uint8List bytes;
  final String title;
  final String? author;
  final List<Book> candidates;
}

/// Eine Passage mit ihrem Buch (Abschnitt "Heute gelesen" im Eintrag).
class DayPassage {
  const DayPassage({required this.book, required this.passage});
  final Book book;
  final Passage passage;
}

/// Passagen, die an einem Tag festgehalten wurden, älteste zuerst; Passagen
/// ohne Buch fehlen.
final dayPassagesProvider = FutureProvider.family<List<DayPassage>, LocalDay>((
  ref,
  day,
) async {
  ref.watch(dataVersionProvider);
  final s = await ref.watch(appServicesProvider.future);
  final result = <DayPassage>[];
  final books = <String, Book?>{};
  for (final p in await s.books.passagesForDay(day)) {
    final book = books[p.bookId] ??= await s.books.bookById(p.bookId);
    if (book == null || book.journalId != s.journalId) continue;
    result.add(DayPassage(book: book, passage: p));
  }
  return result;
});

/// Schreibende Aktionen für Bücher und Passagen. Jede Änderung erhöht den
/// Datenzähler, damit "Heute", "Lesebuch", Eintrag und Suche neu laden.
class BookActions {
  const BookActions(this.ref);
  final Ref ref;

  Future<BooksUseCase> _useCase() async =>
      (await ref.read(appServicesProvider.future)).booksUseCase();

  void _bump() => ref.read(dataVersionProvider.notifier).bump();

  Future<Book> create({
    required String title,
    String? author,
    BookStatus status = BookStatus.reading,
  }) async {
    final book = await (await _useCase()).addBook(
      title: title,
      author: author,
      status: status,
    );
    _bump();
    return book;
  }

  Future<void> edit(
    String bookId, {
    required String title,
    String? author,
  }) async {
    await (await _useCase()).editBook(bookId, title: title, author: author);
    _bump();
  }

  Future<void> setStatus(String bookId, BookStatus status) async {
    await (await _useCase()).setStatus(bookId, status);
    _bump();
  }

  Future<void> delete(String bookId) async {
    await (await _useCase()).deleteBook(bookId);
    ref.invalidate(readerDocumentProvider(bookId));
    _bump();
  }

  // ----- E-Reader (D25) --------------------------------------------------

  /// Prüft ein gewähltes EPUB: Größe, ZIP, Kopierschutz; liest Titel und
  /// Autor und sucht Bücher ohne Datei mit ähnlichem Titel. Wirft
  /// [EpubException].
  Future<EpubImportPlan> inspectEpub(Uint8List bytes) async {
    final doc = EpubDocument.open(bytes);
    final s = await ref.read(appServicesProvider.future);
    final key = _titleKey(doc.book.title);
    final candidates = [
      for (final b in await s.books.listBooks(s.journalId))
        if (!b.hasFile && _similar(_titleKey(b.title), key)) b,
    ];
    return EpubImportPlan(
      bytes: bytes,
      title: doc.book.title,
      author: doc.book.author,
      candidates: candidates,
    );
  }

  /// Legt ein neues Buch mit Status "Lese ich" an und hängt die Datei an.
  Future<Book> importEpubAsNewBook(EpubImportPlan plan) async {
    final useCase = await _useCase();
    final book = await useCase.addBook(title: plan.title, author: plan.author);
    final attached = await useCase.attachFile(book.id, bytes: plan.bytes);
    _bump();
    return attached ?? book;
  }

  /// Hängt die Datei an ein vorhandenes Buch (ersetzt eine alte Datei).
  Future<Book?> attachEpub(String bookId, Uint8List bytes) async {
    final book = await (await _useCase()).attachFile(bookId, bytes: bytes);
    ref.invalidate(readerDocumentProvider(bookId));
    _bump();
    return book;
  }

  /// Merkt die Leseposition; ohne Datenzähler, damit der Reader beim Lesen
  /// nichts neu lädt. Beim Verlassen ruft der Reader [finishReading].
  Future<void> saveReadingPosition(String bookId, ReadingPosition position) =>
      _useCase().then((u) => u.saveReadingPosition(bookId, position));

  /// Beim Verlassen des Readers: letzte Position sichern und die Ansichten
  /// (Buchdetail, "Mehr") einmal neu laden lassen.
  Future<void> finishReading(String bookId, ReadingPosition? position) async {
    if (position != null) await saveReadingPosition(bookId, position);
    // Der Reader ruft dies aus `dispose`; ein Provider darf erst nach dem
    // Aufräumen des Widget-Baums geändert werden (Mikrotask, kein Timer).
    await Future<void>.microtask(() {});
    // Beim Schließen der ganzen App ist der Provider schon weg.
    if (!ref.mounted) return;
    _bump();
  }

  /// Normalisierter Titel für den Ähnlichkeitsvergleich: Kleinschreibung,
  /// nur Buchstaben und Ziffern.
  static String _titleKey(String title) => title.toLowerCase().replaceAll(
    RegExp(r'[^\p{L}\p{N}]+', unicode: true),
    '',
  );

  /// Gleich oder eines enthält das andere (ab vier Zeichen).
  static bool _similar(String a, String b) {
    if (a.isEmpty || b.isEmpty) return false;
    if (a == b) return true;
    final shorter = a.length < b.length ? a : b;
    final longer = a.length < b.length ? b : a;
    return shorter.length >= 4 && longer.contains(shorter);
  }

  Future<Passage?> addPassage(
    String bookId, {
    required String text,
    String? page,
    String? thought,
    PassageAnchor? anchor,
  }) async {
    final p = await (await _useCase()).addPassage(
      bookId,
      text: text,
      page: page,
      thought: thought,
      anchor: anchor,
    );
    if (p != null) _bump();
    return p;
  }

  Future<void> editPassage(
    String passageId, {
    required String text,
    String? page,
    String? thought,
  }) async {
    await (await _useCase()).editPassage(
      passageId,
      text: text,
      page: page,
      thought: thought,
    );
    _bump();
  }

  Future<void> deletePassage(String passageId) async {
    await (await _useCase()).deletePassage(passageId);
    _bump();
  }
}

final bookActionsProvider = Provider<BookActions>((ref) => BookActions(ref));
