import 'dart:convert';
import 'dart:typed_data';

import 'package:meta/meta.dart';

import 'local_day.dart';

/// Format einer geladenen Buchdatei (D25). Bisher nur EPUB; PDF ist für eine
/// spätere Runde vorgesehen.
enum BookFormat {
  epub;

  static BookFormat? tryParse(String? name) =>
      values.where((f) => f.name == name).firstOrNull;
}

/// Leseposition eines E-Books (D25): das eine Lesezeichen je Buch.
@immutable
class ReadingPosition {
  const ReadingPosition({
    required this.chapterIndex,
    this.blockIndex = 0,
    this.progress = 0,
  });

  /// Kapitel in Spine-Reihenfolge, ab 0.
  final int chapterIndex;

  /// Erster sichtbarer Block im Kapitel, ab 0.
  final int blockIndex;

  /// Fortschritt im ganzen Buch, 0 bis 1.
  final double progress;

  Map<String, Object?> toJson() => {
    'chapter': chapterIndex,
    'block': blockIndex,
    'progress': progress,
  };

  static ReadingPosition fromJson(Map<String, Object?> m) => ReadingPosition(
    chapterIndex: (m['chapter'] as num?)?.toInt() ?? 0,
    blockIndex: (m['block'] as num?)?.toInt() ?? 0,
    progress: ((m['progress'] as num?)?.toDouble() ?? 0).clamp(0.0, 1.0),
  );

  String encode() => jsonEncode(toJson());

  /// Tolerant: unlesbares JSON ergibt `null` (kein Lesezeichen).
  static ReadingPosition? decode(String? json) {
    if (json == null || json.isEmpty) return null;
    try {
      final decoded = jsonDecode(json);
      if (decoded is! Map) return null;
      return fromJson(Map<String, Object?>.from(decoded));
    } on FormatException {
      return null;
    }
  }

  @override
  bool operator ==(Object other) =>
      other is ReadingPosition &&
      other.chapterIndex == chapterIndex &&
      other.blockIndex == blockIndex &&
      other.progress == progress;

  @override
  int get hashCode => Object.hash(chapterIndex, blockIndex, progress);
}

/// Anker einer Passage im E-Book (D25): Kapitel, Block, Zeichen-Offsets und
/// ein Textauszug, damit die Stelle auch nach einem Neuparsen wiederzufinden
/// ist. Passagen ohne Anker (getippt, ältere Backups) bleiben gültig.
@immutable
class PassageAnchor {
  const PassageAnchor({
    required this.chapterIndex,
    required this.blockIndex,
    required this.start,
    required this.end,
    this.endBlockIndex,
    this.excerpt = '',
  });

  final int chapterIndex;

  /// Block, in dem die Markierung beginnt.
  final int blockIndex;

  /// Zeichen-Offset im Startblock (einschließlich).
  final int start;

  /// Zeichen-Offset im Endblock (ausschließlich).
  final int end;

  /// Block, in dem die Markierung endet; `null` = derselbe wie [blockIndex].
  final int? endBlockIndex;

  /// Anfang des markierten Texts (höchstens rund 80 Zeichen).
  final String excerpt;

  int get lastBlockIndex => endBlockIndex ?? blockIndex;

  Map<String, Object?> toJson() => {
    'chapter': chapterIndex,
    'block': blockIndex,
    'start': start,
    'end': end,
    if (endBlockIndex != null) 'endBlock': endBlockIndex,
    'excerpt': excerpt,
  };

  static PassageAnchor fromJson(Map<String, Object?> m) => PassageAnchor(
    chapterIndex: (m['chapter'] as num?)?.toInt() ?? 0,
    blockIndex: (m['block'] as num?)?.toInt() ?? 0,
    start: (m['start'] as num?)?.toInt() ?? 0,
    end: (m['end'] as num?)?.toInt() ?? 0,
    endBlockIndex: (m['endBlock'] as num?)?.toInt(),
    excerpt: m['excerpt'] as String? ?? '',
  );

  String encode() => jsonEncode(toJson());

  static PassageAnchor? decode(String? json) {
    if (json == null || json.isEmpty) return null;
    try {
      final decoded = jsonDecode(json);
      if (decoded is! Map) return null;
      return fromJson(Map<String, Object?>.from(decoded));
    } on FormatException {
      return null;
    }
  }

  @override
  bool operator ==(Object other) =>
      other is PassageAnchor &&
      other.chapterIndex == chapterIndex &&
      other.blockIndex == blockIndex &&
      other.start == start &&
      other.end == end &&
      other.endBlockIndex == endBlockIndex &&
      other.excerpt == excerpt;

  @override
  int get hashCode =>
      Object.hash(chapterIndex, blockIndex, start, end, endBlockIndex, excerpt);
}

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
/// keine ISBN, keine Netzsuche. Optional hängt eine EPUB-Datei daran (D25):
/// verschlüsselt im Dateispeicher, mit Leseposition als Lesezeichen.
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
    this.format,
    this.fileName,
    this.fileKeyWrapped,
    this.fileSizeBytes,
    this.readingPosition,
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

  /// Format der Buchdatei (D25); `null`, wenn keine Datei geladen ist.
  final BookFormat? format;

  /// Name der verschlüsselten Datei im Dateispeicher (`book-<id>.epub.tgbc`).
  final String? fileName;

  /// Dateischlüssel, mit dem Master-Key gewrappt (wie `Recording`); gehört
  /// zur Datei und wird nicht exportiert.
  final Uint8List? fileKeyWrapped;

  /// Größe der Datei in Byte (für den Hinweis im Backup-Bildschirm).
  final int? fileSizeBytes;

  /// Lesezeichen; `null`, bevor zum ersten Mal gelesen wurde.
  final ReadingPosition? readingPosition;

  /// Ob eine lesbare Buchdatei am Buch hängt.
  bool get hasFile =>
      format != null &&
      fileName != null &&
      fileKeyWrapped != null &&
      fileKeyWrapped!.isNotEmpty;

  /// Autor, ersatzweise der Titel (für das Zitat aus einer Passage, D20).
  String get attribution {
    final a = author?.trim();
    return a == null || a.isEmpty ? title : a;
  }

  /// [clearAuthor] entfernt den Autor; [clearFinished] entfernt das Datum;
  /// [clearFile] entfernt Datei, Format, Größe und Leseposition.
  Book copyWith({
    String? title,
    String? author,
    BookStatus? status,
    DateTime? updatedAt,
    DateTime? finishedAt,
    BookFormat? format,
    String? fileName,
    Uint8List? fileKeyWrapped,
    int? fileSizeBytes,
    ReadingPosition? readingPosition,
    bool clearAuthor = false,
    bool clearFinished = false,
    bool clearFile = false,
  }) => Book(
    id: id,
    journalId: journalId,
    title: title ?? this.title,
    author: clearAuthor ? null : (author ?? this.author),
    status: status ?? this.status,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    finishedAt: clearFinished ? null : (finishedAt ?? this.finishedAt),
    format: clearFile ? null : (format ?? this.format),
    fileName: clearFile ? null : (fileName ?? this.fileName),
    fileKeyWrapped: clearFile ? null : (fileKeyWrapped ?? this.fileKeyWrapped),
    fileSizeBytes: clearFile ? null : (fileSizeBytes ?? this.fileSizeBytes),
    readingPosition: clearFile
        ? null
        : (readingPosition ?? this.readingPosition),
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
    this.anchor,
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

  /// Stelle im E-Book (D25); `null` bei getippten Passagen.
  final PassageAnchor? anchor;

  /// [clearPage] und [clearThought] entfernen die optionalen Felder.
  Passage copyWith({
    String? text,
    String? page,
    String? thought,
    DateTime? updatedAt,
    LocalDay? day,
    PassageAnchor? anchor,
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
    anchor: anchor ?? this.anchor,
  );
}
