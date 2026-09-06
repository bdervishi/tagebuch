/// Zugriff auf `transcript`, `transcript_segment` und `transcript_word`.
library;

import 'package:drift/drift.dart';

import '../database.dart';
import '../tables.dart';
import '../values.dart';

part 'transcripts_dao.g.dart';

/// Segment für [TranscriptsDao.insertWithSegmentsAndWords].
final class SegmentInput {
  final int idx;
  final int startMs;
  final int endMs;
  final String text;
  final double? confidence;

  /// Siehe [BoundarySources].
  final String boundarySource;

  const SegmentInput({
    required this.idx,
    required this.startMs,
    required this.endMs,
    required this.text,
    this.confidence,
    this.boundarySource = BoundarySources.engine,
  });
}

/// Wort für [TranscriptsDao.insertWithSegmentsAndWords]; [segmentIdx] muss
/// auf ein Segment derselben Eingabe zeigen.
final class WordInput {
  final int segmentIdx;
  final int idx;
  final int startMs;
  final int endMs;
  final String text;
  final double? confidence;

  const WordInput({
    required this.segmentIdx,
    required this.idx,
    required this.startMs,
    required this.endMs,
    required this.text,
    this.confidence,
  });
}

@DriftAccessor(
  tables: [Transcripts, TranscriptSegments, TranscriptWords, Recordings],
)
class TranscriptsDao extends DatabaseAccessor<DiaryDatabase>
    with _$TranscriptsDaoMixin {
  TranscriptsDao(super.attachedDatabase);

  /// Legt Transkript, Segmente und Wörter in einer Transaktion an. Liefert die
  /// Transkript-id.
  ///
  /// [isPrimary] `true` macht dieses Transkript primär und nimmt anderen
  /// Transkripten der Aufnahme den Status; `null` (Vorgabe) macht es nur dann
  /// primär, wenn die Aufnahme noch keines hat.
  Future<int> insertWithSegmentsAndWords({
    required int recordingId,
    required String engine,
    required String modelVersion,
    required String locale,
    required String text,
    int? createdAt,
    bool? isPrimary,
    bool editedByUser = false,
    List<SegmentInput> segments = const [],
    List<WordInput> words = const [],
  }) {
    return transaction(() async {
      var primary = isPrimary;
      if (primary == null) {
        primary = await getPrimaryForRecording(recordingId) == null;
      } else if (primary) {
        await _clearPrimary(recordingId);
      }
      final id = await into(transcripts).insert(
        TranscriptsCompanion.insert(
          recordingId: recordingId,
          engine: engine,
          modelVersion: modelVersion,
          locale: locale,
          createdAt: createdAt ?? nowUtcMillis(),
          content: text,
          isPrimary: Value(primary),
          editedByUser: Value(editedByUser),
        ),
      );
      await batch((b) {
        b.insertAll(transcriptSegments, [
          for (final s in segments)
            TranscriptSegmentsCompanion.insert(
              transcriptId: id,
              idx: s.idx,
              startMs: s.startMs,
              endMs: s.endMs,
              content: s.text,
              confidence: Value(s.confidence),
              boundarySource: Value(s.boundarySource),
            ),
        ]);
        b.insertAll(transcriptWords, [
          for (final w in words)
            TranscriptWordsCompanion.insert(
              transcriptId: id,
              segmentIdx: w.segmentIdx,
              idx: w.idx,
              startMs: w.startMs,
              endMs: w.endMs,
              content: w.text,
              confidence: Value(w.confidence),
            ),
        ]);
      });
      return id;
    });
  }

  /// Macht [transcriptId] zum primären Transkript seiner Aufnahme.
  Future<void> setPrimary(int transcriptId) {
    return transaction(() async {
      final transcript = await getById(transcriptId);
      if (transcript == null) {
        throw ArgumentError.value(
          transcriptId,
          'transcriptId',
          'Transkript existiert nicht.',
        );
      }
      await _clearPrimary(transcript.recordingId);
      await (update(transcripts)..where((t) => t.id.equals(transcriptId)))
          .write(const TranscriptsCompanion(isPrimary: Value(true)));
    });
  }

  Future<void> _clearPrimary(int recordingId) {
    return (update(transcripts)
          ..where((t) => t.recordingId.equals(recordingId) & t.isPrimary))
        .write(const TranscriptsCompanion(isPrimary: Value(false)));
  }

  /// Ersetzt den Text; der FTS-Index folgt über den Update-Trigger.
  /// [editedByUser] markiert Nutzerkorrekturen (Vorgabe `true`).
  Future<bool> updateText(
    int transcriptId,
    String text, {
    bool editedByUser = true,
  }) async {
    final rows =
        await (update(
          transcripts,
        )..where((t) => t.id.equals(transcriptId))).write(
          TranscriptsCompanion(
            content: Value(text),
            editedByUser: Value(editedByUser),
          ),
        );
    return rows > 0;
  }

  Future<Transcript?> getById(int id) =>
      (select(transcripts)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<Transcript?> getPrimaryForRecording(int recordingId) {
    return (select(transcripts)
          ..where((t) => t.recordingId.equals(recordingId) & t.isPrimary))
        .getSingleOrNull();
  }

  /// Alle Transkripte einer Aufnahme, neueste zuerst.
  Future<List<Transcript>> listForRecording(int recordingId) {
    return (select(transcripts)
          ..where((t) => t.recordingId.equals(recordingId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  Future<List<TranscriptSegment>> getSegments(int transcriptId) {
    return (select(transcriptSegments)
          ..where((s) => s.transcriptId.equals(transcriptId))
          ..orderBy([(s) => OrderingTerm.asc(s.idx)]))
        .get();
  }

  Future<List<TranscriptWord>> getWords(int transcriptId) {
    return (select(transcriptWords)
          ..where((w) => w.transcriptId.equals(transcriptId))
          ..orderBy([
            (w) => OrderingTerm.asc(w.segmentIdx),
            (w) => OrderingTerm.asc(w.idx),
          ]))
        .get();
  }

  /// Löscht ein Transkript mit Segmenten und Wörtern (Kaskade).
  Future<bool> deleteTranscript(int transcriptId) async {
    final rows = await (delete(
      transcripts,
    )..where((t) => t.id.equals(transcriptId))).go();
    if (rows > 0) {
      notifyUpdates({
        TableUpdate.onTable(transcriptSegments, kind: UpdateKind.delete),
        TableUpdate.onTable(transcriptWords, kind: UpdateKind.delete),
      });
    }
    return rows > 0;
  }
}
