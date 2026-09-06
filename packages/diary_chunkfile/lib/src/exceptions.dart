/// Fehlerklassen des Chunk-Dateiformats.
///
/// Authentifizierungsfehler (verändertes Byte, vertauschter Chunk, Chunk aus
/// einer anderen Datei, falscher Master-Key) werden nicht hier abgebildet,
/// sondern als `AuthenticationException` aus `diary_crypto` durchgereicht.
library;

/// Gemeinsame Basis aller strukturellen Fehler einer Chunk-Datei.
sealed class ChunkFileException implements Exception {
  const ChunkFileException(this.message);

  /// Beschreibung des Fehlers (Deutsch, für Protokolle; nicht für die UI).
  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// Kopf oder Struktur der Datei sind ungültig: falsche Magic-Bytes, unbekannte
/// Version oder AEAD-Kennung, unplausible Chunk-Größe, falsche Länge des
/// gewrappten Schlüssels, überzählige Bytes am Dateiende oder ein nicht
/// kanonischer Aufbau (z. B. leerer letzter Chunk bei nicht leerer Datei).
final class ChunkFileFormatException extends ChunkFileException {
  const ChunkFileFormatException(super.message);
}

/// Die Datei endet zu früh: Kopf unvollständig, ein Datensatz ist nur teilweise
/// vorhanden, oder der letzte vorhandene Chunk trägt nicht das Kennzeichen
/// `isLast` (ganze Chunks am Ende fehlen).
final class ChunkFileTruncatedException extends ChunkFileException {
  const ChunkFileTruncatedException(super.message);
}
