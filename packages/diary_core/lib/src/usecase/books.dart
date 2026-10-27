import '../model/book.dart';
import '../model/local_day.dart';
import '../ports/clock.dart';
import '../ports/repositories.dart';
import '../ports/services.dart';

/// Lesebuch (D21): Bücher anlegen, bearbeiten, Status wechseln, löschen;
/// Passagen festhalten, bearbeiten, löschen. Keine Lesestatistik, keine
/// Ziele, keine Empfehlungen.
class BooksUseCase {
  const BooksUseCase({
    required this.journalId,
    required this.books,
    required this.ids,
    required this.clock,
  });

  final String journalId;
  final BookRepository books;
  final IdGenerator ids;
  final Clock clock;

  static String? _clean(String? s) {
    final t = s?.trim();
    return t == null || t.isEmpty ? null : t;
  }

  /// Legt ein Buch an. Leerer Titel wird abgelehnt ([ArgumentError]).
  /// Status `finished` setzt `finishedAt` auf jetzt.
  Future<Book> addBook({
    required String title,
    String? author,
    BookStatus status = BookStatus.reading,
  }) async {
    final t = title.trim();
    if (t.isEmpty) throw ArgumentError('Titel fehlt');
    final now = clock.now();
    final book = Book(
      id: ids.next(),
      journalId: journalId,
      title: t,
      author: _clean(author),
      status: status,
      createdAt: now,
      updatedAt: now,
      finishedAt: status == BookStatus.finished ? now : null,
    );
    await books.insertBook(book);
    return book;
  }

  /// Titel und Autor ändern; leerer Autor entfernt ihn.
  Future<void> editBook(
    String bookId, {
    required String title,
    String? author,
  }) async {
    final book = await books.bookById(bookId);
    if (book == null) return;
    final t = title.trim();
    if (t.isEmpty) throw ArgumentError('Titel fehlt');
    final a = _clean(author);
    await books.updateBook(
      book.copyWith(
        title: t,
        author: a,
        clearAuthor: a == null,
        updatedAt: clock.now(),
      ),
    );
  }

  /// Status wechseln: "Gelesen" setzt `finishedAt` (bleibt, wenn es schon
  /// gesetzt war), jeder andere Status entfernt es.
  Future<void> setStatus(String bookId, BookStatus status) async {
    final book = await books.bookById(bookId);
    if (book == null || book.status == status) return;
    final now = clock.now();
    await books.updateBook(
      status == BookStatus.finished
          ? book.copyWith(
              status: status,
              updatedAt: now,
              finishedAt: book.finishedAt ?? now,
            )
          : book.copyWith(status: status, updatedAt: now, clearFinished: true),
    );
  }

  /// Löscht ein Buch samt Passagen.
  Future<void> deleteBook(String bookId) => books.deleteBook(bookId);

  /// Hält eine Passage fest; der Tag ist der heutige. Leerer Text wird
  /// abgelehnt ([ArgumentError]); liefert `null`, wenn das Buch fehlt.
  Future<Passage?> addPassage(
    String bookId, {
    required String text,
    String? page,
    String? thought,
  }) async {
    final t = text.trim();
    if (t.isEmpty) throw ArgumentError('Text fehlt');
    final book = await books.bookById(bookId);
    if (book == null) return null;
    final now = clock.now();
    final passage = Passage(
      id: ids.next(),
      bookId: bookId,
      createdAt: now,
      updatedAt: now,
      text: t,
      page: _clean(page),
      thought: _clean(thought),
      day: LocalDay.forMoment(now),
    );
    await books.insertPassage(passage);
    await books.updateBook(book.copyWith(updatedAt: now));
    return passage;
  }

  /// Text, Seite und Gedanke ändern; leere Angaben entfernen Seite oder
  /// Gedanke. Der Tag bleibt der des Festhaltens.
  Future<void> editPassage(
    String passageId, {
    required String text,
    String? page,
    String? thought,
  }) async {
    final passage = await books.passageById(passageId);
    if (passage == null) return;
    final t = text.trim();
    if (t.isEmpty) throw ArgumentError('Text fehlt');
    final p = _clean(page);
    final th = _clean(thought);
    await books.updatePassage(
      passage.copyWith(
        text: t,
        page: p,
        thought: th,
        clearPage: p == null,
        clearThought: th == null,
        updatedAt: clock.now(),
      ),
    );
  }

  Future<void> deletePassage(String passageId) =>
      books.deletePassage(passageId);

  /// Bücher nach Status, innerhalb zuletzt geänderte zuerst.
  Future<List<Book>> listByStatus(BookStatus status) async =>
      (await books.listBooks(journalId))
          .where((b) => b.status == status)
          .toList();
}
