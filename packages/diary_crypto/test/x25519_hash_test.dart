import 'dart:typed_data';

import 'package:diary_crypto/diary_crypto.dart';
import 'package:test/test.dart';

Uint8List _hex(String s) => Uint8List.fromList([
  for (var i = 0; i < s.length; i += 2)
    int.parse(s.substring(i, i + 2), radix: 16),
]);

void main() {
  const x = X25519KeyAgreement();

  test('X25519: Testvektor aus RFC 7748 Abschnitt 6.1', () async {
    final alicePriv = _hex(
      '77076d0a7318a57d3c16c17251b26645df4c2f87ebc0992ab177fba51db92c2a',
    );
    final alicePub = _hex(
      '8520f0098930a754748b7ddcb43ef75a0dbf3a0d26381af4eba4a98eaa9b4e6a',
    );
    final bobPriv = _hex(
      '5dab087e624a8a4b79e17f8b83800ee66f3bb1292618b6fd1c2f8b27ff88e0eb',
    );
    final bobPub = _hex(
      'de9edb7d7b7dc1b4d35b61c2ece435373f8343c85b78674dadfc7e146f882b4f',
    );
    const shared =
        '4a5d9d5ba4ce2de1728e3bf480350f25e07e21c947d19e3376f09b3c1e161742';

    final alice = await x.keyPairFromSeed(alicePriv);
    expect(hexEncode(alice.publicKey), hexEncode(alicePub));
    final bob = await x.keyPairFromSeed(bobPriv);
    expect(hexEncode(bob.publicKey), hexEncode(bobPub));

    final s1 = await x.sharedSecret(
      privateKey: alicePriv,
      remotePublicKey: bobPub,
    );
    final s2 = await x.sharedSecret(
      privateKey: bobPriv,
      remotePublicKey: alicePub,
    );
    expect(hexEncode(s1), shared);
    expect(hexEncode(s2), shared);
  });

  test('X25519: zufällige Paare, beide Seiten gleiches Geheimnis', () async {
    final a = await x.newKeyPair();
    final b = await x.newKeyPair();
    expect(a.publicKey, isNot(b.publicKey));
    final s1 = await x.sharedSecret(
      privateKey: a.privateKey,
      remotePublicKey: b.publicKey,
    );
    final s2 = await x.sharedSecret(
      privateKey: b.privateKey,
      remotePublicKey: a.publicKey,
    );
    expect(s1, s2);
    a.dispose();
    expect(a.privateKey.every((b) => b == 0), isTrue);
  });

  test('SHA-256: bekannter Wert', () async {
    final h = await sha256(Uint8List.fromList('abc'.codeUnits));
    expect(
      hexEncode(h),
      'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
    );
  });
}
