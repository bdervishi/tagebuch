import 'dart:typed_data';

import '../model/recording.dart';

/// Ergebnis von [AudioFileSink.write]: der neu gewrappte Dateischlüssel und
/// die Größe der verschlüsselten Datei (gehören in den Aufnahme-Datensatz).
class StoredAudioFile {
  const StoredAudioFile({
    required this.fileKeyWrapped,
    required this.sizeBytes,
  });
  final Uint8List fileKeyWrapped;
  final int sizeBytes;
}

/// Liest das Audio einer Aufnahme entschlüsselt in den Speicher (Export in den
/// Container, D6). Liefert `null`, wenn die Datei fehlt oder das Audio
/// gelöscht ist; die Aufnahme wird dann ohne Audio exportiert.
abstract interface class AudioFileSource {
  Future<Uint8List?> read(Recording recording);
}

/// Schreibt Audio aus dem Container als verschlüsselte Chunk-Datei unter dem
/// Master-Key dieses Geräts (Import). Der Container selbst ist verschlüsselt;
/// das Zielgerät wrappt den Dateischlüssel neu (D5).
abstract interface class AudioFileSink {
  Future<StoredAudioFile> write(String fileName, Uint8List bytes);
}

/// Ergebnis von [BookFileStore.write] (D25): gewrappter Dateischlüssel und
/// Größe der verschlüsselten Datei, beides gehört in den Buch-Datensatz.
class StoredBookFile {
  const StoredBookFile({required this.fileKeyWrapped, required this.sizeBytes});
  final Uint8List fileKeyWrapped;
  final int sizeBytes;
}

/// Buchdateien (EPUB, D25) im verschlüsselten Dateispeicher: derselbe Weg wie
/// Audio (`diary_chunkfile`), nie Klartext auf dem Dateisystem. Web:
/// `WebBookFiles` über den `EncryptedFileStore`; nativ folgt mit den Spikes.
abstract interface class BookFileStore {
  /// Verschlüsselt [bytes] unter [fileName]; eine vorhandene Datei wird
  /// ersetzt.
  Future<StoredBookFile> write(String fileName, Uint8List bytes);

  /// Liest die Datei entschlüsselt in den Speicher; `null`, wenn sie fehlt
  /// oder nicht zum Schlüssel passt.
  Future<Uint8List?> read(String fileName, Uint8List fileKeyWrapped);

  /// Entfernt die Datei (Crypto-Shredding zusammen mit dem Datensatz).
  Future<void> delete(String fileName);
}
