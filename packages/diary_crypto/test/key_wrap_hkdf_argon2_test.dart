import 'dart:typed_data';

import 'package:diary_crypto/diary_crypto.dart';
import 'package:test/test.dart';

void main() {
  group('KeyWrap', () {
    final wrap = KeyWrap(
      CryptographyAead.xchacha20Poly1305(),
      SequentialRandomSource(9),
    );
    final master = SequentialRandomSource(200).bytes(32);
    final fileKey = SequentialRandomSource(50).bytes(32);

    test('Round-Trip', () async {
      final blob = await wrap.wrap(
        masterKey: master,
        key: fileKey,
        purpose: 'recording',
      );
      expect(blob.length, 24 + 32 + 16);
      final back = await wrap.unwrap(
        masterKey: master,
        wrapped: blob,
        purpose: 'recording',
      );
      expect(back, fileKey);
    });

    test('anderer Verwendungszweck scheitert', () async {
      final blob = await wrap.wrap(
        masterKey: master,
        key: fileKey,
        purpose: 'recording',
      );
      expect(
        () =>
            wrap.unwrap(masterKey: master, wrapped: blob, purpose: 'database'),
        throwsA(isA<AuthenticationException>()),
      );
    });

    test('zu kurzer Blob scheitert', () {
      expect(
        () => wrap.unwrap(
          masterKey: master,
          wrapped: Uint8List(10),
          purpose: 'recording',
        ),
        throwsA(isA<AuthenticationException>()),
      );
    });
  });

  test('HKDF-SHA256 Testvektor RFC 5869 Fall 1', () async {
    final ikm = Uint8List.fromList(List.filled(22, 0x0b));
    final salt = Uint8List.fromList(List.generate(13, (i) => i));
    final out = await const HkdfSha256().derive(
      inputKeyMaterial: ikm,
      salt: salt,
      info: String.fromCharCodes(List.generate(10, (i) => 0xf0 + i)),
      length: 42,
    );
    expect(
      out.map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
      '3cb25f25faacd57a90434f64d0362f2a2d2d0a90cf1a5a4c5db02d56ecc4c5bf34007208d5b887185865',
    );
  });

  test('Argon2id ist deterministisch und salzabhängig', () async {
    const kdf = Argon2idKdf();
    final salt1 = SequentialRandomSource(1).bytes(16);
    final salt2 = SequentialRandomSource(2).bytes(16);
    final a = await kdf.derive(
      passphrase: 'korrekt pferd batterie',
      salt: salt1,
      params: Argon2Params.testing,
    );
    final b = await kdf.derive(
      passphrase: 'korrekt pferd batterie',
      salt: salt1,
      params: Argon2Params.testing,
    );
    final c = await kdf.derive(
      passphrase: 'korrekt pferd batterie',
      salt: salt2,
      params: Argon2Params.testing,
    );
    expect(a, b);
    expect(a, isNot(c));
    expect(a.length, 32);
  });

  test('Standardparameter entsprechen docs/05 (64 MiB, t=3, p=1, Salt 16)', () {
    expect(Argon2Params.standard.memoryKiB, 65536);
    expect(Argon2Params.standard.iterations, 3);
    expect(Argon2Params.standard.parallelism, 1);
    expect(Argon2Params.standard.saltLength, 16);
  });

  test('PIN-Parameter (D23) sind moderat, aber nicht die Testparameter', () {
    expect(Argon2Params.pin.memoryKiB, 4096);
    expect(Argon2Params.pin.iterations, 3);
    expect(Argon2Params.pin.parallelism, 1);
    expect(Argon2Params.pin.saltLength, 16);
    expect(Argon2Params.pin.hashLength, 32);
    expect(
      Argon2Params.pin.memoryKiB,
      greaterThan(Argon2Params.testing.memoryKiB * 8),
    );
  });

  test('constantTimeEquals', () {
    expect(constantTimeEquals([1, 2, 3], [1, 2, 3]), isTrue);
    expect(constantTimeEquals([1, 2, 3], [1, 2, 4]), isFalse);
    expect(constantTimeEquals([1, 2], [1, 2, 3]), isFalse);
  });
}
