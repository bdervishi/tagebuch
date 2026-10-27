import 'package:diary_core/diary_core.dart';
import 'package:diary_web/diary_web.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

void main() {
  const dbName = 'tagebuch-test-repos';
  late IndexedDbStore db;
  late EncryptedRecordStore store;
  late WebJournalRepository journals;
  late WebEntryRepository entries;
  late WebRecordingRepository recordings;
  late WebTranscriptRepository transcripts;
  late WebNoteRepository notes;
  late WebSettingsRepository settings;
  late WebSearchRepository search;
  const journalId = WebJournalRepository.defaultId;

  setUp(() async {
    db = await openFreshDatabase(dbName);
    store = await EncryptedRecordStore.open(db, WebMasterKeyStore(db));
    journals = WebJournalRepository(store);
    entries = WebEntryRepository(store, CountingIds());
    recordings = WebRecordingRepository(store);
    transcripts = WebTranscriptRepository(store);
    notes = WebNoteRepository(store);
    settings = WebSettingsRepository(store);
    search = WebSearchRepository(store);
  });

  tearDown(() async {
    await search.dispose();
    await store.close();
    db.close();
  });

  /// Legt Eintrag, Aufnahme und Transkript für einen Tag an.
  Future<DiaryEntry> seed(
    LocalDay day,
    String text, {
    List<String>? segments,
  }) async {
    final e = await entries.getOrCreate(
      journalId,
      day,
      day.startOfDay.add(const Duration(hours: 21)),
    );
    final rid = 'rec-${e.id}';
    await recordings.insert(
      testRecording(
        id: rid,
        entryId: e.id,
        startedAt: day.startOfDay.add(const Duration(hours: 21)),
      ),
    );
    await transcripts.insert(
      testTranscript(
        id: 'tr-$rid',
        recordingId: rid,
        text: text,
        segments: segments,
      ),
    );
    return e;
  }

  test('Standardtagebuch entsteht einmal', () async {
    final a = await journals.ensureDefault(defaultLocale: 'de-DE');
    final b = await journals.ensureDefault(defaultLocale: 'en-US');
    expect(a.id, journalId);
    expect(b.defaultLocale, 'de-DE');
  });

  test('ein Eintrag je Tag, Aufnahmen und Transkripte hängen daran', () async {
    final day = LocalDay(2026, 9, 6);
    final e1 = await seed(day, 'Kaffee im Park');
    final e2 = await entries.getOrCreate(journalId, day, DateTime(2026, 9, 6));
    expect(e2.id, e1.id);
    expect((await entries.findByDay(journalId, day))?.id, e1.id);
    expect(await entries.findByDay(journalId, day.next), isNull);
    final recs = await recordings.listForEntry(e1.id);
    expect(recs, hasLength(1));
    expect(recs.single.waveform, Uint8ListFixture.waveform);
    expect(recs.single.fileKeyWrapped, Uint8ListFixture.wrapped);
    final t = await transcripts.primaryForRecording(recs.single.id);
    expect(t?.text, 'Kaffee im Park');
    expect(t?.segments.single.end, const Duration(seconds: 5));

    await transcripts.updateText(t!.id, 'Tee im Park', editedByUser: true);
    final edited = await transcripts.primaryForRecording(recs.single.id);
    expect(edited?.text, 'Tee im Park');
    expect(edited?.editedByUser, isTrue);

    await entries.update(e1.copyWith(title: 'Sonntag', pinned: true));
    final updated = await entries.byId(e1.id);
    expect(updated?.title, 'Sonntag');
    expect(updated?.pinned, isTrue);
  });

  test('Monat: watchMonth liefert Stand und Änderungen', () async {
    await seed(LocalDay(2026, 9, 6), 'a');
    await seed(LocalDay(2026, 9, 21), 'b');
    await seed(LocalDay(2026, 8, 30), 'c');
    final stream = entries.watchMonth(journalId, 2026, 9);
    final first = await stream.first;
    expect(first.map((e) => e.day.day), [21, 6]);

    final updates = <List<DiaryEntry>>[];
    final sub = entries.watchMonth(journalId, 2026, 9).listen(updates.add);
    await Future<void>.delayed(Duration.zero);
    await seed(LocalDay(2026, 9, 10), 'd');
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(updates.last.map((e) => e.day.day), [21, 10, 6]);
    await sub.cancel();
  });

  test(
    'delete entfernt Eintrag samt Aufnahmen und liefert Dateinamen',
    () async {
      final e = await seed(LocalDay(2026, 9, 6), 'weg damit');
      final rid = (await recordings.listForEntry(e.id)).single.id;
      final files = await entries.delete(e.id);
      expect(files, ['$rid.tgbc']);
      expect(await entries.byId(e.id), isNull);
      expect(await recordings.listForEntry(e.id), isEmpty);
      expect(await transcripts.primaryForRecording(rid), isNull);
    },
  );

  test('Notizen (D17): anlegen, ändern, auflisten, löschen', () async {
    final day = LocalDay(2026, 10, 27);
    final e = await entries.getOrCreate(journalId, day, DateTime(2026, 10, 27));
    final n1 = EntryNote(
      id: 'n1',
      entryId: e.id,
      createdAt: DateTime(2026, 10, 27, 21, 1),
      updatedAt: DateTime(2026, 10, 27, 21, 1),
      text: 'Dankbar für den Kaffee.',
      promptKey: ReviewPrompts.good,
    );
    final n0 = EntryNote(
      id: 'n0',
      entryId: e.id,
      createdAt: DateTime(2026, 10, 27, 20, 50),
      updatedAt: DateTime(2026, 10, 27, 20, 50),
      text: 'Frei geschrieben.',
    );
    await notes.insert(n1);
    await notes.insert(n0);
    expect(await notes.listForEntry('fremd'), isEmpty);
    final list = await notes.listForEntry(e.id);
    expect(list.map((n) => n.id), ['n0', 'n1']);
    expect(list.last.promptKey, 'good');
    expect(list.last.source, NoteSource.typed);

    await notes.update(
      n1.copyWith(text: 'Kaffee und Sonne.', updatedAt: DateTime(2026, 10, 28)),
    );
    final updated = (await notes.listForEntry(e.id)).last;
    expect(updated.text, 'Kaffee und Sonne.');
    expect(updated.updatedAt, DateTime(2026, 10, 28));
    expect(updated.createdAt, n1.createdAt);

    await notes.delete('n0');
    expect((await notes.listForEntry(e.id)).map((n) => n.id), ['n1']);

    // Eintrag löschen nimmt die Notizen mit.
    await entries.delete(e.id);
    expect(await notes.listForEntry(e.id), isEmpty);
    expect(await store.getAllKeys(Collections.notes), isEmpty);
  });

  test('Aufnahme löschen und Audio löschen', () async {
    final e = await seed(LocalDay(2026, 9, 6), 'x');
    final rec = (await recordings.listForEntry(e.id)).single;
    await recordings.markAudioDeleted(rec.id);
    final marked = (await recordings.listForEntry(e.id)).single;
    expect(marked.state, RecordingState.audioDeleted);
    expect(marked.fileKeyWrapped, isEmpty);
    expect(await recordings.delete(rec.id), rec.fileName);
    expect(await recordings.delete(rec.id), isNull);
    expect(await transcripts.primaryForRecording(rec.id), isNull);
    expect(await entries.byId(e.id), isNotNull);
  });

  test('Einstellungen: Erinnerung und freie Schlüssel', () async {
    expect((await settings.reminder()).hour, 21);
    await settings.saveReminder(
      const ReminderSettings(
        hour: 7,
        minute: 30,
        enabled: false,
        weekdays: {1, 3},
        pausedUntil: LocalDay(2026, 12, 24),
      ),
    );
    final r = await settings.reminder();
    expect(r.hour, 7);
    expect(r.minute, 30);
    expect(r.enabled, isFalse);
    expect(r.weekdays, {1, 3});
    expect(r.pausedUntil, LocalDay(2026, 12, 24));
    expect(await settings.get('language'), isNull);
    await settings.set('language', 'de-CH');
    expect(await settings.get('language'), 'de-CH');
  });

  test(
    'Suche: Strasse findet Straße, Treffer mit Tag und Sprungziel',
    () async {
      final e1 = await seed(
        LocalDay(2026, 9, 6),
        'Heute Kaffee im Park. Dann über die Straße zum Bäcker.',
        segments: ['Heute Kaffee im Park.', 'Dann über die Straße zum Bäcker.'],
      );
      await seed(LocalDay(2026, 9, 21), 'Regen, Buch, früh ins Bett.');
      await seed(LocalDay(2026, 8, 30), 'Café mit Ökonomie-Vortrag.');

      final hits = await search.search('Strasse');
      expect(hits, hasLength(1));
      expect(hits.single.entryId, e1.id);
      expect(hits.single.day, LocalDay(2026, 9, 6));
      expect(hits.single.jumpTo, const Duration(seconds: 5));
      expect(hits.single.snippet, contains('Straße'));

      expect((await search.search('STRASSE bäcker')).single.entryId, e1.id);
      expect(await search.search('strasse regen'), isEmpty);
      expect((await search.search('cafe')).single.day, LocalDay(2026, 8, 30));
      expect(
        (await search.search('okonomie')).single.day,
        LocalDay(2026, 8, 30),
      );
      expect(await search.search('   '), isEmpty);

      // Neueste zuerst, Zeitraum filtert.
      final all = await search.search('e');
      expect(all.map((h) => h.day.iso), [
        '2026-09-21',
        '2026-09-06',
        '2026-08-30',
      ]);
      final sept = await search.search('e', from: LocalDay(2026, 9, 1));
      expect(sept, hasLength(2));

      // Änderungen machen den Index ungültig.
      await entries.delete(e1.id);
      expect(await search.search('strasse'), isEmpty);
    },
  );

  test('Suche findet Notizen ohne Sprungziel, interne Notizen nicht', () async {
    final e = await seed(LocalDay(2026, 10, 27), 'Gesprochen: Spaziergang.');
    final at = DateTime(2026, 10, 27, 21);
    await notes.insert(
      EntryNote(
        id: 'n1',
        entryId: e.id,
        createdAt: at,
        updatedAt: at,
        text: 'Geschrieben: Dankbar für die Straßenbahn.',
        promptKey: ReviewPrompts.good,
      ),
    );
    await notes.insert(
      EntryNote(
        id: 'n2',
        entryId: e.id,
        createdAt: at,
        updatedAt: at,
        text: '{"recordingId":"rec-x","marks":[]}',
        promptKey: ReviewPrompts.promptsAt,
      ),
    );
    final hits = await search.search('strassenbahn');
    expect(hits, hasLength(1));
    expect(hits.single.entryId, e.id);
    expect(hits.single.recordingId, isNull);
    expect(hits.single.jumpTo, isNull);
    expect(hits.single.snippet, contains('Straßenbahn'));
    expect(await search.search('recordingId'), isEmpty);
    final spoken = await search.search('spaziergang');
    expect(spoken.single.recordingId, isNotNull);
    expect(spoken.single.jumpTo, Duration.zero);
  });
}
