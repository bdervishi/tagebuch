import 'dart:typed_data';

import 'package:diary_chunkfile/diary_chunkfile.dart';
import 'package:diary_core/diary_core.dart';
import 'package:diary_crypto/diary_crypto.dart';

import 'encrypted_file_store.dart';

/// Audiodateien für Backup und Gerätewechsel (D6) auf dem Web: liest die
/// Chunk-Datei entschlüsselt in den Speicher und schreibt importiertes Audio
/// als neue Chunk-Datei unter dem Master-Key dieses Browsers.
class WebAudioFiles implements AudioFileSource, AudioFileSink {
  WebAudioFiles(this._files);

  final EncryptedFileStore _files;

  @override
  Future<Uint8List?> read(Recording recording) async {
    if (recording.state == RecordingState.audioDeleted ||
        recording.fileKeyWrapped.isEmpty) {
      return null;
    }
    try {
      return await _files.read(recording.fileName, recording.fileKeyWrapped);
    } on StateError {
      // Datei fehlt (z. B. nach Speicherräumung): ohne Audio exportieren.
      return null;
    } on ChunkFileTruncatedException {
      // Abgebrochene Aufnahme: so viel mitnehmen, wie lesbar ist.
      return null;
    } on AuthenticationException {
      return null;
    }
  }

  @override
  Future<StoredAudioFile> write(String fileName, Uint8List bytes) async {
    final written = await _files.write(fileName, bytes);
    return StoredAudioFile(
      fileKeyWrapped: written.fileKeyWrapped,
      sizeBytes: written.sizeBytes,
    );
  }
}
