/// Schlüsselverwahrung und App-Sperre (D5).
///
/// Zielbild: Master-Key im iOS-Keychain (`kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly`)
/// bzw. gewrappt mit einem Android-Keystore-Schlüssel (StrongBox, TEE-Fallback);
/// Biometrie nur als Komfortpfad vor dem Gerätecode. Die native Brücke folgt
/// in Spike S4; hier stehen Schnittstelle, In-Memory-Umsetzung, die
/// Sperrlogik mit Zeitfenster und der PIN-Hash der Bildschirmsperre (D23:
/// Argon2id statt PIN, Wartezeiten nach Fehlversuchen, gerätegebundene
/// Einstellungen).
library;

export 'src/key_store.dart';
export 'src/lock.dart';
export 'src/pin.dart';
