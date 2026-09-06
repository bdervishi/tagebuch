/// Gemeinsame Testhelfer: Beispieldaten, Zähler für eindeutige Dateinamen,
/// Matcher für SQLite-Fehler aus Vorder- und Hintergrund-Isolate.
library;

import 'package:diary_storage/diary_storage.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart' show SqliteException;
import 'package:test/test.dart';

const String testTimeZone = 'Europe/Berlin';

int _fileCounter = 0;

/// Eindeutiger Dateiname (Unique auf `recording.file_name`).
String nextFileName() => 'rec-${++_fileCounter}.m4a';

Uint8List filledBytes(int length, [int fill = 7]) =>
    Uint8List.fromList(List<int>.filled(length, fill));

/// Der Fehler ist eine [SqliteException], auch wenn er aus dem
/// Hintergrund-Isolate als `DriftRemoteException` ankommt.
final Matcher throwsSqlite = throwsA(
  predicate<Object>(
    (e) => unwrapRemoteError(e) is SqliteException,
    'is a SqliteException (ggf. aus dem Isolate)',
  ),
);

final class Seeded {
  final Journal journal;
  final Entry entry;
  final int recordingId;
  final int transcriptId;
  final String fileName;

  const Seeded({
    required this.journal,
    required this.entry,
    required this.recordingId,
    required this.transcriptId,
    required this.fileName,
  });
}

Future<int> seedRecording(
  DiaryDatabase db,
  int entryId, {
  String? fileName,
  int startedAt = 1757145600000,
  int durationMs = 60000,
  String state = RecordingStates.complete,
}) {
  return db.recordingsDao.insert(
    entryId: entryId,
    startedAt: startedAt,
    timeZone: testTimeZone,
    durationMs: durationMs,
    codec: AudioCodecs.aacLc,
    container: AudioContainers.m4a,
    sampleRate: 24000,
    bitrate: 32000,
    fileName: fileName ?? nextFileName(),
    fileKeyWrapped: filledBytes(48),
    sizeBytes: 240000,
    waveform: filledBytes(100),
    state: state,
  );
}

/// Legt Tagebuch (falls nötig), Eintrag, Aufnahme und Transkript an. Ohne
/// [segments] entsteht ein Segment über den ganzen Text.
Future<Seeded> seedTranscript(
  DiaryDatabase db, {
  required String day,
  required String text,
  List<SegmentInput>? segments,
  List<WordInput> words = const [],
  int? journalId,
  bool? isPrimary,
  String? fileName,
}) async {
  final journal = journalId == null
      ? await db.journalsDao.ensureDefaultJournal()
      : (await db.journalsDao.getById(journalId))!;
  final entry = await db.entriesDao.getOrCreateForDay(
    journal.id,
    day,
    timeZone: testTimeZone,
  );
  final name = fileName ?? nextFileName();
  final recordingId = await seedRecording(db, entry.id, fileName: name);
  final transcriptId = await db.transcriptsDao.insertWithSegmentsAndWords(
    recordingId: recordingId,
    engine: TranscriptEngines.sherpaMoonshineSmall,
    modelVersion: 'test',
    locale: 'de-DE',
    text: text,
    isPrimary: isPrimary,
    segments:
        segments ??
        [SegmentInput(idx: 0, startMs: 0, endMs: 60000, text: text)],
    words: words,
  );
  return Seeded(
    journal: journal,
    entry: entry,
    recordingId: recordingId,
    transcriptId: transcriptId,
    fileName: name,
  );
}

Future<int> countRows(
  DiaryDatabase db,
  String table, {
  String? where,
  List<Object> args = const [],
}) async {
  final sql =
      'SELECT COUNT(*) AS c FROM $table${where == null ? '' : ' WHERE $where'}';
  final row = await db
      .customSelect(sql, variables: [for (final a in args) Variable(a)])
      .getSingle();
  return row.read<int>('c');
}

Future<Object?> pragma(DiaryDatabase db, String name) async {
  final row = await db.customSelect('PRAGMA $name').getSingle();
  return row.data.values.first;
}

Future<Set<String>> schemaNames(DiaryDatabase db, String type) async {
  final rows = await db
      .customSelect(
        'SELECT name FROM sqlite_master WHERE type = ?',
        variables: [Variable<String>(type)],
      )
      .get();
  return rows.map((r) => r.read<String>('name')).toSet();
}
