import 'package:diary_storage/diary_storage.dart';
import 'package:test/test.dart';

import 'support/fixtures.dart';

void main() {
  late DiaryDatabase db;

  setUp(() {
    db = DiaryDatabase.inMemoryForTesting();
  });

  tearDown(() => db.close());

  test('legt alle Tabellen aus docs/04 Abschnitt 4 an', () async {
    expect(
      await schemaNames(db, 'table'),
      containsAll(<String>[
        'journal',
        'entry',
        'recording',
        'transcript',
        'transcript_segment',
        'transcript_word',
        'tag',
        'entry_tag',
        'setting',
        'keyring',
        ftsTableName,
      ]),
    );
  });

  test('legt FTS-Trigger und Indizes an', () async {
    expect(await schemaNames(db, 'trigger'), containsAll(ftsTriggerNames));
    expect(
      await schemaNames(db, 'index'),
      containsAll(<String>[
        'transcript_primary_unique',
        'recording_entry',
        'transcript_recording',
        'entry_tag_tag',
      ]),
    );
  });

  test('transcript_word verweist zusammengesetzt auf das Segment', () async {
    final row = await db
        .customSelect(
          "SELECT sql FROM sqlite_master WHERE name = 'transcript_word'",
        )
        .getSingle();
    expect(
      row.read<String>('sql'),
      contains(
        'FOREIGN KEY (transcript_id, segment_idx) '
        'REFERENCES transcript_segment (transcript_id, idx) ON DELETE CASCADE',
      ),
    );
  });

  test('setzt user_version auf die aktuelle Schemaversion', () async {
    expect(
      await pragma(db, 'user_version'),
      DiaryDatabase.currentSchemaVersion,
    );
    expect(DiaryDatabase.currentSchemaVersion, 1);
  });

  test('foreign_keys und secure_delete sind eingeschaltet', () async {
    expect(await pragma(db, 'foreign_keys'), 1);
    expect(await pragma(db, 'secure_delete'), 1);
  });

  test('erzwingt genau einen Eintrag pro Tag und Tagebuch', () async {
    final journal = await db.journalsDao.ensureDefaultJournal();
    final first = await db.entriesDao.getOrCreateForDay(
      journal.id,
      '2026-09-06',
      timeZone: testTimeZone,
    );
    final again = await db.entriesDao.getOrCreateForDay(
      journal.id,
      '2026-09-06',
      timeZone: testTimeZone,
    );
    expect(again.id, first.id);

    expect(
      () => db
          .into(db.entries)
          .insert(
            EntriesCompanion.insert(
              journalId: journal.id,
              day: '2026-09-06',
              timeZone: testTimeZone,
              createdAt: 1,
              updatedAt: 1,
            ),
          ),
      throwsSqlite,
    );
    expect(await countRows(db, 'entry'), 1);
  });

  test('derselbe Tag ist in einem zweiten Tagebuch erlaubt', () async {
    final first = await db.journalsDao.ensureDefaultJournal();
    final second = await db
        .into(db.journals)
        .insertReturning(
          JournalsCompanion.insert(
            title: 'Zweites',
            createdAt: 1,
            defaultLocale: 'en-US',
          ),
        );
    final a = await db.entriesDao.getOrCreateForDay(
      first.id,
      '2026-09-06',
      timeZone: testTimeZone,
    );
    final b = await db.entriesDao.getOrCreateForDay(
      second.id,
      '2026-09-06',
      timeZone: testTimeZone,
    );
    expect(b.id, isNot(a.id));
    expect(await db.journalsDao.getAll(), hasLength(2));
  });

  test('weist Tagesangaben ab, die kein ISO-Datum sind', () {
    expect(
      () => db.entriesDao.getOrCreateForDay(
        1,
        '06.09.2026',
        timeZone: testTimeZone,
      ),
      throwsArgumentError,
    );
  });

  test('prüft Fremdschlüssel', () async {
    expect(
      () => db
          .into(db.entries)
          .insert(
            EntriesCompanion.insert(
              journalId: 999,
              day: '2026-09-06',
              timeZone: testTimeZone,
              createdAt: 1,
              updatedAt: 1,
            ),
          ),
      throwsSqlite,
    );
  });

  test('CHECK auf recording.state lässt nur bekannte Werte zu', () async {
    final journal = await db.journalsDao.ensureDefaultJournal();
    final entry = await db.entriesDao.getOrCreateForDay(
      journal.id,
      '2026-09-06',
      timeZone: testTimeZone,
    );
    expect(() => seedRecording(db, entry.id, state: 'bogus'), throwsSqlite);
    for (final state in RecordingStates.values) {
      await seedRecording(db, entry.id, state: state);
    }
    expect(await countRows(db, 'recording'), RecordingStates.values.length);
  });

  test('ensureDefaultJournal ist idempotent', () async {
    final a = await db.journalsDao.ensureDefaultJournal(nowMs: 42);
    final b = await db.journalsDao.ensureDefaultJournal(title: 'Anderes');
    expect(b.id, a.id);
    expect(b.title, 'Tagebuch');
    expect(b.createdAt, 42);
    expect(b.defaultLocale, 'de-DE');
    expect(await db.journalsDao.getAll(), hasLength(1));
  });

  test('watchEntriesInMonth liefert nur den Monat, aufsteigend', () async {
    final journal = await db.journalsDao.ensureDefaultJournal();
    for (final day in [
      '2026-09-30',
      '2026-09-01',
      '2026-10-01',
      '2026-08-31',
      '2026-12-31',
      '2027-01-01',
    ]) {
      await db.entriesDao.getOrCreateForDay(
        journal.id,
        day,
        timeZone: testTimeZone,
      );
    }
    final september = await db.entriesDao
        .watchEntriesInMonth(journal.id, 2026, 9)
        .first;
    expect(september.map((e) => e.day), ['2026-09-01', '2026-09-30']);

    final december = await db.entriesDao
        .watchEntriesInMonth(journal.id, 2026, 12)
        .first;
    expect(december.map((e) => e.day), ['2026-12-31']);

    final range = await db.entriesDao.listInRange(
      journal.id,
      '2026-09-01',
      '2026-10-01',
    );
    expect(range.map((e) => e.day), ['2026-10-01', '2026-09-30', '2026-09-01']);
  });

  test('watchEntriesInMonth meldet neue Einträge', () async {
    final journal = await db.journalsDao.ensureDefaultJournal();
    final stream = db.entriesDao.watchEntriesInMonth(journal.id, 2026, 9);
    final expectation = expectLater(
      stream.map((list) => list.length),
      emitsInOrder([0, 1]),
    );
    await pumpEventQueue();
    await db.entriesDao.getOrCreateForDay(
      journal.id,
      '2026-09-15',
      timeZone: testTimeZone,
    );
    await expectation;
  });

  test('updateTitle, updateMood und setPinned stempeln updated_at', () async {
    final journal = await db.journalsDao.ensureDefaultJournal();
    final entry = await db.entriesDao.getOrCreateForDay(
      journal.id,
      '2026-09-06',
      timeZone: testTimeZone,
      nowMs: 1000,
    );
    expect(entry.createdAt, 1000);
    expect(entry.updatedAt, 1000);
    expect(entry.pinned, isFalse);

    expect(
      await db.entriesDao.updateTitle(entry.id, 'Zahnarzt', nowMs: 2000),
      isTrue,
    );
    expect(
      await db.entriesDao.updateMood(entry.id, 'good', nowMs: 3000),
      isTrue,
    );
    expect(await db.entriesDao.setPinned(entry.id, true, nowMs: 4000), isTrue);

    final updated = (await db.entriesDao.getById(entry.id))!;
    expect(updated.title, 'Zahnarzt');
    expect(updated.mood, 'good');
    expect(updated.pinned, isTrue);
    expect(updated.createdAt, 1000);
    expect(updated.updatedAt, 4000);

    expect(
      await db.entriesDao.updateTitle(entry.id, null, nowMs: 5000),
      isTrue,
    );
    expect((await db.entriesDao.getById(entry.id))!.title, isNull);
    expect(await db.entriesDao.updateTitle(999, 'x'), isFalse);
  });

  test('eine neue Aufnahme stempelt updated_at des Eintrags', () async {
    final journal = await db.journalsDao.ensureDefaultJournal();
    final entry = await db.entriesDao.getOrCreateForDay(
      journal.id,
      '2026-09-06',
      timeZone: testTimeZone,
      nowMs: 1000,
    );
    await seedRecording(db, entry.id);
    final updated = (await db.entriesDao.getById(entry.id))!;
    expect(updated.updatedAt, greaterThan(1000));
    expect(await db.recordingsDao.listForEntry(entry.id), hasLength(1));
  });
}
