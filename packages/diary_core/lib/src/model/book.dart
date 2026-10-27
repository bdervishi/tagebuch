import 'package:meta/meta.dart';

import 'local_day.dart';

/// Wo ein Buch gerade steht (D21). Es gibt keine Lesestatistik, nur diese
/// drei Zustände.
enum BookStatus {
  /// Wird gerade gelesen.
  reading,

  /// Vorgemerkt, noch nicht begonnen.
  planned,

  /// Zu Ende gelesen; `Book.finishedAt` nennt das Datum.
  finished,
}

/// Ein Buch im Lesebuch (D21). Titel und Autor werden getippt: keine Cover,
/// keine ISBN, keine Netzsuche.
@immutable
class Book {
  const Book({
    required this.id,
    required this.journalId,
    required this.title,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.author,
    this.finishedAt,
  });

  final String id;
  final String journalId;
  final String title;

  /// Autorin oder Autor, frei getippt; optional.
  final String? author;
  final BookStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Zeitpunkt des Zu-Ende-Lesens; gesetzt, wenn [status] `finished` ist.
  final DateTime? finishedAt;

  /// Autor, ersatzweise der Titel (für das Zitat aus einer Passage, D20).
  String get attribution {
    final a = author?.trim();
    return a == null || a.isEmpty ? title : a;
  }

  /// [clearAuthor] entfernt den Autor; [clearFinished] entfernt das Datum.
  Book copyWith({
    String? title,
    String? author,
    BookStatus? status,
    DateTime? updatedAt,
    DateTime? finishedAt,
    bool clearAuthor = false,
    bool clearFinished = false,
  }) => Book(
    id: id,
    journalId: journalId,
    title: title ?? this.title,
    author: clearAuthor ? null : (author ?? this.author),
    status: status ?? this.status,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    finishedAt: clearFinished ? null : (finishedAt ?? this.finishedAt),
  );
}

/// Eine festgehaltene Stelle aus einem Buch, optional mit Seitenangabe und
/// eigenem Gedanken dazu (D21).
@immutable
class Passage {
  const Passage({
    required this.id,
    required this.bookId,
    required this.createdAt,
    required this.updatedAt,
    required this.text,
    required this.day,
    this.page,
    this.thought,
  });

  final String id;
  final String bookId;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Die Stelle selbst.
  final String text;

  /// Freie Angabe wie "S. 42" oder "Kap. 3"; optional.
  final String? page;

  /// Eigener Gedanke dazu; optional.
  final String? thought;

  /// Kalendertag, an dem die Passage festgehalten wurde (Abschnitt "Heute
  /// gelesen" im Eintrag dieses Tages).
  final LocalDay day;

  /// [clearPage] und [clearThought] entfernen die optionalen Felder.
  Passage copyWith({
    String? text,
    String? page,
    String? thought,
    DateTime? updatedAt,
    LocalDay? day,
    bool clearPage = false,
    bool clearThought = false,
  }) => Passage(
    id: id,
    bookId: bookId,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    text: text ?? this.text,
    page: clearPage ? null : (page ?? this.page),
    thought: clearThought ? null : (thought ?? this.thought),
    day: day ?? this.day,
  );
}
