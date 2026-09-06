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

  Future<List<SearchHit>> search(
    String query, {
    bool prefix = true,
    bool primaryOnly = true,
    int? journalId,
    String? from,
    String? to,
    int? tagId,
    SearchOrder order = SearchOrder.relevance,
    int limit = 50,
  }) {
    return db.searchDao.search(
      query,
      prefix: prefix,
      primaryOnly: primaryOnly,
      journalId: journalId,
      from: from,
      to: to,
      tagId: tagId,
      order: order,
      limit: limit,
    );
  }

  Future<int> ftsRowsMatching(String term) async {
    final row = await db
        .customSelect(
          'SELECT COUNT(*) AS c FROM $ftsTableName WHERE $ftsTableName MATCH ?',
          variables: [Variable<String>('"$term"')],
        )
        .getSingle();
    return row.read<int>('c');
  }

  test(
    'ein Insert erscheint in der Suche, das Snippet markiert den Treffer',
    () async {
      final seeded = await seedTranscript(
        db,
        day: '2026-09-06',
        text: 'Heute war ich beim Zahnarzt und danach im Park.',
      );

      final hits = await search('Zahnarzt');

      expect(hits, hasLength(1));
      final hit = hits.single;
      expect(hit.entryId, seeded.entry.id);
      expect(hit.journalId, seeded.journal.id);
      expect(hit.day, '2026-09-06');
      expect(hit.recordingId, seeded.recordingId);
      expect(hit.transcriptId, seeded.transcriptId);
      expect(hit.snippet, contains('[Zahnarzt]'));
      expect(hit.score, lessThan(0));
      expect(hit.segmentIdx, 0);
      expect(hit.startMs, 0);
    },
  );

  test('ein Update des Textes spiegelt sich im Index', () async {
    final seeded = await seedTranscript(
      db,
      day: '2026-09-06',
      text: 'Termin beim Zahnarzt.',
    );

    expect(
      await db.transcriptsDao.updateText(
        seeded.transcriptId,
        'Termin beim Friseur.',
      ),
      isTrue,
    );

    expect(await search('Zahnarzt'), isEmpty);
    expect(await search('Friseur'), hasLength(1));
    expect(await ftsRowsMatching('zahnarzt'), 0);
    final transcript = (await db.transcriptsDao.getById(seeded.transcriptId))!;
    expect(transcript.content, 'Termin beim Friseur.');
    expect(transcript.editedByUser, isTrue);
  });

  test('ein Update anderer Spalten lässt den Index unberührt', () async {
    final seeded = await seedTranscript(
      db,
      day: '2026-09-06',
      text: 'Termin beim Zahnarzt.',
    );
    await db.transcriptsDao.setPrimary(seeded.transcriptId);
    expect(await search('Zahnarzt'), hasLength(1));
    expect(await ftsRowsMatching('zahnarzt'), 1);
  });

  test('ein Delete entfernt das Transkript aus dem Index', () async {
    final seeded = await seedTranscript(
      db,
      day: '2026-09-06',
      text: 'Termin beim Zahnarzt.',
    );

    expect(
      await db.transcriptsDao.deleteTranscript(seeded.transcriptId),
      isTrue,
    );

    expect(await search('Zahnarzt'), isEmpty);
    expect(await ftsRowsMatching('zahnarzt'), 0);
  });

  test('"Strasse" findet "Straße" und umgekehrt', () async {
    await seedTranscript(
      db,
      day: '2026-09-01',
      text: 'In der Straße war es laut.',
    );
    await seedTranscript(
      db,
      day: '2026-09-02',
      text: 'Die Strasse war gesperrt.',
    );
    await seedTranscript(
      db,
      day: '2026-09-03',
      text: 'GROSSE Freude, große Pläne.',
    );

    expect(
      (await search('Strasse')).map((h) => h.day),
      unorderedEquals(['2026-09-01', '2026-09-02']),
    );
    expect(
      (await search('Straße')).map((h) => h.day),
      unorderedEquals(['2026-09-01', '2026-09-02']),
    );
    expect((await search('grosse')).single.day, '2026-09-03');
    expect((await search('Große')).single.day, '2026-09-03');
    // Das Snippet zeigt den Originaltext.
    expect(
      (await search(
        'Strasse',
        from: '2026-09-01',
        to: '2026-09-01',
      )).single.snippet,
      contains('[Straße]'),
    );
  });

  test('Umlaute und Diakritika werden gefaltet', () async {
    await seedTranscript(
      db,
      day: '2026-09-06',
      text: 'Der Bär trifft Herrn Müller im Café.',
    );

    expect(await search('Bar'), hasLength(1));
    expect(await search('bär'), hasLength(1));
    expect(await search('Muller'), hasLength(1));
    expect(await search('MÜLLER'), hasLength(1));
    expect(await search('cafe'), hasLength(1));
    // Die ue-Schreibweise ist keine Diakritika-Variante und wird nicht gefaltet.
    expect(await search('Mueller'), isEmpty);
  });

  test('Präfixsuche', () async {
    await seedTranscript(
      db,
      day: '2026-09-06',
      text: 'Morgen früh zum Zahnarzt.',
    );

    expect(await search('zahn'), hasLength(1));
    expect(await search('zahn', prefix: false), isEmpty);
    expect(await search('zahn*', prefix: false), hasLength(1));
    expect(await search('Zahnarzt', prefix: false), hasLength(1));
    expect(await search('arzt'), isEmpty, reason: 'nur Präfix, kein Infix');
  });

  test('mehrere Begriffe sind UND-verknüpft', () async {
    await seedTranscript(
      db,
      day: '2026-09-01',
      text: 'Zahnarzt und dann Park.',
    );
    await seedTranscript(db, day: '2026-09-02', text: 'Nur der Park.');

    expect(await search('Park'), hasLength(2));
    expect((await search('Zahnarzt Park')).single.day, '2026-09-01');
    expect(await search('Zahnarzt Kino'), isEmpty);
  });

  test('Relevanz sortiert nach bm25, Datum wahlweise', () async {
    await seedTranscript(
      db,
      day: '2026-09-02',
      text:
          'Ich war heute nach langer Zeit endlich wieder einmal beim Zahnarzt '
          'in der Stadt, und es war halb so schlimm wie befürchtet.',
    );
    await seedTranscript(
      db,
      day: '2026-09-01',
      text: 'Zahnarzt, Zahnarzt, Zahnarzt.',
    );

    final byRelevance = await search('Zahnarzt');
    expect(byRelevance.map((h) => h.day), ['2026-09-01', '2026-09-02']);
    expect(byRelevance.first.score, lessThan(byRelevance.last.score));

    final newest = await search('Zahnarzt', order: SearchOrder.newestFirst);
    expect(newest.map((h) => h.day), ['2026-09-02', '2026-09-01']);

    final oldest = await search('Zahnarzt', order: SearchOrder.oldestFirst);
    expect(oldest.map((h) => h.day), ['2026-09-01', '2026-09-02']);
  });

  test('Filter nach Tagebuch, Zeitraum und Schlagwort', () async {
    final first = await db.journalsDao.ensureDefaultJournal();
    final second = await db
        .into(db.journals)
        .insertReturning(
          JournalsCompanion.insert(
            title: 'Zweites',
            createdAt: 1,
            defaultLocale: 'de-DE',
          ),
        );
    final august = await seedTranscript(
      db,
      day: '2026-08-15',
      text: 'Zahnarzt im August.',
      journalId: first.id,
    );
    await seedTranscript(
      db,
      day: '2026-09-06',
      text: 'Zahnarzt im September.',
      journalId: first.id,
    );
    await seedTranscript(
      db,
      day: '2026-09-06',
      text: 'Zahnarzt im zweiten Tagebuch.',
      journalId: second.id,
    );
    final tagId = await db.tagsDao.create('Gesundheit', color: 0xFF00AA00);
    await db.tagsDao.attach(august.entry.id, tagId);
    await db.tagsDao.attach(august.entry.id, tagId);

    expect(await search('Zahnarzt'), hasLength(3));
    expect(await search('Zahnarzt', journalId: first.id), hasLength(2));
    expect(await search('Zahnarzt', journalId: second.id), hasLength(1));
    expect(await search('Zahnarzt', from: '2026-09-01'), hasLength(2));
    expect(await search('Zahnarzt', to: '2026-08-31'), hasLength(1));
    expect(
      await search(
        'Zahnarzt',
        journalId: first.id,
        from: '2026-09-01',
        to: '2026-09-30',
      ),
      hasLength(1),
    );
    final tagged = await search('Zahnarzt', tagId: tagId);
    expect(tagged.single.day, '2026-08-15');
    expect(
      (await db.tagsDao.listForEntry(august.entry.id)).map((t) => t.name),
      ['Gesundheit'],
    );
    expect(await search('Zahnarzt', tagId: 999), isEmpty);
  });

  test('startMs zeigt auf das erste passende Segment', () async {
    const segments = [
      SegmentInput(idx: 0, startMs: 0, endMs: 2000, text: 'Guten Morgen.'),
      SegmentInput(
        idx: 1,
        startMs: 2000,
        endMs: 5000,
        text: 'Heute Zahnarzt in der Straße.',
        boundarySource: BoundarySources.vad,
      ),
      SegmentInput(
        idx: 2,
        startMs: 5000,
        endMs: 8000,
        text: 'Dann Zahnarzt noch mal.',
      ),
    ];
    await seedTranscript(
      db,
      day: '2026-09-06',
      text: segments.map((s) => s.text).join(' '),
      segments: segments,
    );

    final hit = (await search('zahnarzt')).single;
    expect(hit.segmentIdx, 1);
    expect(hit.startMs, 2000);

    final sharpS = (await search('strasse')).single;
    expect(sharpS.startMs, 2000);

    final last = (await search('mal')).single;
    expect(last.startMs, 5000);
  });

  test(
    'startMs ist null, wenn der Begriff nur im bearbeiteten Text steht',
    () async {
      final seeded = await seedTranscript(
        db,
        day: '2026-09-06',
        text: 'Guten Morgen.',
      );
      await db.transcriptsDao.updateText(
        seeded.transcriptId,
        'Guten Morgen beim Zahnarzt.',
      );

      final hit = (await search('Zahnarzt')).single;
      expect(hit.startMs, isNull);
      expect(hit.segmentIdx, isNull);
    },
  );

  test('Sonderzeichen und FTS-Operatoren sind ungefährlich', () async {
    await seedTranscript(
      db,
      day: '2026-09-06',
      text: 'Zahnarzt (Termin) AND NOT Park: "Zitat" 100% sicher',
    );

    for (final query in [
      '"',
      '*',
      '(',
      ')',
      'zahn OR',
      'NOT Park',
      'zahn:arzt',
      '-',
      'NEAR(',
      '"Zitat"',
      'AND',
      '^zahn',
      '   ',
      '100%',
      'Termin)',
    ]) {
      await expectLater(search(query), completes, reason: 'query "$query"');
    }
    expect(await search('"Zitat"'), hasLength(1));
    expect(
      await search('AND'),
      hasLength(1),
      reason: 'als Wort, nicht Operator',
    );
    expect(await search('NOT Park'), hasLength(1));
    expect(await search('   '), isEmpty);
    expect(await search('100'), hasLength(1));
  });

  test('primaryOnly liefert je Aufnahme nur das primäre Transkript', () async {
    final seeded = await seedTranscript(
      db,
      day: '2026-09-06',
      text: 'Zahnarzt eins.',
    );
    await db.transcriptsDao.insertWithSegmentsAndWords(
      recordingId: seeded.recordingId,
      engine: TranscriptEngines.whisperKitLargeV3,
      modelVersion: 'v3',
      locale: 'de-DE',
      text: 'Zahnarzt zwei.',
    );

    final primary = await search('Zahnarzt');
    expect(primary.single.transcriptId, seeded.transcriptId);
    expect(await search('Zahnarzt', primaryOnly: false), hasLength(2));
  });

  test(
    'rebuildSearchIndex erhält die Suche inklusive ß-Normalisierung',
    () async {
      await seedTranscript(db, day: '2026-09-06', text: 'In der Straße.');
      await seedTranscript(db, day: '2026-09-07', text: 'Beim Zahnarzt.');

      await db.rebuildSearchIndex();

      expect(await search('Strasse'), hasLength(1));
      expect(await search('Zahnarzt'), hasLength(1));
      expect(await ftsRowsMatching('strasse'), 1);
    },
  );

  test('limit begrenzt die Trefferzahl', () async {
    for (final day in ['2026-09-01', '2026-09-02', '2026-09-03']) {
      await seedTranscript(db, day: day, text: 'Zahnarzt.');
    }
    expect(await search('Zahnarzt', limit: 2), hasLength(2));
  });

  test('leere Eingabe liefert keine Treffer', () async {
    await seedTranscript(db, day: '2026-09-06', text: 'Zahnarzt.');
    expect(await search(''), isEmpty);
    expect(await search('...'), isEmpty);
  });
}
