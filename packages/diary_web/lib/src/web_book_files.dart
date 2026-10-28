import 'dart:typed_data';

import 'package:diary_chunkfile/diary_chunkfile.dart';
import 'package:diary_core/diary_core.dart';
import 'package:diary_crypto/diary_crypto.dart';

import 'encrypted_file_store.dart';

/// Buchdateien (EPUB, D25) auf dem Web: dieselbe Chunk-AEAD-Datei im
/// IndexedDB-Store `files` wie Audio ([EncryptedFileStore]); der gewrappte
/// Dateischlüssel steht im Buch-Datensatz. Entschlüsselt wird nur in den
/// Arbeitsspeicher, nie auf das Dateisystem.
class WebBookFiles implements BookFileStore {
  WebBookFiles(this._files);

  final EncryptedFileStore _files;

  @override
  Future<StoredBookFile> write(String fileName, Uint8List bytes) async {
    final written = await _files.write(fileName, bytes);
    return StoredBookFile(
      fileKeyWrapped: written.fileKeyWrapped,
      sizeBytes: written.sizeBytes,
    );
  }

  @override
  Future<Uint8List?> read(String fileName, Uint8List fileKeyWrapped) async {
    if (fileKeyWrapped.isEmpty) return null;
    try {
      return await _files.read(fileName, fileKeyWrapped);
    } on StateError {
      // Datei fehlt (z. B. nach Speicherräumung).
      return null;
    } on ChunkFileTruncatedException {
      return null;
    } on AuthenticationException {
      return null;
    }
  }

  @override
  Future<void> delete(String fileName) => _files.delete(fileName);
}
