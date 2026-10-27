import 'dart:typed_data';

import 'package:diary_crypto/diary_crypto.dart';
import 'package:meta/meta.dart';

/// Ableitung des Containerschlüssels (D6, docs/06 Abschnitt 5.2 und 6.1).
///
/// Zwei Wege führen zu demselben 32-Byte-Schlüssel `K_c`:
///
/// * **Passphrase (Backup):** `K_c = Argon2id(passphrase, salt, params)`;
///   Salt und Parameter stehen im Container-Kopf.
/// * **Empfänger (Gerätewechsel):** Das neue Gerät erzeugt ein
///   X25519-Paar (r, R) und zeigt R im QR-Code. Das alte Gerät erzeugt ein
///   ephemeres Paar (e, E), rechnet `shared = X25519(e, R)` und
///   `K_c = HKDF-SHA-256(ikm = shared, salt = Sitzungs-ID,
///   info = "tagebuch-container-v1", 32)`. E steht im Kopf; der Empfänger
///   rechnet `X25519(r, E)` und dieselbe HKDF.
///
/// Zusätzlich liefert [keyCheck] acht Prüfbytes, die im Kopf stehen und
/// "falsche Passphrase" von "Datei beschädigt" unterscheiden.
class ContainerKeys {
  const ContainerKeys({
    this.kdf = const Argon2idKdf(),
    this.hkdf = const HkdfSha256(),
    this.x25519 = const X25519KeyAgreement(),
  });

  static const String hkdfInfo = 'tagebuch-container-v1';
  static const String keyCheckInfo = 'tagebuch-container-v1/check';
  static const int keyLength = 32;
  static const int keyCheckLength = 8;

  final PassphraseKdf kdf;
  final HkdfSha256 hkdf;
  final X25519KeyAgreement x25519;

  Future<Uint8List> fromPassphrase({
    required String passphrase,
    required Uint8List salt,
    required Argon2Params params,
  }) => kdf.derive(passphrase: passphrase, salt: salt, params: params);

  /// Senderseite: ephemeres Paar erzeugen, Schlüssel ableiten.
  Future<SenderKeyMaterial> forRecipient({
    required Uint8List recipientPublicKey,
    required Uint8List sessionId,
  }) async {
    final ephemeral = await x25519.newKeyPair();
    try {
      final key = await _agree(
        privateKey: ephemeral.privateKey,
        remotePublicKey: recipientPublicKey,
        sessionId: sessionId,
      );
      return SenderKeyMaterial(
        key: key,
        ephemeralPublicKey: ephemeral.publicKey,
      );
    } finally {
      ephemeral.dispose();
    }
  }

  /// Empfängerseite: aus eigenem privatem Schlüssel und E aus dem Kopf.
  Future<Uint8List> asRecipient({
    required Uint8List recipientPrivateKey,
    required Uint8List ephemeralPublicKey,
    required Uint8List sessionId,
  }) => _agree(
    privateKey: recipientPrivateKey,
    remotePublicKey: ephemeralPublicKey,
    sessionId: sessionId,
  );

  Future<Uint8List> _agree({
    required Uint8List privateKey,
    required Uint8List remotePublicKey,
    required Uint8List sessionId,
  }) async {
    final shared = await x25519.sharedSecret(
      privateKey: privateKey,
      remotePublicKey: remotePublicKey,
    );
    try {
      return await hkdf.derive(
        inputKeyMaterial: shared,
        salt: sessionId,
        info: hkdfInfo,
        length: keyLength,
      );
    } finally {
      zeroize(shared);
    }
  }

  /// Prüfwert des Schlüssels für den Kopf: HKDF über `K_c` mit eigener
  /// Info-Zeichenkette, damit aus dem Prüfwert nichts über `K_c` folgt.
  Future<Uint8List> keyCheck(Uint8List key, Uint8List sessionId) => hkdf.derive(
    inputKeyMaterial: key,
    salt: sessionId,
    info: keyCheckInfo,
    length: keyCheckLength,
  );
}

/// Ergebnis der Senderseite: Containerschlüssel und das E für den Kopf.
@immutable
class SenderKeyMaterial {
  const SenderKeyMaterial({
    required this.key,
    required this.ephemeralPublicKey,
  });
  final Uint8List key;
  final Uint8List ephemeralPublicKey;
}
