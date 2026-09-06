/// Chunk-AEAD-Dateiformat mit wahlfreiem Zugriff für verschlüsselte
/// Audiodateien (docs/04-technik-architektur.md Abschnitt 5.1).
///
/// Dart-Referenzimplementierung des Formats `TGBC` Version 1: Dateikopf mit
/// gewrapptem Dateischlüssel, Inhalt in Chunks fester Größe mit je eigener
/// Nonce und Auth-Tag, Zusatzdaten aus Kopf-Präfix, Chunk-Index und
/// Endkennzeichen. Byte-Layout und Testvektoren siehe README.
///
/// Diese Bibliothek ist plattformneutral (kein `dart:io`); die Datei-Varianten
/// liegen in `package:diary_chunkfile/diary_chunkfile_io.dart`.
library;

export 'src/exceptions.dart';
export 'src/format.dart';
export 'src/reader.dart';
export 'src/sink.dart';
export 'src/source.dart';
export 'src/writer.dart';
