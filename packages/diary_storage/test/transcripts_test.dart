import 'package:diary_storage/diary_storage.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:test/test.dart';

import 'support/fixtures.dart';

void main() {
  late DiaryDatabase db;

  setUp(() {
    db = DiaryDatabase.inMemoryForTesting();
  });

  tearDown(() => db.close());

  Future<int> addTranscript(int recordingId, String text, {bool? isPrimary}) {
    return db.transcriptsDao.insertWithSegmentsAndWords(
      recordingId: recordingId,
      engine: TranscriptEngines.sherpaParakeetV3,
      modelVersion: 'v3',
      locale: 'de-DE',
      text: text,
      isPrimary: isPrimary,
    );
  }

  test('das erste Transkript einer Aufnahme wird automatisch primär', () async {
    final seeded = await seedTranscript(db, day: '2026-09-06', text: 'Eins.');
    final second = await addTranscript(seeded.recordingId, 'Zwei.');

    final primary = await db.transcriptsDao.getPrimaryForRecording(
      seeded.recordingId,
    );
    expect(primary!.id, seeded.transcriptId);
    expect((await db.transcriptsDao.getById(second))!.isPrimary, isFalse);
    expect(
      await db.transcriptsDao.listForRecording(seeded.recordingId),
      hasLength(2),
    );
  });

  test(
    'isPrimary: true übernimmt den Status vom bisherigen Transkript',
    () async {
      final seeded = await seedTranscript(db, day: '2026-09-06', text: 'Eins.');
      final second = await addTranscript(
        seeded.recordingId,
        'Zwei.',
        isPrimary: true,
      );

      expect(
        (await db.transcriptsDao.getPrimaryForRecording(seeded.recordingId))!
            .id,
        second,
      );
      expect(
        (await db.transcriptsDao.getById(seeded.transcriptId))!.isPrimary,
        isFalse,
      );
    },
  );

  test('setPrimary wechselt; der partielle Unique-Index verhindert zwei primäre', () async {
    final seeded = await seedTranscript(db, day: '2026-09-06', text: 'Eins.');
    final second = await addTranscript(seeded.recordingId, 'Zwei.');

    await db.transcriptsDao.setPrimary(second);
    expect(
      (await db.transcriptsDao.getPrimaryForRecording(seeded.recordingId))!.id,
      second,
    );

    await db.transcriptsDao.setPrimary(seeded.transcriptId);
    expect(
      (await db.transcriptsDao.getPrimaryForRecording(seeded.recordingId))!.id,
      seeded.transcriptId,
    );

    // Direkt am Schema vorbei: zweites primäres Transkript scheitert am Index.
    expect(
      () => (db.update(db.transcripts)..where((t) => t.id.equals(second)))
          .write(const TranscriptsCompanion(isPrimary: Value(true))),
      throwsSqlite,
    );
    expect(() => db.transcriptsDao.setPrimary(999), throwsArgumentError);
  });

  test('Segmente und Wörter landen geordnet in einer Transaktion', () async {
    final seeded = await seedTranscript(
      db,
      day: '2026-09-06',
      text: 'Guten Morgen. Zahnarzt heute.',
      segments: const [
        SegmentInput(
          idx: 1,
          startMs: 1500,
          endMs: 3000,
          text: 'Zahnarzt heute.',
          confidence: 0.8,
          boundarySource: BoundarySources.vad,
        ),
        SegmentInput(
          idx: 0,
          startMs: 0,
          endMs: 1500,
          text: 'Guten Morgen.',
          confidence: 0.9,
        ),
      ],
      words: const [
        WordInput(
          segmentIdx: 1,
          idx: 0,
          startMs: 1500,
          endMs: 2200,
          text: 'Zahnarzt',
        ),
        WordInput(
          segmentIdx: 0,
          idx: 1,
          startMs: 600,
          endMs: 1400,
          text: 'Morgen',
          confidence: 0.7,
        ),
        WordInput(segmentIdx: 0, idx: 0, startMs: 0, endMs: 600, text: 'Guten'),
      ],
    );

    final segments = await db.transcriptsDao.getSegments(seeded.transcriptId);
    expect(segments.map((s) => s.idx), [0, 1]);
    expect(segments.map((s) => s.content), [
      'Guten Morgen.',
      'Zahnarzt heute.',
    ]);
    expect(segments.map((s) => s.boundarySource), [
      BoundarySources.engine,
      BoundarySources.vad,
    ]);
    expect(segments.last.confidence, 0.8);

    final words = await db.transcriptsDao.getWords(seeded.transcriptId);
    expect(words.map((w) => w.content), ['Guten', 'Morgen', 'Zahnarzt']);
    expect(words[1].confidence, 0.7);
    expect(words.last.confidence, isNull);
  });

  test('ein Wort ohne Segment lässt die ganze Einfügung scheitern', () async {
    final seeded = await seedTranscript(db, day: '2026-09-06', text: 'Eins.');
    final before = await countRows(db, 'transcript');

    expect(
      () => db.transcriptsDao.insertWithSegmentsAndWords(
        recordingId: seeded.recordingId,
        engine: TranscriptEngines.appleDictation,
        modelVersion: 'ios',
        locale: 'de-DE',
        text: 'Kaputt.',
        segments: const [
          SegmentInput(idx: 0, startMs: 0, endMs: 100, text: 'Kaputt.'),
        ],
        words: const [
          WordInput(
            segmentIdx: 7,
            idx: 0,
            startMs: 0,
            endMs: 100,
            text: 'Kaputt',
          ),
        ],
      ),
      throwsSqlite,
    );
    await pumpEventQueue();
    expect(await countRows(db, 'transcript'), before);
    expect(await countRows(db, 'transcript_segment'), 1);
    expect(await db.searchDao.search('Kaputt'), isEmpty);
  });

  test('boundary_source lässt nur engine und vad zu', () async {
    final seeded = await seedTranscript(db, day: '2026-09-06', text: 'Eins.');
    expect(
      () => db.transcriptsDao.insertWithSegmentsAndWords(
        recordingId: seeded.recordingId,
        engine: TranscriptEngines.appleDictation,
        modelVersion: 'ios',
        locale: 'de-DE',
        text: 'Zwei.',
        segments: const [
          SegmentInput(
            idx: 0,
            startMs: 0,
            endMs: 100,
            text: 'Zwei.',
            boundarySource: 'guess',
          ),
        ],
      ),
      throwsSqlite,
    );
  });

  test('das Löschen eines Segments räumt seine Wörter ab', () async {
    final seeded = await seedTranscript(
      db,
      day: '2026-09-06',
      text: 'Guten Morgen.',
      words: const [
        WordInput(segmentIdx: 0, idx: 0, startMs: 0, endMs: 600, text: 'Guten'),
      ],
    );
    await (db.delete(
      db.transcriptSegments,
    )..where((s) => s.transcriptId.equals(seeded.transcriptId))).go();
    expect(await countRows(db, 'transcript_word'), 0);
  });

  test('updateText markiert Nutzerkorrekturen wahlweise', () async {
    final seeded = await seedTranscript(db, day: '2026-09-06', text: 'Eins.');
    expect(
      await db.transcriptsDao.updateText(
        seeded.transcriptId,
        'Zwei.',
        editedByUser: false,
      ),
      isTrue,
    );
    expect(
      (await db.transcriptsDao.getById(seeded.transcriptId))!.editedByUser,
      isFalse,
    );
    expect(
      await db.transcriptsDao.updateText(seeded.transcriptId, 'Drei.'),
      isTrue,
    );
    expect(
      (await db.transcriptsDao.getById(seeded.transcriptId))!.editedByUser,
      isTrue,
    );
    expect(await db.transcriptsDao.updateText(999, 'Nichts.'), isFalse);
  });
}
