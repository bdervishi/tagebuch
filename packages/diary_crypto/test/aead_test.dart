import 'dart:typed_data';

import 'package:diary_crypto/diary_crypto.dart';
import 'package:test/test.dart';

void main() {
  for (final id in AeadId.values) {
    group(id.name, () {
      final aead = CryptographyAead.forId(id);
      final key = SequentialRandomSource(1).bytes(id.keyLength);
      final nonce = SequentialRandomSource(100).bytes(id.nonceLength);
      final aad = Uint8List.fromList('chunk-0'.codeUnits);
      final plaintext = Uint8List.fromList(List.generate(1000, (i) => i % 251));

      test('Round-Trip mit Zusatzdaten', () async {
        final sealed = await aead.seal(
          key: key,
          nonce: nonce,
          plaintext: plaintext,
          aad: aad,
        );
        expect(sealed.length, plaintext.length + id.tagLength);
        final opened = await aead.open(
          key: key,
          nonce: nonce,
          sealed: sealed,
          aad: aad,
        );
        expect(opened, plaintext);
      });

      test('verändertes Byte scheitert', () async {
        final sealed = await aead.seal(
          key: key,
          nonce: nonce,
          plaintext: plaintext,
          aad: aad,
        );
        sealed[10] ^= 0x01;
        expect(
          () => aead.open(key: key, nonce: nonce, sealed: sealed, aad: aad),
          throwsA(isA<AuthenticationException>()),
        );
      });

      test('falsche Zusatzdaten scheitern', () async {
        final sealed = await aead.seal(
          key: key,
          nonce: nonce,
          plaintext: plaintext,
          aad: aad,
        );
        expect(
          () => aead.open(
            key: key,
            nonce: nonce,
            sealed: sealed,
            aad: Uint8List.fromList('chunk-1'.codeUnits),
          ),
          throwsA(isA<AuthenticationException>()),
        );
      });

      test('falscher Schlüssel scheitert', () async {
        final sealed = await aead.seal(
          key: key,
          nonce: nonce,
          plaintext: plaintext,
          aad: aad,
        );
        final other = SequentialRandomSource(7).bytes(id.keyLength);
        expect(
          () => aead.open(key: other, nonce: nonce, sealed: sealed, aad: aad),
          throwsA(isA<AuthenticationException>()),
        );
      });

      test('falsche Schlüssellänge wird abgewiesen', () {
        expect(
          () =>
              aead.seal(key: Uint8List(5), nonce: nonce, plaintext: plaintext),
          throwsArgumentError,
        );
      });
    });
  }

  test(
    'XChaCha20-Poly1305 Testvektor aus draft-irtf-cfrg-xchacha (A.3.1)',
    () async {
      // Klartext, AAD, Schlüssel, Nonce und Ergebnis aus dem IETF-Entwurf.
      final plaintext = Uint8List.fromList(
        "Ladies and Gentlemen of the class of '99: If I could offer you only one tip for the future, sunscreen would be it."
            .codeUnits,
      );
      final aad = _hex('50515253c0c1c2c3c4c5c6c7');
      final key = _hex(
        '808182838485868788898a8b8c8d8e8f909192939495969798999a9b9c9d9e9f',
      );
      final nonce = _hex('404142434445464748494a4b4c4d4e4f5051525354555657');
      final expectedCipher = _hex(
        'bd6d179d3e83d43b9576579493c0e939572a1700252bfaccbed2902c21396cbb'
        '731c7f1b0b4aa6440bf3a82f4eda7e39ae64c6708c54c216cb96b72e1213b452'
        '2f8c9ba40db5d945b11b69b982c1bb9e3f3fac2bc369488f76b2383565d3fff9'
        '21f9664c97637da9768812f615c68b13b52e',
      );
      final expectedTag = _hex('c0875924c1c7987947deafd8780acf49');
      final aead = CryptographyAead.xchacha20Poly1305();
      final sealed = await aead.seal(
        key: key,
        nonce: nonce,
        plaintext: plaintext,
        aad: aad,
      );
      expect(sealed.sublist(0, plaintext.length), expectedCipher);
      expect(sealed.sublist(plaintext.length), expectedTag);
    },
  );
}

Uint8List _hex(String s) {
  final out = Uint8List(s.length ~/ 2);
  for (var i = 0; i < out.length; i++) {
    out[i] = int.parse(s.substring(2 * i, 2 * i + 2), radix: 16);
  }
  return out;
}
