import 'dart:typed_data';

/// Sequenzielle Stromverschlüsselung des Containers (D6). Produktiv:
/// libsodium `crypto_secretstream_xchacha20poly1305` (Spike S5). Die
/// Schnittstelle spiegelt dessen Modell: ein Kopf, dann Nachrichten mit
/// Tag, die letzte mit `final`.
abstract interface class ContainerStreamCipher {
  /// Kopfdaten für [ContainerHeader.streamHeader].
  Uint8List get header;

  /// Verschlüsselt eine Nachricht; [aad] ist der kodierte Container-Kopf.
  Future<Uint8List> push(
    Uint8List message, {
    required bool isFinal,
    Uint8List? aad,
  });
}

abstract interface class ContainerStreamDecipher {
  /// Liefert Klartext und ob dies die letzte Nachricht war; wirft
  /// `AuthenticationException` bei Manipulation, Umsortierung oder
  /// Abschneiden.
  Future<(Uint8List, bool)> pull(Uint8List sealed, {Uint8List? aad});
}

/// Erzeugt Cipher/Decipher für einen Container-Schlüssel.
abstract interface class ContainerStreamCipherFactory {
  Future<ContainerStreamCipher> encryptor(Uint8List key);
  Future<ContainerStreamDecipher> decryptor(Uint8List key, Uint8List header);
}
