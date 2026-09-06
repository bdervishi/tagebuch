/// Schlüsselverwahrung und App-Sperre (D5).
///
/// Zielbild: Master-Key im iOS-Keychain (`kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly`)
/// bzw. gewrappt mit einem Android-Keystore-Schlüssel (StrongBox, TEE-Fallback);
/// Biometrie nur als Komfortpfad vor dem Gerätecode. Die native Brücke folgt
/// in Spike S4; hier stehen Schnittstelle, In-Memory-Umsetzung und die
/// Sperrlogik mit Zeitfenster.
library;

export 'src/key_store.dart';
export 'src/lock.dart';
