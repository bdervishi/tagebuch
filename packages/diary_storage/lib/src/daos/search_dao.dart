/// Volltextsuche über `transcript_fts` (docs/04, Abschnitt 6).
library;

import 'package:drift/drift.dart';

import '../database.dart';
import '../fts.dart';
import '../search/fts_query.dart';
import '../search/search_hit.dart';
import '../search/text_normalization.dart';
import '../tables.dart';

part 'search_dao.g.dart';

@DriftAccessor(
  tables: [Transcripts, TranscriptSegments, Recordings, Entries, EntryTags],
)
class SearchDao extends DatabaseAccessor<DiaryDatabase> with _$SearchDaoMixin {
  SearchDao(super.attachedDatabase);

  /// Sucht [query] im FTS5-Index.
  ///
  /// - Begriffe werden über [buildFtsMatchExpression] sicher maskiert und
  ///   UND-verknüpft; [prefix] schaltet die Präfixsuche (Vorgabe an).
  /// - Filter: [journalId], [from]/[to] (ISO-Tage, inklusive), [tagId].
  /// - [primaryOnly] (Vorgabe) berücksichtigt je Aufnahme nur das primäre
  ///   Transkript, damit eine Aufnahme nicht mehrfach erscheint.
  /// - Sortierung nach [order]; Relevanz ist `bm25()`.
  /// - Das Snippet stammt aus `snippet()` mit [highlightStart]/[highlightEnd]
  ///   um Treffer und höchstens [snippetTokens] Tokens.
  /// - [SearchHit.startMs] ist die Startzeit des ersten Segments, dessen
  ///   gefalteter Text einen Suchbegriff enthält (Sprung in die Wiedergabe).
  Future<List<SearchHit>> search(
    String query, {
    int? journalId,
    String? from,
    String? to,
    int? tagId,
    bool prefix = true,
    bool primaryOnly = true,
    SearchOrder order = SearchOrder.relevance,
    int limit = 50,
    String highlightStart = '[',
    String highlightEnd = ']',
    int snippetTokens = 12,
  }) async {
    final match = buildFtsMatchExpression(query, prefix: prefix);
    if (match == null) {
      return const [];
    }

    final where = StringBuffer('$ftsTableName MATCH ?');
    final variables = <Variable<Object>>[
      Variable<String>(highlightStart),
      Variable<String>(highlightEnd),
      Variable<int>(snippetTokens),
      Variable<String>(match),
    ];
    if (primaryOnly) {
      where.write(' AND t.is_primary = 1');
    }
    if (journalId != null) {
      where.write(' AND e.journal_id = ?');
      variables.add(Variable<int>(journalId));
    }
    if (from != null) {
      where.write(' AND e.day >= ?');
      variables.add(Variable<String>(from));
    }
    if (to != null) {
      where.write(' AND e.day <= ?');
      variables.add(Variable<String>(to));
    }
    if (tagId != null) {
      where.write(
        ' AND EXISTS (SELECT 1 FROM entry_tag et '
        'WHERE et.entry_id = e.id AND et.tag_id = ?)',
      );
      variables.add(Variable<int>(tagId));
    }
    variables.add(Variable<int>(limit));

    final orderBy = switch (order) {
      SearchOrder.relevance => 'score ASC, e.day DESC, t.id DESC',
      SearchOrder.newestFirst => 'e.day DESC, score ASC, t.id DESC',
      SearchOrder.oldestFirst => 'e.day ASC, score ASC, t.id ASC',
    };

    final rows = await customSelect(
      'SELECT t.id AS transcript_id, t.recording_id AS recording_id, '
      'r.entry_id AS entry_id, e.journal_id AS journal_id, e.day AS day, '
      "snippet($ftsTableName, 0, ?, ?, '…', ?) AS snippet, "
      'bm25($ftsTableName) AS score '
      'FROM $ftsTableName '
      'JOIN transcript t ON t.id = $ftsTableName.rowid '
      'JOIN recording r ON r.id = t.recording_id '
      'JOIN entry e ON e.id = r.entry_id '
      'WHERE $where ORDER BY $orderBy LIMIT ?',
      variables: variables,
      readsFrom: {transcripts, recordings, entries, entryTags},
    ).get();
    if (rows.isEmpty) {
      return const [];
    }

    final terms = foldedSearchTerms(query);
    final firstSegments = await _firstMatchingSegments(
      rows.map((row) => row.read<int>('transcript_id')).toSet(),
      terms,
    );

    return [
      for (final row in rows)
        _toHit(row, firstSegments[row.read<int>('transcript_id')]),
    ];
  }

  SearchHit _toHit(QueryRow row, TranscriptSegment? segment) {
    return SearchHit(
      entryId: row.read<int>('entry_id'),
      journalId: row.read<int>('journal_id'),
      day: row.read<String>('day'),
      recordingId: row.read<int>('recording_id'),
      transcriptId: row.read<int>('transcript_id'),
      snippet: row.read<String>('snippet'),
      score: row.read<double>('score'),
      segmentIdx: segment?.idx,
      startMs: segment?.startMs,
    );
  }

  /// Erstes Segment je Transkript, dessen gefalteter Text einen der [terms]
  /// enthält.
  Future<Map<int, TranscriptSegment>> _firstMatchingSegments(
    Set<int> transcriptIds,
    List<String> terms,
  ) async {
    if (transcriptIds.isEmpty || terms.isEmpty) {
      return const {};
    }
    final segments =
        await (select(transcriptSegments)
              ..where((s) => s.transcriptId.isIn(transcriptIds))
              ..orderBy([
                (s) => OrderingTerm.asc(s.transcriptId),
                (s) => OrderingTerm.asc(s.idx),
              ]))
            .get();
    final result = <int, TranscriptSegment>{};
    for (final segment in segments) {
      if (result.containsKey(segment.transcriptId)) {
        continue;
      }
      final folded = foldForMatch(segment.content);
      if (terms.any(folded.contains)) {
        result[segment.transcriptId] = segment;
      }
    }
    return result;
  }
}
