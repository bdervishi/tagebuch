import 'dart:convert';
import 'dart:typed_data';

import 'package:diary_container/diary_container.dart';
import 'package:diary_crypto/diary_crypto.dart';
import 'package:test/test.dart';

/// Baut einen kleinen Container mit Manifest, Datenbank-Export und zwei
/// Audiodateien; [messageSize] klein, damit mehrere Nachrichten entstehen.
Future<Uint8List> buildContainer({
  required Uint8List key,
  required ContainerHeader Function(Uint8List streamHeader) header,
  int messageSize = 1000,
  RandomSource? random,
}) async {
  final out = BytesBuilder(copy: false);
  final writer = await ContainerWriter.start(
    cipherFactory: ChunkAeadStreamCipherFactory(random: random),
    key: key,
    header: header,
    sink: out.add,
    messageSize: messageSize,
  );
  final builder = ContainerPayloadBuilder(
    createdAt: DateTime.utc(2026, 10, 27, 20),
    appVersion: '0.1.0',
    schemaVersion: 1,
    entryCount: 2,
    recordingCount: 2,
    firstDay: '2026-10-25',
    lastDay: '2026-10-26',
  );
  await builder.add(
    ContainerPayload.databaseName,
    Uint8List.fromList(utf8.encode('{"type":"entry","id":"a"}\n')),
  );
  await builder.add(
    'audio/a.tgbc',
    Uint8List.fromList(List.generate(2500, (i) => (i * 7) & 0xff)),
  );
  await builder.add('audio/b.tgbc', Uint8List(0));
  await builder.writeTo(writer);
  return out.toBytes();
}

void main() {
  const keys = ContainerKeys();
  final rnd = SecureRandomSource();
  final sessionId = rnd.bytes(16);
  final factory = ChunkAeadStreamCipherFactory();

  group('Stromverschlüsselung (Kennung 2)', () {
    final key = rnd.bytes(32);
    final aad = Uint8List.fromList('kopf'.codeUnits);

    test('Round-Trip über mehrere Nachrichten, Final erkannt', () async {
      final enc = await factory.encryptor(key);
      final m1 = await enc.push(
        Uint8List.fromList([1, 2, 3]),
        isFinal: false,
        aad: aad,
      );
      final m2 = await enc.push(Uint8List(0), isFinal: false, aad: aad);
      final m3 = await enc.push(
        Uint8List.fromList([9]),
        isFinal: true,
        aad: aad,
      );
      expect(() => enc.push(Uint8List(1), isFinal: true), throwsStateError);

      final dec = await factory.decryptor(key, enc.header);
      final (c1, f1) = await dec.pull(m1, aad: aad);
      expect(c1, [1, 2, 3]);
      expect(f1, isFalse);
      final (c2, f2) = await dec.pull(m2, aad: aad);
      expect(c2, isEmpty);
      expect(f2, isFalse);
      final (c3, f3) = await dec.pull(m3, aad: aad);
      expect(c3, [9]);
      expect(f3, isTrue);
      await expectLater(
        dec.pull(m3, aad: aad),
        throwsA(isA<AuthenticationException>()),
      );
    });

    test(
      'Umsortieren, Auslassen, Manipulation und Tag-Wechsel scheitern',
      () async {
        final enc = await factory.encryptor(key);
        final m1 = await enc.push(
          Uint8List.fromList([1]),
          isFinal: false,
          aad: aad,
        );
        final m2 = await enc.push(
          Uint8List.fromList([2]),
          isFinal: false,
          aad: aad,
        );
        final m3 = await enc.push(
          Uint8List.fromList([3]),
          isFinal: true,
          aad: aad,
        );

        // Umsortiert
        var dec = await factory.decryptor(key, enc.header);
        await expectLater(
          dec.pull(m2, aad: aad),
          throwsA(isA<AuthenticationException>()),
        );
        // Ausgelassen
        dec = await factory.decryptor(key, enc.header);
        await dec.pull(m1, aad: aad);
        await expectLater(
          dec.pull(m3, aad: aad),
          throwsA(isA<AuthenticationException>()),
        );
        // Manipuliert
        dec = await factory.decryptor(key, enc.header);
        final broken = Uint8List.fromList(m1)..[5] ^= 0x01;
        await expectLater(
          dec.pull(broken, aad: aad),
          throwsA(isA<AuthenticationException>()),
        );
        // Final-Tag entfernt (Abschneiden verschleiern)
        dec = await factory.decryptor(key, enc.header);
        await dec.pull(m1, aad: aad);
        await dec.pull(m2, aad: aad);
        final notFinal = Uint8List.fromList(m3)..[0] = 0;
        await expectLater(
          dec.pull(notFinal, aad: aad),
          throwsA(isA<AuthenticationException>()),
        );
        // Andere Zusatzdaten (anderer Kopf)
        dec = await factory.decryptor(key, enc.header);
        await expectLater(
          dec.pull(m1, aad: Uint8List.fromList('anderer'.codeUnits)),
          throwsA(isA<AuthenticationException>()),
        );
      },
    );

    test('Nonce = Header XOR Zähler in den letzten 8 Byte', () {
      final header = Uint8List(24)..[23] = 0x0f;
      final n = ChunkAeadStreamCipherFactory.nonceFor(header, 0x1_0000_0001);
      expect(n.sublist(0, 16), header.sublist(0, 16));
      expect(n[23], 0x0e);
      expect(n[19], 0x01);
      final a = ChunkAeadStreamCipherFactory.aadFor(
        Uint8List.fromList([7]),
        2,
        1,
      );
      expect(a, [7, 0, 0, 0, 0, 0, 0, 0, 2, 1]);
    });
  });

  group('Container mit Passphrase', () {
    final salt = rnd.bytes(16);
    const params = Argon2Params.testing;
    late Uint8List key;
    late Uint8List file;

    setUpAll(() async {
      key = await keys.fromPassphrase(
        passphrase: 'korrekt horse batterie',
        salt: salt,
        params: params,
      );
      final check = await keys.keyCheck(key, sessionId);
      file = await buildContainer(
        key: key,
        header: (sh) => ContainerHeader(
          keyKind: ContainerKeyKind.passphraseArgon2id,
          cipher: ContainerCipher.chunkAeadXchacha20,
          sessionId: sessionId,
          salt: salt,
          argon2Params: params,
          keyCheck: check,
          streamHeader: sh,
        ),
      );
    });

    test(
      'Round-Trip: Kopf lesbar, Schlüssel aus Kopf-Parametern, Inhalt gleich',
      () async {
        final reader = ContainerReader(file);
        expect(reader.header.keyKind, ContainerKeyKind.passphraseArgon2id);
        expect(reader.header.cipher, ContainerCipher.chunkAeadXchacha20);
        final derived = await keys.fromPassphrase(
          passphrase: 'korrekt horse batterie',
          salt: reader.header.salt!,
          params: reader.header.argon2Params!,
        );
        final progress = <int>[];
        final payload = await ContainerPayload.parse(
          await reader.decrypt(
            derived,
            factory,
            onProgress: (done, total) => progress.add(done),
          ),
        );
        expect(progress, isNotEmpty);
        expect(progress.last, file.length);
        expect(payload.manifest.entryCount, 2);
        expect(payload.manifest.firstDay, '2026-10-25');
        expect(payload.manifest.compression, 'none');
        expect(payload.fileNames, [
          ContainerPayload.databaseName,
          'audio/a.tgbc',
          'audio/b.tgbc',
        ]);
        expect(payload.file('audio/a.tgbc')!.length, 2500);
        expect(payload.file('audio/a.tgbc')![10], (10 * 7) & 0xff);
        expect(payload.file('audio/b.tgbc'), isEmpty);
        expect(
          utf8.decode(payload.file(ContainerPayload.databaseName)!),
          '{"type":"entry","id":"a"}\n',
        );
      },
    );

    test(
      'Falsche Passphrase: klare Meldung ohne Entschlüsselungsversuch',
      () async {
        final reader = ContainerReader(file);
        final wrong = await keys.fromPassphrase(
          passphrase: 'falsch',
          salt: reader.header.salt!,
          params: reader.header.argon2Params!,
        );
        expect(await reader.keyMatches(wrong), isFalse);
        await expectLater(
          reader.decrypt(wrong, factory),
          throwsA(
            isA<ContainerException>().having(
              (e) => e.error,
              'error',
              ContainerError.wrongKey,
            ),
          ),
        );
      },
    );

    test('Abgeschnittene Datei: "unvollständig", nicht "beschädigt"', () async {
      for (final cut in [file.length - 1, file.length - 500, 100]) {
        final reader = ContainerReader(file.sublist(0, cut));
        await expectLater(
          reader.decrypt(key, factory),
          throwsA(
            isA<ContainerException>().having(
              (e) => e.error,
              'error',
              ContainerError.truncated,
            ),
          ),
        );
      }
      // Kopf selbst abgeschnitten
      expect(
        () => ContainerReader(file.sublist(0, 20)),
        throwsA(
          isA<ContainerException>().having(
            (e) => e.error,
            'error',
            ContainerError.truncated,
          ),
        ),
      );
    });

    test(
      'Manipulation, vertauschte und entfernte Nachrichten scheitern',
      () async {
        final headerLen = ContainerReader(file).headerBytes.length;
        Future<void> expectTampered(Uint8List bytes) => expectLater(
          ContainerReader(bytes).decrypt(key, factory),
          throwsA(
            isA<ContainerException>().having(
              (e) => e.error,
              'error',
              ContainerError.tampered,
            ),
          ),
        );

        // Ein Bit im Chiffrat der zweiten Nachricht
        final view = ByteData.sublistView(file);
        final len1 = view.getUint32(headerLen);
        final m2Start = headerLen + 4 + len1;
        final len2 = view.getUint32(m2Start);
        final flipped = Uint8List.fromList(file)..[m2Start + 4 + 10] ^= 0x80;
        await expectTampered(flipped);

        // Nachrichten 1 und 2 vertauscht
        final m1 = file.sublist(headerLen, m2Start);
        final m2 = file.sublist(m2Start, m2Start + 4 + len2);
        final rest = file.sublist(m2Start + 4 + len2);
        await expectTampered(
          Uint8List.fromList([
            ...file.sublist(0, headerLen),
            ...m2,
            ...m1,
            ...rest,
          ]),
        );

        // Nachricht 2 entfernt
        await expectTampered(
          Uint8List.fromList([...file.sublist(0, headerLen), ...m1, ...rest]),
        );

        // Daten hinter dem Ende
        await expectTampered(Uint8List.fromList([...file, 0, 0, 0, 0]));

        // Kopf verändert (Sitzungs-ID): Prüfwert passt nicht mehr
        final otherSession = Uint8List.fromList(file)..[7] ^= 0xff;
        await expectLater(
          ContainerReader(otherSession).decrypt(key, factory),
          throwsA(
            isA<ContainerException>().having(
              (e) => e.error,
              'error',
              ContainerError.wrongKey,
            ),
          ),
        );
      },
    );

    test('Keine Container-Datei und unbekannte Version', () {
      expect(
        () => ContainerReader(Uint8List.fromList('%PDF-1.7 ...'.codeUnits)),
        throwsA(
          isA<ContainerException>().having(
            (e) => e.error,
            'error',
            ContainerError.notContainer,
          ),
        ),
      );
      final newer = Uint8List.fromList(file)..[4] = 2;
      expect(
        () => ContainerReader(newer),
        throwsA(
          isA<ContainerException>().having(
            (e) => e.error,
            'error',
            ContainerError.unsupported,
          ),
        ),
      );
    });

    test('Manifest-Prüfung: fehlende, fremde und veränderte Datei', () async {
      Future<void> expectMismatch(Uint8List payload) => expectLater(
        ContainerPayload.parse(payload),
        throwsA(
          isA<ContainerException>().having(
            (e) => e.error,
            'error',
            ContainerError.manifestMismatch,
          ),
        ),
      );
      final b = ContainerPayloadBuilder(
        createdAt: DateTime.utc(2026),
        appVersion: '0',
        schemaVersion: 1,
        entryCount: 0,
        recordingCount: 0,
      );
      await b.add('x', Uint8List.fromList([1, 2, 3]));
      final manifestBytes = Uint8List.fromList(
        utf8.encode(b.manifest().toJsonString()),
      );
      final ok = FrameWriter()
        ..add('manifest.json', manifestBytes)
        ..add('x', Uint8List.fromList([1, 2, 3]));
      final parsed = await ContainerPayload.parse(ok.toBytes());
      expect(parsed.file('x'), [1, 2, 3]);

      await expectMismatch(
        (FrameWriter()..add('manifest.json', manifestBytes)).toBytes(),
      );
      await expectMismatch(
        (FrameWriter()
              ..add('manifest.json', manifestBytes)
              ..add('x', Uint8List.fromList([1, 2, 4])))
            .toBytes(),
      );
      await expectMismatch(
        (FrameWriter()
              ..add('manifest.json', manifestBytes)
              ..add('x', Uint8List.fromList([1, 2, 3]))
              ..add('y', Uint8List(0)))
            .toBytes(),
      );
      await expectMismatch((FrameWriter()..add('x', manifestBytes)).toBytes());
      await expectLater(
        ContainerPayload.parse(
          (FrameWriter()..add(
                'manifest.json',
                Uint8List.fromList(utf8.encode('{"format":9}')),
              ))
              .toBytes(),
        ),
        throwsA(
          isA<ContainerException>().having(
            (e) => e.error,
            'error',
            ContainerError.unsupported,
          ),
        ),
      );
    });
  });

  group('Container für den Gerätewechsel (X25519)', () {
    test(
      'Round-Trip: Empfänger zeigt QR, Sender exportiert, Prüfcode gleich',
      () async {
        // Neues Gerät
        final recipient = await keys.x25519.newKeyPair();
        final qr = QrPayload(
          platform: 0,
          sessionId: sessionId,
          publicKey: recipient.publicKey,
        );
        final qrText = qr.encode();

        // Altes Gerät
        final scanned = QrPayload.decode(qrText);
        expect(scanned.verificationCode(), qr.verificationCode());
        final sender = await keys.forRecipient(
          recipientPublicKey: scanned.publicKey,
          sessionId: scanned.sessionId,
        );
        final check = await keys.keyCheck(sender.key, scanned.sessionId);
        final file = await buildContainer(
          key: sender.key,
          header: (sh) => ContainerHeader(
            keyKind: ContainerKeyKind.recipientX25519,
            cipher: ContainerCipher.chunkAeadXchacha20,
            sessionId: scanned.sessionId,
            ephemeralPublicKey: sender.ephemeralPublicKey,
            keyCheck: check,
            streamHeader: sh,
          ),
          messageSize: 64 * 1024,
        );

        // Neues Gerät liest
        final reader = ContainerReader(file);
        expect(reader.header.keyKind, ContainerKeyKind.recipientX25519);
        expect(reader.header.sessionId, sessionId);
        final key = await keys.asRecipient(
          recipientPrivateKey: recipient.privateKey,
          ephemeralPublicKey: reader.header.ephemeralPublicKey!,
          sessionId: reader.header.sessionId,
        );
        expect(key, sender.key);
        final payload = await ContainerPayload.parse(
          await reader.decrypt(key, factory),
        );
        expect(payload.manifest.recordingCount, 2);
        expect(payload.file('audio/a.tgbc')!.length, 2500);

        // Ein anderes Gerät (anderer privater Schlüssel) kommt nicht hinein.
        final other = await keys.x25519.newKeyPair();
        final wrong = await keys.asRecipient(
          recipientPrivateKey: other.privateKey,
          ephemeralPublicKey: reader.header.ephemeralPublicKey!,
          sessionId: reader.header.sessionId,
        );
        await expectLater(
          reader.decrypt(wrong, factory),
          throwsA(
            isA<ContainerException>().having(
              (e) => e.error,
              'error',
              ContainerError.wrongKey,
            ),
          ),
        );
      },
    );

    test('Ableitung ist deterministisch und an die Sitzung gebunden', () async {
      final r = await keys.x25519.keyPairFromSeed(Uint8List(32)..[0] = 1);
      final e = await keys.x25519.keyPairFromSeed(Uint8List(32)..[0] = 2);
      final s1 = Uint8List(16)..[0] = 1;
      final s2 = Uint8List(16)..[0] = 2;
      final a = await keys.asRecipient(
        recipientPrivateKey: r.privateKey,
        ephemeralPublicKey: e.publicKey,
        sessionId: s1,
      );
      final b = await keys.asRecipient(
        recipientPrivateKey: e.privateKey,
        ephemeralPublicKey: r.publicKey,
        sessionId: s1,
      );
      final c = await keys.asRecipient(
        recipientPrivateKey: r.privateKey,
        ephemeralPublicKey: e.publicKey,
        sessionId: s2,
      );
      expect(a, b);
      expect(a, isNot(c));
      expect(a.length, 32);
    });
  });
}
