import 'dart:typed_data';

import 'package:diary_container/diary_container.dart';
import 'package:diary_crypto/diary_crypto.dart';
import 'package:test/test.dart';

void main() {
  final rnd = SequentialRandomSource(1);
  final session = rnd.bytes(16);
  final pk = rnd.bytes(32);
  final sh = rnd.bytes(24);
  final check = rnd.bytes(8);

  test('Kopf für Gerätewechsel: Round-Trip', () {
    final h = ContainerHeader(
      keyKind: ContainerKeyKind.recipientX25519,
      cipher: ContainerCipher.secretstreamXchacha20,
      sessionId: session,
      ephemeralPublicKey: pk,
      keyCheck: check,
      streamHeader: sh,
    );
    final bytes = h.encode();
    expect(bytes.length, 4 + 3 + 16 + 32 + 8 + 1 + 24);
    final (back, used) = ContainerHeader.decode(
      Uint8List.fromList([...bytes, 9, 9, 9]),
    );
    expect(used, bytes.length);
    expect(back.keyKind, ContainerKeyKind.recipientX25519);
    expect(back.ephemeralPublicKey, pk);
    expect(back.sessionId, session);
    expect(back.keyCheck, check);
    expect(back.streamHeader, sh);
  });

  test('Kopf für Backup mit Passphrase: Parameter überleben', () {
    final salt = rnd.bytes(16);
    final h = ContainerHeader(
      keyKind: ContainerKeyKind.passphraseArgon2id,
      cipher: ContainerCipher.chunkAeadXchacha20,
      sessionId: session,
      salt: salt,
      argon2Params: Argon2Params.standard,
      keyCheck: check,
      streamHeader: sh,
    );
    final (back, _) = ContainerHeader.decode(h.encode());
    expect(back.salt, salt);
    expect(back.argon2Params!.memoryKiB, 65536);
    expect(back.argon2Params!.iterations, 3);
    expect(back.argon2Params!.parallelism, 1);
    expect(back.cipher, ContainerCipher.chunkAeadXchacha20);
  });

  test('Kopf: falsches Magic, falsche Version, abgeschnitten', () {
    final h = ContainerHeader(
      keyKind: ContainerKeyKind.recipientX25519,
      cipher: ContainerCipher.secretstreamXchacha20,
      sessionId: session,
      ephemeralPublicKey: pk,
      keyCheck: check,
      streamHeader: sh,
    ).encode();
    expect(
      () => ContainerHeader.decode(Uint8List.fromList([0, ...h.sublist(1)])),
      throwsFormatException,
    );
    final wrongVersion = Uint8List.fromList(h)..[4] = 7;
    expect(() => ContainerHeader.decode(wrongVersion), throwsFormatException);
    expect(
      () => ContainerHeader.decode(h.sublist(0, 30)),
      throwsFormatException,
    );
  });

  test('QR-Nutzlast: Round-Trip, Größe unter 200 Byte, Prüfcode stabil', () {
    final q = QrPayload(platform: 2, sessionId: session, publicKey: pk);
    final text = q.encode();
    expect(text.length, lessThan(200));
    final back = QrPayload.decode(text);
    expect(back.publicKey, pk);
    expect(back.sessionId, session);
    expect(back.platform, 2);
    expect(back.verificationCode(), q.verificationCode());
    expect(q.verificationCode(), matches(RegExp(r'^\d{6}$')));
    expect(
      () => QrPayload.decode('https://example.org'),
      throwsFormatException,
    );
  });

  test('Manifest: Round-Trip und Versionsprüfung', () {
    final m = ContainerManifest(
      createdAt: DateTime.utc(2026, 9, 6, 12),
      appVersion: '0.1.0',
      schemaVersion: 1,
      entryCount: 3,
      recordingCount: 4,
      noteCount: 5,
      goalCount: 2,
      milestoneCount: 6,
      firstDay: '2026-09-01',
      lastDay: '2026-09-03',
      files: const [
        ManifestFile(name: 'db.ndjson.gz', sizeBytes: 10, sha256Hex: 'ab'),
      ],
    );
    final back = ContainerManifest.fromJsonString(m.toJsonString());
    expect(back.entryCount, 3);
    expect(back.noteCount, 5);
    expect(back.goalCount, 2);
    expect(back.milestoneCount, 6);
    // Ältere Dateien ohne Feld `notes`: gilt als 0.
    expect(
      ContainerManifest.fromJsonString(
        m.toJsonString().replaceFirst('"notes":5,', ''),
      ).noteCount,
      0,
    );
    // Ebenso ohne `goals` und `milestones` (vor D19).
    final withoutGoals = ContainerManifest.fromJsonString(
      m.toJsonString().replaceFirst('"goals":2,"milestones":6,', ''),
    );
    expect(withoutGoals.goalCount, 0);
    expect(withoutGoals.milestoneCount, 0);
    expect(withoutGoals.noteCount, 5);
    expect(back.compression, ContainerManifest.compressionNone);
    expect(back.files.single.name, 'db.ndjson.gz');
    expect(
      () => ContainerManifest.fromJsonString('{"format":2}'),
      throwsFormatException,
    );
    expect(
      () => ContainerManifest.fromJsonString(
        m.toJsonString().replaceFirst('"none"', '"zstd"'),
      ),
      throwsFormatException,
    );
  });

  test('Rahmung: mehrere Dateien, Unicode-Namen, unvollständig erkannt', () {
    final w = FrameWriter()
      ..add('manifest.json', Uint8List.fromList('{}'.codeUnits))
      ..add(
        'audio/äöü.m4a',
        Uint8List.fromList(List.generate(300, (i) => i % 256)),
      )
      ..add('leer', Uint8List(0));
    final bytes = w.toBytes();
    final frames = FrameReader(bytes).readAll();
    expect(frames.map((f) => f.name), [
      'manifest.json',
      'audio/äöü.m4a',
      'leer',
    ]);
    expect(frames[1].data.length, 300);
    expect(frames[2].data, isEmpty);
    expect(
      () => FrameReader(bytes.sublist(0, bytes.length - 5)).readAll(),
      throwsFormatException,
    );
  });
}
