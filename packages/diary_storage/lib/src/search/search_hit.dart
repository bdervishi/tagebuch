/// Ergebnis der Volltextsuche.
library;

/// Sortierung der Suchergebnisse.
enum SearchOrder {
  /// Nach `bm25()` (beste Treffer zuerst), bei Gleichstand neueste zuerst.
  relevance,

  /// Nach `entry.day` absteigend, innerhalb eines Tages nach Relevanz.
  newestFirst,

  /// Nach `entry.day` aufsteigend, innerhalb eines Tages nach Relevanz.
  oldestFirst,
}

/// Ein Treffer der Volltextsuche.
final class SearchHit {
  final int entryId;
  final int journalId;

  /// ISO-Datum des Eintrags (`YYYY-MM-DD`).
  final String day;

  final int recordingId;
  final int transcriptId;

  /// Ausschnitt aus `snippet()` mit den gewählten Markierungen um Treffer.
  final String snippet;

  /// `bm25()`-Wert; kleiner ist besser (negativ).
  final double score;

  /// Index des ersten Segments, dessen Text einen Suchbegriff enthält, oder
  /// `null`, wenn der Begriff nur im (ggf. bearbeiteten) Gesamttext vorkommt.
  final int? segmentIdx;

  /// Startzeit dieses Segments in Millisekunden, für den Sprung in die
  /// Wiedergabe; `null` wie [segmentIdx].
  final int? startMs;

  const SearchHit({
    required this.entryId,
    required this.journalId,
    required this.day,
    required this.recordingId,
    required this.transcriptId,
    required this.snippet,
    required this.score,
    this.segmentIdx,
    this.startMs,
  });

  @override
  String toString() =>
      'SearchHit(entry $entryId, $day, recording $recordingId, '
      'transcript $transcriptId, score $score, startMs $startMs, "$snippet")';
}
