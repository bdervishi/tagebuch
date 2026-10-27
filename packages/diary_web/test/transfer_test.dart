import 'dart:typed_data';

import 'package:diary_core/diary_core.dart';
import 'package:diary_crypto/diary_crypto.dart';
import 'package:diary_web/diary_web.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

/// Ein "Browser" mit eigener Datenbank: Master-Key, Datensätze, Dateien und
/// der Transfer-Anwendungsfall darauf.
class WebDevice {
  WebDevice._(this.db, this.store, this.files, this.useCase, this.ids);

  static Future<WebDevice> open(String dbName) async {
    final db = await openFreshDatabase(dbName);
    final keys = WebMasterKeyStore(db);
    final store = await EncryptedRecordStore.open(db, keys);
    final files = EncryptedFileStore(db, keys);
    final ids = CountingIds();
    final journal = await WebJournalRepository(store)
        .ensureDefault(defaultLocale: 'de-DE');
    final audio = WebAudioFiles(files);
    final useCase = TransferUseCase(
      journalId: journal.id,
      entries: WebEntryRepository(store, ids),
      recordings: WebRecordingRepository(store),
      transcripts: WebTranscriptRepository(store),
      notes: WebNoteRepository(store),
      settings: WebSettingsRepository(store),
      audioSource: audio,
      audioSink: audio,
      ids: ids,
      clock: const SystemClock(),
      appVersion: '0.1.0-web-test',
      argon2Params: Argon2Params.testing,
    );
    return WebDevice._(db, store, files, useCase, ids);
  }

  final IndexedDbStore db;
  final EncryptedRecordStore store;
  final EncryptedFileStore files;
  final TransferUseCase useCase;
  final CountingIds ids;

  Future<void> close() async {
    await store.close();
    db.close();
  }

  /// Legt einen Eintrag mit echter verschlüsselter Audiodatei an.
  Future<Recording> seed(LocalDay day, String text, Uint8List audio) async {
    final startedAt = day.startOfDay.add(const Duration(hours: 21));
    final entry = await useCase.entries.getOrCreate(
      useCase.journalId,
      day,
      startedAt,
    );
    final rid = ids.next();
    final written = await files.write('$rid.tgbc', audio);
    final r = Recording(
      id: rid,
      entryId: entry.id,
      startedAt: startedAt,
      duration: const Duration(seconds: 42),
      codec: AudioCodec.opus,
      container: AudioContainer.webm,
      sampleRate: 48000,
      bitrate: 32000,
      fileName: '$rid.tgbc',
      fileKeyWrapped: written.fileKeyWrapped,
      sizeBytes: written.sizeBytes,
      state: RecordingState.complete,
      waveform: Uint8ListFixture.waveform,
    );
    await useCase.recordings.insert(r);
    await useCase.transcripts.insert(
      testTranscript(id: 'tr-$rid', recordingId: rid, text: text),
    );
    return r;
  }
}

void main() {
  late WebDevice a;
  late WebDevice b;

  setUp(() async {
    a = await WebDevice.open('tagebuch-test-transfer-a');
    b = await WebDevice.open('tagebuch-test-transfer-b');
  });

  tearDown(() async {
    await a.close();
    await b.close();
  });

  Uint8List audioBytes(int seed) =>
      Uint8List.fromList(List.generate(40000, (i) => (i * seed + 3) & 0xff));

  test('Backup aus Browser A lässt sich in Browser B wiederherstellen, Audio lesbar', () async {
    const d1 = LocalDay(2026, 10, 24);
    const d2 = LocalDay(2026, 10, 26);
    await a.seed(d1, 'Erster Tag', audioBytes(5));
    await a.seed(d2, 'Zweiter Tag', audioBytes(9));
    await a.useCase.settings.set('language', 'de-AT');

    final bytes = await a.useCase.exportWithPassphrase('acht zeichen min');
    expect(bytes.length, greaterThan(80000));

    final opened = await b.useCase.openWithPassphrase(
      bytes,
      'acht zeichen min',
    );
    expect(opened.manifest.entryCount, 2);
    expect(opened.manifest.firstDay, '2026-10-24');
    expect(opened.manifest.lastDay, '2026-10-26');
    final result = await b.useCase.import(opened);
    expect(result.entriesCreated, 2);
    expect(result.recordingsImported, 2);

    final entries = await b.useCase.entries.listAll(b.useCase.journalId);
    expect(entries.map((e) => e.day), [d1, d2]);
    final recs = await b.useCase.recordings.listForEntry(entries[0].id);
    final r = recs.single;
    expect(r.state, RecordingState.complete);
    // Mit dem Master-Key von B neu gewrappt, Datei im Store von B lesbar.
    expect(await b.files.exists(r.fileName), isTrue);
    expect(await b.files.read(r.fileName, r.fileKeyWrapped), audioBytes(5));
    expect(
      (await b.useCase.transcripts.primaryForRecording(r.id))!.text,
      'Erster Tag',
    );
    expect(await b.useCase.settings.get('language'), 'de-AT');

    // Der Dateischlüssel von A öffnet die Datei in B nicht.
    final fromA = (await a.useCase.recordings.listAll()).first;
    await expectLater(
      b.files.read(r.fileName, fromA.fileKeyWrapped),
      throwsA(isA<AuthenticationException>()),
    );
  });

  test(
    'Backup mit Notizen (D17): Notizen kommen am richtigen Tag an',
    () async {
      const d1 = LocalDay(2026, 10, 24);
      const d2 = LocalDay(2026, 10, 25);
      await a.seed(d1, 'Gesprochen', audioBytes(5));
      final e1 = (await a.useCase.entries.findByDay(a.useCase.journalId, d1))!;
      final e2 = await a.useCase.entries.getOrCreate(
        a.useCase.journalId,
        d2,
        d2.startOfDay,
      );
      final at = d1.startOfDay.add(const Duration(hours: 22));
      await a.useCase.notes!.insert(
        EntryNote(
          id: 'n-good',
          entryId: e1.id,
          createdAt: at,
          updatedAt: at,
          text: 'Dankbar für den Regen.',
          promptKey: ReviewPrompts.good,
        ),
      );
      await a.useCase.notes!.insert(
        EntryNote(
          id: 'n-free',
          entryId: e2.id,
          createdAt: at.add(const Duration(days: 1)),
          updatedAt: at.add(const Duration(days: 1)),
          text: 'Nur geschrieben.',
        ),
      );

      final bytes = await a.useCase.exportWithPassphrase('acht zeichen min');
      final opened = await b.useCase.openWithPassphrase(
        bytes,
        'acht zeichen min',
      );
      expect(opened.manifest.noteCount, 2);
      final result = await b.useCase.import(opened);
      expect(result.entriesCreated, 2);
      expect(result.notesImported, 2);

      final b1 = (await b.useCase.entries.findByDay(b.useCase.journalId, d1))!;
      final b2 = (await b.useCase.entries.findByDay(b.useCase.journalId, d2))!;
      final notes1 = await b.useCase.notes!.listForEntry(b1.id);
      expect(notes1.single.text, 'Dankbar für den Regen.');
      expect(notes1.single.promptKey, 'good');
      final notes2 = await b.useCase.notes!.listForEntry(b2.id);
      expect(notes2.single.text, 'Nur geschrieben.');
      expect(await b.useCase.recordings.listForEntry(b2.id), isEmpty);
    },
  );

  test('Gerätewechsel zwischen zwei Browsern über QR-Nutzlast', () async {
    await a.seed(const LocalDay(2026, 10, 25), 'Umzug', audioBytes(7));
    final session = await b.useCase.createReceiveSession();
    final export = await a.useCase.exportForRecipient(
      QrPayloadRoundTrip.through(session.qrPayload),
    );
    expect(export.verificationCode, session.verificationCode);
    final opened = await b.useCase.openAsRecipient(export.bytes, session);
    final result = await b.useCase.import(opened);
    expect(result.recordingsImported, 1);
    final entry = (await b.useCase.entries.listAll(b.useCase.journalId)).single;
    final r = (await b.useCase.recordings.listForEntry(entry.id)).single;
    expect(await b.files.read(r.fileName, r.fileKeyWrapped), audioBytes(7));
  });

  test('BarcodeDetector-Verfügbarkeit ist abfragbar, Scanner baubar', () {
    expect(QrCameraScanner.isSupported, isA<bool>());
    final scanner = QrCameraScanner();
    expect(scanner.viewType, startsWith('tagebuch-qr-'));
  });
}

/// Simuliert den Weg über den QR-Code: Text kodieren und wieder lesen.
abstract final class QrPayloadRoundTrip {
  static QrPayload through(QrPayload p) => QrPayload.decode(p.encode());
}
