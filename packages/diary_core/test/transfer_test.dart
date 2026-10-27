import 'dart:convert';
import 'dart:typed_data';

import 'package:diary_core/diary_core.dart';
import 'package:test/test.dart';

import 'transfer_support.dart';

void main() {
  const d1 = LocalDay(2026, 10, 25);
  const d2 = LocalDay(2026, 10, 26);

  test('Backup mit Passphrase: Round-Trip auf ein leeres Gerät', () async {
    final old = Device('alt-');
    await old.seed(d1, 'Kaffee im Park');
    await old.seed(d2, 'Regen', withAudio: false);
    await old.settings.set('language', 'de-CH');
    old.settings.reminderValue = const ReminderSettings(hour: 7, minute: 30);

    final phases = <TransferPhase>[];
    final bytes = await old.useCase.exportWithPassphrase(
      'korrektes pferd',
      onProgress: (p) => phases.add(p.phase),
    );
    expect(
      phases,
      containsAllInOrder([
        TransferPhase.collecting,
        TransferPhase.derivingKey,
        TransferPhase.encrypting,
      ]),
    );
    expect(bytes.sublist(0, 4), 'TGBX'.codeUnits);
    expect(
      TransferUseCase.backupFileName(d2),
      'tagebuch-backup-2026-10-26.tgbx',
    );

    final fresh = Device('neu-');
    expect(
      fresh.useCase.inspect(bytes).keyKind,
      ContainerKeyKind.passphraseArgon2id,
    );
    final opened = await fresh.useCase.openWithPassphrase(
      bytes,
      'korrektes pferd',
    );
    expect(opened.manifest.entryCount, 2);
    expect(opened.manifest.recordingCount, 2);
    expect(opened.manifest.firstDay, '2026-10-25');
    expect(opened.manifest.lastDay, '2026-10-26');
    expect(opened.manifest.appVersion, '0.1.0-test');
    expect(opened.payload.fileNames, ['db.ndjson', 'audio/alt-2.tgbc']);

    final result = await fresh.useCase.import(opened);
    expect(result.entriesCreated, 2);
    expect(result.entriesMerged, 0);
    expect(result.recordingsImported, 2);
    expect(result.recordingsSkipped, 0);

    final entries = await fresh.entries.listAll(Device.journalId);
    expect(entries.map((e) => e.day), [d1, d2]);
    final r1 = (await fresh.recordings.listForEntry(entries[0].id)).single;
    expect(r1.id, 'alt-2');
    expect(r1.state, RecordingState.complete);
    expect(r1.fileKeyWrapped, isNot(old.recordings.items[0].fileKeyWrapped));
    expect(r1.sizeBytes, 3100);
    expect(fresh.audio.files['alt-2.tgbc'], old.audio.files['alt-2.tgbc']);
    expect(
      (await fresh.transcripts.primaryForRecording('alt-2'))!.text,
      'Kaffee im Park',
    );
    final r2 = (await fresh.recordings.listForEntry(entries[1].id)).single;
    expect(r2.state, RecordingState.audioDeleted);
    expect(r2.fileKeyWrapped, isEmpty);
    expect(fresh.settings.values['language'], 'de-CH');
    expect(fresh.settings.reminderValue.hour, 7);
  });

  test('Falsche Passphrase und zu kurze Passphrase', () async {
    final old = Device('alt-');
    await old.seed(d1, 'x');
    final bytes = await old.useCase.exportWithPassphrase('korrektes pferd');
    await expectLater(
      Device('neu-').useCase.openWithPassphrase(bytes, 'falsches pferd'),
      throwsA(
        isA<ContainerException>().having(
          (e) => e.error,
          'error',
          ContainerError.wrongKey,
        ),
      ),
    );
    expect(() => old.useCase.exportWithPassphrase('kurz'), throwsArgumentError);
  });

  test(
    'Import führt zusammen: gleicher Tag hängt an, Kennungen nur einmal',
    () async {
      final old = Device('alt-');
      await old.seed(d1, 'Alt am 25.', recordingId: 'rec-a');
      await old.seed(d2, 'Alt am 26.', recordingId: 'rec-b');
      final bytes = await old.useCase.exportWithPassphrase('korrektes pferd');

      final target = Device('neu-');
      await target.seed(d1, 'Neu am 25.', recordingId: 'rec-n');
      await target.seed(d2, 'Schon da', recordingId: 'rec-b');
      await target.settings.set('language', 'en');
      target.settings.reminderValue = const ReminderSettings(hour: 6);

      final opened = await target.useCase.openWithPassphrase(
        bytes,
        'korrektes pferd',
      );
      final result = await target.useCase.import(opened);
      expect(result.entriesCreated, 0);
      expect(result.entriesMerged, 2);
      expect(result.recordingsImported, 1);
      expect(result.recordingsSkipped, 1);

      final e1 = (await target.entries.findByDay(Device.journalId, d1))!;
      final recs = await target.recordings.listForEntry(e1.id);
      expect(recs.map((r) => r.id), ['rec-n', 'rec-a']);
      expect(
        (await target.transcripts.primaryForRecording('rec-b'))!.text,
        'Schon da',
      );
      expect(target.entries.items.length, 2);
      // Vorhandene Einstellungen bleiben.
      expect(target.settings.values['language'], 'en');
      expect(target.settings.reminderValue.hour, 6);

      // Nochmal importieren ändert nichts mehr.
      final again = await target.useCase.import(opened);
      expect(again.recordingsImported, 0);
      expect(again.recordingsSkipped, 2);
    },
  );

  test(
    'Gerätewechsel: QR vom neuen Gerät, Datei vom alten, Prüfcode gleich',
    () async {
      final newDevice = Device('neu-');
      final session = await newDevice.useCase.createReceiveSession(platform: 2);
      final qrText = session.qrPayload.encode();
      expect(qrText, startsWith('tgb1:'));

      // Sitzung überlebt als JSON (verschlüsselt im SettingsRepository).
      final restored = ReceiveSession.fromJson(
        jsonDecode(jsonEncode(session.toJson())) as Map<String, Object?>,
      );
      expect(restored.sessionId, session.sessionId);
      expect(restored.verificationCode, session.verificationCode);

      final old = Device('alt-');
      await old.seed(d1, 'Übertragen');
      final export = await old.useCase.exportForRecipient(
        QrPayload.decode(qrText),
      );
      expect(export.verificationCode, session.verificationCode);
      expect(
        newDevice.useCase.inspect(export.bytes).keyKind,
        ContainerKeyKind.recipientX25519,
      );

      final opened = await newDevice.useCase.openAsRecipient(
        export.bytes,
        restored,
      );
      expect(opened.snapshot.entries.single.day, d1);
      final result = await newDevice.useCase.import(opened);
      expect(result.recordingsImported, 1);
      expect(
        (await newDevice.transcripts.primaryForRecording('alt-2'))!.text,
        'Übertragen',
      );

      // Eine andere Sitzung (anderer QR-Code) kommt nicht hinein.
      final other = await newDevice.useCase.createReceiveSession();
      await expectLater(
        newDevice.useCase.openAsRecipient(export.bytes, other),
        throwsA(
          isA<ContainerException>().having(
            (e) => e.error,
            'error',
            ContainerError.wrongSession,
          ),
        ),
      );
      // Backup-Datei als Gerätewechsel öffnen und umgekehrt: klare Meldung.
      final backup = await old.useCase.exportWithPassphrase('korrektes pferd');
      await expectLater(
        newDevice.useCase.openAsRecipient(backup, session),
        throwsA(isA<ContainerException>()),
      );
      await expectLater(
        newDevice.useCase.openWithPassphrase(export.bytes, 'korrektes pferd'),
        throwsA(isA<ContainerException>()),
      );
    },
  );

  test(
    'Abgeschnittene Datei und fremde Datei: Fehlerart unterscheidbar',
    () async {
      final old = Device('alt-');
      await old.seed(d1, 'x');
      final bytes = await old.useCase.exportWithPassphrase('korrektes pferd');
      await expectLater(
        Device('neu-').useCase.openWithPassphrase(
          bytes.sublist(0, bytes.length - 30),
          'korrektes pferd',
        ),
        throwsA(
          isA<ContainerException>().having(
            (e) => e.error,
            'error',
            ContainerError.truncated,
          ),
        ),
      );
      expect(
        () =>
            Device('neu-').useCase
                .inspect(Uint8List.fromList('PK\x03\x04 zip'.codeUnits)),
        throwsA(
          isA<ContainerException>().having(
            (e) => e.error,
            'error',
            ContainerError.notContainer,
          ),
        ),
      );
    },
  );

  test(
    'Notizen (D17): Export zählt sie, Import hängt sie an den Tag',
    () async {
      final old = Device('alt-');
      await old.seed(d1, 'Gesprochen am 25.');
      await old.seedNote(d1, 'Dankbar für den Kaffee.', promptKey: 'good');
      await old.seedNote(d2, 'Nur geschrieben, keine Aufnahme.');
      await old.seedNote(d2, '1', promptKey: 'next_done');
      final bytes = await old.useCase.exportWithPassphrase('korrektes pferd');

      final fresh = Device('neu-');
      final opened = await fresh.useCase.openWithPassphrase(
        bytes,
        'korrektes pferd',
      );
      expect(opened.manifest.entryCount, 2);
      expect(opened.manifest.recordingCount, 1);
      expect(opened.manifest.noteCount, 3);
      expect(opened.snapshot.notes, hasLength(3));
      final result = await fresh.useCase.import(opened);
      expect(result.entriesCreated, 2);
      expect(result.notesImported, 3);
      expect(result.notesSkipped, 0);

      // Der zweite Tag existiert nur durch Notizen.
      final e2 = (await fresh.entries.findByDay(Device.journalId, d2))!;
      expect(await fresh.recordings.listForEntry(e2.id), isEmpty);
      final n2 = await fresh.notes.listForEntry(e2.id);
      expect(n2.map((n) => n.text), ['Nur geschrieben, keine Aufnahme.', '1']);
      expect(n2.last.promptKey, 'next_done');
      expect(n2.first.source, NoteSource.typed);
      // Notizen hängen am Eintrag des Zielgeräts, nicht an der alten Kennung.
      final e1 = (await fresh.entries.findByDay(Device.journalId, d1))!;
      final n1 = (await fresh.notes.listForEntry(e1.id)).single;
      expect(n1.entryId, e1.id);
      expect(n1.promptKey, 'good');

      // Nochmal: Kennungen bleiben einmalig.
      final again = await fresh.useCase.import(opened);
      expect(again.notesImported, 0);
      expect(again.notesSkipped, 3);

      // Ein Gerät ohne Notiz-Speicher importiert den Rest trotzdem.
      final plain = Device('ohne-', withNotes: false);
      final r = await plain.useCase.import(
        await plain.useCase.openWithPassphrase(bytes, 'korrektes pferd'),
      );
      expect(r.entriesCreated, 2);
      expect(r.notesImported, 0);
    },
  );

  test(
    'Ziele und Etappen (D19): Export zählt sie, Import übernimmt sie',
    () async {
      final old = Device('alt-');
      await old.seed(d1, 'Gesprochen am 25.');
      final useCase = GoalsUseCase(
        journalId: Device.journalId,
        goals: old.goals,
        ids: old.ids,
        clock: old.clock,
      );
      final g = await useCase.createGoal(
        title: 'Lesen',
        why: 'Ruhe am Abend.',
        milestoneTitles: ['Buch aussuchen', 'Kapitel 1'],
      );
      final done = await useCase.createGoal(title: 'Fertig');
      await useCase.completeGoal(done.id);
      final ms = await old.goals.listMilestones(g.id);
      await useCase.setMilestoneDone(ms.first.id, true);
      // Der Schritt für morgen hängt am Ziel; das Häkchen trägt die Etappe.
      await old.seedNote(
        d1,
        'Wenn ich heimkomme, dann lesen.',
        promptKey: 'next',
        goalId: g.id,
      );
      final step = await useCase.addDoneMilestone(g.id, 'Gelesen.');
      await old.seedNote(
        d2,
        StepDoneMark(milestoneId: step!.id).encode(),
        promptKey: 'next_done',
      );
      final bytes = await old.useCase.exportWithPassphrase('korrektes pferd');

      final fresh = Device('neu-');
      final opened = await fresh.useCase.openWithPassphrase(
        bytes,
        'korrektes pferd',
      );
      expect(opened.manifest.goalCount, 2);
      expect(opened.manifest.milestoneCount, 3);
      expect(opened.snapshot.goals, hasLength(2));
      expect(opened.snapshot.milestones, hasLength(3));
      final result = await fresh.useCase.import(opened);
      expect(result.goalsImported, 2);
      expect(result.milestonesImported, 3);
      expect(result.goalsSkipped, 0);
      expect(result.milestonesSkipped, 0);

      final imported = (await fresh.goals.goalById(g.id))!;
      expect(imported.title, 'Lesen');
      expect(imported.why, 'Ruhe am Abend.');
      expect(imported.isActive, isTrue);
      expect((await fresh.goals.goalById(done.id))!.isActive, isFalse);
      final importedMs = await fresh.goals.listMilestones(g.id);
      expect(importedMs.map((m) => m.title), [
        'Buch aussuchen',
        'Kapitel 1',
        'Gelesen.',
      ]);
      expect(importedMs.first.isDone, isTrue);
      expect(importedMs[1].isDone, isFalse);
      // Die Zuordnung der Notiz und die Etappen-Kennung im Häkchen bleiben.
      final e1 = (await fresh.entries.findByDay(Device.journalId, d1))!;
      final next = (await fresh.notes.listForEntry(e1.id)).single;
      expect(next.goalId, g.id);
      final e2 = (await fresh.entries.findByDay(Device.journalId, d2))!;
      final mark = (await fresh.notes.listForEntry(e2.id)).single;
      expect(StepDoneMark.parse(mark.text).milestoneId, step.id);

      // Nochmal: Kennungen bleiben einmalig.
      final again = await fresh.useCase.import(opened);
      expect(again.goalsImported, 0);
      expect(again.goalsSkipped, 2);
      expect(again.milestonesImported, 0);
      expect(again.milestonesSkipped, 3);

      // Ein Gerät ohne Ziel-Speicher importiert den Rest trotzdem.
      final plain = Device('ohne-', withGoals: false);
      final r = await plain.useCase.import(
        await plain.useCase.openWithPassphrase(bytes, 'korrektes pferd'),
      );
      expect(r.entriesCreated, 2);
      expect(r.goalsImported, 0);
    },
  );

  test('Import: Etappe ohne ihr Ziel wird übersprungen', () async {
    final snap = TransferSnapshot.decodeNdjson(
      '{"type":"goal","id":"g1","journalId":"j","title":"A",'
      '"createdAt":"2026-10-25T19:00:00.000Z",'
      '"updatedAt":"2026-10-25T19:00:00.000Z","sortIndex":0}\n'
      '{"type":"milestone","id":"m1","goalId":"g1","title":"a",'
      '"sortIndex":0,"createdAt":"2026-10-25T19:00:00.000Z"}\n'
      '{"type":"milestone","id":"m2","goalId":"fehlt","title":"b",'
      '"sortIndex":0,"createdAt":"2026-10-25T19:00:00.000Z"}\n',
    );
    expect(snap.goals.single.id, 'g1');
    expect(snap.milestones, hasLength(2));
    // Kopf und Nutzlast eines leeren Exports, der Inhalt aus den Zeilen oben.
    final device = Device('x-');
    final empty = await device.useCase.openWithPassphrase(
      await device.useCase.exportWithPassphrase('korrektes pferd'),
      'korrektes pferd',
    );
    final result = await device.useCase.import(
      OpenedContainer(
        header: empty.header,
        payload: empty.payload,
        snapshot: snap,
      ),
    );
    expect(result.goalsImported, 1);
    expect(result.milestonesImported, 1);
    expect(result.milestonesSkipped, 1);
    expect((await device.goals.listMilestones('g1')).single.id, 'm1');
    // Das Ziel gehört jetzt zum Tagebuch des Zielgeräts.
    expect((await device.goals.goalById('g1'))!.journalId, Device.journalId);
  });

  test(
    'Bücher und Passagen (D21): Export zählt sie, Import übernimmt sie',
    () async {
      final old = Device('alt-');
      await old.seed(d1, 'Gesprochen am 25.');
      final useCase = BooksUseCase(
        journalId: Device.journalId,
        books: old.books,
        ids: old.ids,
        clock: old.clock,
      );
      final book = await useCase.addBook(
        title: 'Der Sommer der Bücher',
        author: 'Anna Beispiel',
      );
      final done = await useCase.addBook(
        title: 'Fertig gelesen',
        status: BookStatus.finished,
      );
      final p1 = await useCase.addPassage(
        book.id,
        text: 'Ein Satz, der bleibt.',
        page: 'S. 42',
        thought: 'Erinnert mich an den Sommer.',
      );
      final p2 = await useCase.addPassage(book.id, text: 'Zweite Stelle.');
      expect(p1, isNotNull);
      expect(p2, isNotNull);

      final bytes = await old.useCase.exportWithPassphrase('korrektes pferd');
      final fresh = Device('neu-');
      final opened = await fresh.useCase.openWithPassphrase(
        bytes,
        'korrektes pferd',
      );
      expect(opened.manifest.bookCount, 2);
      expect(opened.manifest.passageCount, 2);
      expect(opened.snapshot.books, hasLength(2));
      expect(opened.snapshot.passages, hasLength(2));
      final result = await fresh.useCase.import(opened);
      expect(result.booksImported, 2);
      expect(result.passagesImported, 2);
      expect(result.booksSkipped, 0);
      expect(result.passagesSkipped, 0);

      final imported = (await fresh.books.bookById(book.id))!;
      expect(imported.title, 'Der Sommer der Bücher');
      expect(imported.author, 'Anna Beispiel');
      expect(imported.status, BookStatus.reading);
      expect(imported.journalId, Device.journalId);
      final importedDone = (await fresh.books.bookById(done.id))!;
      expect(importedDone.status, BookStatus.finished);
      expect(importedDone.finishedAt, done.finishedAt);
      final passages = await fresh.books.listPassages(book.id);
      expect(passages.map((p) => p.text), [
        'Ein Satz, der bleibt.',
        'Zweite Stelle.',
      ]);
      expect(passages.first.page, 'S. 42');
      expect(passages.first.thought, 'Erinnert mich an den Sommer.');
      expect(passages.first.day, p1!.day);

      // Nochmal: Kennungen bleiben einmalig.
      final again = await fresh.useCase.import(opened);
      expect(again.booksImported, 0);
      expect(again.booksSkipped, 2);
      expect(again.passagesImported, 0);
      expect(again.passagesSkipped, 2);

      // Ein Gerät ohne Bücher-Speicher importiert den Rest trotzdem.
      final plain = Device('ohne-', withBooks: false);
      final r = await plain.useCase.import(
        await plain.useCase.openWithPassphrase(bytes, 'korrektes pferd'),
      );
      expect(r.entriesCreated, 1);
      expect(r.booksImported, 0);
    },
  );

  test('Import: Passage ohne ihr Buch wird übersprungen', () async {
    final snap = TransferSnapshot.decodeNdjson(
      '{"type":"book","id":"b1","journalId":"j","title":"A",'
      '"status":"planned","createdAt":"2026-10-25T19:00:00.000Z",'
      '"updatedAt":"2026-10-25T19:00:00.000Z"}\n'
      '{"type":"passage","id":"p1","bookId":"b1","text":"a",'
      '"day":"2026-10-25","createdAt":"2026-10-25T19:00:00.000Z",'
      '"updatedAt":"2026-10-25T19:00:00.000Z"}\n'
      '{"type":"passage","id":"p2","bookId":"fehlt","text":"b",'
      '"day":"2026-10-25","createdAt":"2026-10-25T19:00:00.000Z",'
      '"updatedAt":"2026-10-25T19:00:00.000Z"}\n',
    );
    expect(snap.books.single.id, 'b1');
    expect(snap.books.single.status, BookStatus.planned);
    expect(snap.passages, hasLength(2));
    final device = Device('x-');
    final empty = await device.useCase.openWithPassphrase(
      await device.useCase.exportWithPassphrase('korrektes pferd'),
      'korrektes pferd',
    );
    final result = await device.useCase.import(
      OpenedContainer(
        header: empty.header,
        payload: empty.payload,
        snapshot: snap,
      ),
    );
    expect(result.booksImported, 1);
    expect(result.passagesImported, 1);
    expect(result.passagesSkipped, 1);
    expect((await device.books.listPassages('b1')).single.id, 'p1');
    expect((await device.books.bookById('b1'))!.journalId, Device.journalId);
  });

  test('NDJSON ohne Notizen (ältere Datei) bleibt lesbar', () {
    final snap = TransferSnapshot.decodeNdjson(
      '{"type":"entry","id":"e1","journalId":"j","day":"2026-10-25",'
      '"createdAt":"2026-10-25T19:00:00.000Z",'
      '"updatedAt":"2026-10-25T19:00:00.000Z"}\n',
    );
    expect(snap.entries.single.id, 'e1');
    expect(snap.notes, isEmpty);
    expect(snap.goals, isEmpty);
    expect(snap.milestones, isEmpty);
    expect(snap.books, isEmpty);
    expect(snap.passages, isEmpty);
  });

  test('NDJSON: unbekannte Typen werden übersprungen, Reihenfolge stabil', () {
    final snap = TransferSnapshot.decodeNdjson(
      '{"type":"future-thing","x":1}\n'
      '{"type":"setting","key":"a","value":"b"}\n'
      '\n'
      '{"type":"reminder","hour":8,"minute":15}\n',
    );
    expect(snap.entries, isEmpty);
    expect(snap.settings, {'a': 'b'});
    expect(snap.reminder!.hour, 8);
    expect(snap.firstDay, isNull);
    expect(TransferSnapshot.schemaVersion, 1);
  });
}
