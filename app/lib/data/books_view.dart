import 'package:diary_core/diary_core.dart';
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
    _bump();
  }

  Future<Passage?> addPassage(
    String bookId, {
    required String text,
    String? page,
    String? thought,
  }) async {
    final p = await (await _useCase()).addPassage(
      bookId,
      text: text,
      page: page,
      thought: thought,
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
