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

  test('deleteEntry löscht die Kaskade und liefert die Dateinamen', () async {
    final seeded = await seedTranscript(
      db,
      day: '2026-09-06',
      text: 'Zahnarzt am Morgen.',
      words: const [
        WordInput(
          segmentIdx: 0,
          idx: 0,
          startMs: 0,
          endMs: 500,
          text: 'Zahnarzt',
        ),
        WordInput(segmentIdx: 0, idx: 1, startMs: 500, endMs: 700, text: 'am'),
      ],
    );
    final second = await seedRecording(
      db,
      seeded.entry.id,
      fileName: 'zweite.m4a',
    );
    await db.transcriptsDao.insertWithSegmentsAndWords(
      recordingId: second,
      engine: TranscriptEngines.androidSystem,
      modelVersion: 'system',
      locale: 'de-DE',
      text: 'Zweite Aufnahme, wieder Zahnarzt.',
      segments: const [
        SegmentInput(
          idx: 0,
          startMs: 0,
          endMs: 1000,
          text: 'Zweite Aufnahme, wieder Zahnarzt.',
        ),
      ],
    );
    final shredded = await seedRecording(
      db,
      seeded.entry.id,
      fileName: 'geloescht.m4a',
    );
    expect(await db.recordingsDao.markAudioDeleted(shredded), 'geloescht.m4a');
    final tagId = await db.tagsDao.create('Gesundheit');
    await db.tagsDao.attach(seeded.entry.id, tagId);
    final other = await seedTranscript(
      db,
      day: '2026-09-07',
      text: 'Bleibt erhalten, auch mit Zahnarzt.',
    );
    await db.tagsDao.attach(other.entry.id, tagId);

    expect(await countRows(db, 'recording'), 4);
    expect(await countRows(db, 'transcript'), 3);
    expect(await countRows(db, 'transcript_word'), 2);
    expect(await countRows(db, 'entry_tag'), 2);

    final fileNames = await db.entriesDao.deleteEntry(seeded.entry.id);

    expect(
      fileNames,
      unorderedEquals([seeded.fileName, 'zweite.m4a']),
      reason: 'Audio, das schon gelöscht war, wird nicht erneut gemeldet',
    );
    expect(await db.entriesDao.getById(seeded.entry.id), isNull);
    expect(await countRows(db, 'recording'), 1);
    expect(await countRows(db, 'transcript'), 1);
    expect(await countRows(db, 'transcript_segment'), 1);
    expect(await countRows(db, 'transcript_word'), 0);
    expect(await countRows(db, 'entry_tag'), 1);
    expect(await countRows(db, 'tag'), 1, reason: 'Schlagwörter bleiben');
    expect(await countRows(db, 'entry'), 1);

    final hits = await db.searchDao.search('Zahnarzt');
    expect(hits.single.entryId, other.entry.id);
    final orphaned = await db
        .customSelect(
          'SELECT COUNT(*) AS c FROM $ftsTableName WHERE $ftsTableName MATCH ?',
          variables: [Variable<String>('zahnarzt')],
        )
        .getSingle();
    expect(orphaned.read<int>('c'), 1, reason: 'keine Leichen im FTS-Index');
    expect(await db.customSelect('PRAGMA foreign_key_check').get(), isEmpty);
  });

  test('deleteEntry ohne Eintrag liefert eine leere Liste', () async {
    expect(await db.entriesDao.deleteEntry(12345), isEmpty);
  });

  test('deleteEntry aktualisiert Streams auf Kindtabellen', () async {
    final seeded = await seedTranscript(
      db,
      day: '2026-09-06',
      text: 'Zahnarzt.',
    );
    final stream = db.recordingsDao.watchForEntry(seeded.entry.id);
    final expectation = expectLater(
      stream.map((list) => list.length),
      emitsInOrder([1, 0]),
    );
    await pumpEventQueue();
    await db.entriesDao.deleteEntry(seeded.entry.id);
    await expectation;
  });

  test('markAudioDeleted entfernt den gewrappten Dateischlüssel', () async {
    final seeded = await seedTranscript(
      db,
      day: '2026-09-06',
      text: 'Zahnarzt.',
    );
    final before = (await db.recordingsDao.getById(seeded.recordingId))!;
    expect(before.fileKeyWrapped, isNotNull);
    expect(before.state, RecordingStates.complete);

    expect(
      await db.recordingsDao.markAudioDeleted(seeded.recordingId),
      seeded.fileName,
    );

    final after = (await db.recordingsDao.getById(seeded.recordingId))!;
    expect(after.state, RecordingStates.audioDeleted);
    expect(after.fileKeyWrapped, isNull);
    expect(after.fileName, seeded.fileName);
    expect(await db.recordingsDao.markAudioDeleted(999), isNull);
    // Der Text bleibt durchsuchbar.
    expect(await db.searchDao.search('Zahnarzt'), hasLength(1));
  });

  test('Löschen eines Schlagworts entfernt die Zuordnungen', () async {
    final seeded = await seedTranscript(
      db,
      day: '2026-09-06',
      text: 'Zahnarzt.',
    );
    final tagId = await db.tagsDao.create('Gesundheit');
    await db.tagsDao.attach(seeded.entry.id, tagId);
    expect(await countRows(db, 'entry_tag'), 1);

    expect(await db.tagsDao.deleteTag(tagId), isTrue);
    expect(await countRows(db, 'entry_tag'), 0);
    expect(await db.tagsDao.getAll(), isEmpty);
    expect(await db.entriesDao.getById(seeded.entry.id), isNotNull);
  });

  test('detach entfernt genau eine Zuordnung', () async {
    final seeded = await seedTranscript(
      db,
      day: '2026-09-06',
      text: 'Zahnarzt.',
    );
    final a = await db.tagsDao.create('A');
    final b = await db.tagsDao.create('B');
    await db.tagsDao.attach(seeded.entry.id, a);
    await db.tagsDao.attach(seeded.entry.id, b);
    expect(await db.tagsDao.detach(seeded.entry.id, a), isTrue);
    expect(await db.tagsDao.detach(seeded.entry.id, a), isFalse);
    expect(
      (await db.tagsDao.listForEntry(seeded.entry.id)).map((t) => t.name),
      ['B'],
    );
  });
}
