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
