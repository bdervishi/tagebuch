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
